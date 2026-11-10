import 'dart:async';
import 'dart:convert';
import 'package:bongo_foodie/data/checkout/pending_checkout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const owner = '11111111-1111-4111-8111-111111111111';
const other = '22222222-2222-4222-8222-222222222222';
Map<String, dynamic> request() => {
      'version': 1,
      'items': [
        {'id': 'dish', 'quantity': 1}
      ],
      'name': 'Asha Juma',
      'reviewed_quote': {'version': 1, 'total': 12000, 'currency': 'TZS'}
    };
Map<String, dynamic> response(Map<String, dynamic> request) => {
      'version': 1,
      'order_id': 'BF-aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
      'status': 'pending',
      'payment_state': 'unconfirmed',
      'items': [
        {
          'id': 'dish',
          'quantity': 1,
          'name': 'Catalog dish',
          'price': 10000,
          'customizations': []
        }
      ],
      'quote': request['reviewed_quote']
    };

class Journal implements CheckoutJournal {
  final values = <String, String>{};
  int writes = 0;
  int? failAt;
  @override
  Future<String?> read(String scope) async => values[scope];
  @override
  Future<void> write(String scope, String value) async {
    writes++;
    if (writes == failAt) throw StateError('disk failed');
    values[scope] = value;
  }
}

class Transport implements CheckoutTransport {
  Transport(
      {this.project = 'https://test.supabase.co',
      this.owner = '11111111-1111-4111-8111-111111111111'});
  @override
  final String project;
  @override
  final String owner;
  int submits = 0;
  int lookups = 0;
  Future<Map<String, dynamic>> Function(String, Map<String, dynamic>)? onSubmit;
  Future<Map<String, dynamic>?> Function(String)? onLookup;
  final keys = <String>[];
  final bodies = <String>[];
  @override
  Future<Map<String, dynamic>> submit(
      String key, Map<String, dynamic> body) async {
    submits++;
    keys.add(key);
    bodies.add(jsonEncode(body));
    return onSubmit == null ? response(body) : await onSubmit!(key, body);
  }

  @override
  Future<Map<String, dynamic>?> lookup(String key) async {
    lookups++;
    keys.add(key);
    return onLookup == null ? null : await onLookup!(key);
  }
}

PendingCheckoutCoordinator coordinator(
        CheckoutJournal journal, Transport transport,
        {String project = 'https://test.supabase.co',
        String user = owner,
        String? Function()? active}) =>
    PendingCheckoutCoordinator(
        project: project,
        owner: user,
        currentOwner: active ?? () => user,
        journal: journal,
        transport: transport);
void main() {
  test(
      'prepared request survives restart and caller mutation before submission',
      () async {
    SharedPreferences.setMockInitialValues({});
    final journal = PreferencesCheckoutJournal();
    final transport = Transport();
    final first = coordinator(journal, transport);
    final body = request();
    final prepared = await first.prepare(body);
    (body['items'] as List).clear();
    prepared.request['name'] = 'forged';
    final restarted = coordinator(PreferencesCheckoutJournal(), transport);
    final saved = (await restarted.restore())!;
    expect(saved.key, prepared.key);
    expect(saved.request['name'], 'Asha Juma');
    expect(saved.request['items'], hasLength(1));
    expect(transport.submits, 0);
    expect((await restarted.submitSaved()).phase, CheckoutPhase.confirmed);
    expect(transport.keys.single, prepared.key);
  });
  test('journal failure before prepared/unknown prevents network writes',
      () async {
    final journal = Journal()..failAt = 1;
    final transport = Transport();
    final c = coordinator(journal, transport);
    await expectLater(c.prepare(request()), throwsStateError);
    expect(transport.submits, 0);
    journal.failAt = null;
    await c.prepare(request());
    journal.failAt = journal.writes + 1;
    await expectLater(c.submitSaved(), throwsStateError);
    expect(transport.submits, 0);
  });
  test(
      'lost response, null lookup, and failed lookup retain same unknown key/body',
      () async {
    final journal = Journal();
    final transport = Transport()
      ..onSubmit = (_, __) async => throw StateError('lost');
    final c = coordinator(journal, transport);
    final prepared = await c.prepare(request());
    expect((await c.submitSaved()).phase, CheckoutPhase.unknown);
    final restarted = coordinator(journal, transport);
    expect((await restarted.reconcile())!.phase, CheckoutPhase.unknown);
    transport.onLookup = (_) async => throw TimeoutException('offline');
    expect((await restarted.reconcile())!.key, prepared.key);
    await expectLater(
        restarted.prepare({...request(), 'name': 'changed'}), throwsStateError);
    transport.onSubmit = null;
    expect((await restarted.submitSaved()).phase, CheckoutPhase.confirmed);
    expect(transport.bodies.toSet(), hasLength(1));
    expect(transport.keys.toSet(), {prepared.key});
  });
  test('failed confirmed journal write recovers by lookup without resubmission',
      () async {
    final journal = Journal()..failAt = 3;
    final transport = Transport();
    final c = coordinator(journal, transport);
    await c.prepare(request());
    await expectLater(c.submitSaved(), throwsStateError);
    expect((await c.restore())!.phase, CheckoutPhase.unknown);
    transport.onLookup = (_) async => response(request());
    final recovered = await coordinator(journal, transport).reconcile();
    expect(recovered!.phase, CheckoutPhase.confirmed);
    expect(transport.submits, 1);
    await c.submitSaved();
    expect(transport.submits, 1);
  });
  test(
      'concurrent coordinators serialize one scope and do not double submit confirmed request',
      () async {
    final journal = Journal();
    final transport = Transport();
    final c = coordinator(journal, transport);
    final prepared = await Future.wait([
      c.prepare(request()),
      coordinator(journal, transport).prepare(request())
    ]);
    expect(prepared.map((p) => p.key).toSet(), hasLength(1));
    final pending = Completer<Map<String, dynamic>>();
    transport.onSubmit = (_, __) => pending.future;
    final first = c.submitSaved();
    final second = coordinator(journal, transport).submitSaved();
    await Future<void>.delayed(Duration.zero);
    expect(transport.submits, 1);
    pending.complete(response(request()));
    await Future.wait([first, second]);
    expect(transport.submits, 1);
  });
  test(
      'owner/project scopes isolate and session switch during response cannot expose confirmation',
      () async {
    final journal = Journal();
    final transport = Transport();
    String? active = owner;
    final c = coordinator(journal, transport, active: () => active);
    await c.prepare(request());
    expect(
        await coordinator(journal, Transport(owner: other), user: other)
            .restore(),
        isNull);
    expect(
        await coordinator(journal, transport,
                project: 'https://another.supabase.co')
            .restore(),
        isNull);
    transport.onSubmit = (_, body) async {
      active = other;
      return response(body);
    };
    await expectLater(c.submitSaved(), throwsStateError);
    active = owner;
    expect((await c.restore())!.phase, CheckoutPhase.unknown);
    active = null;
    await expectLater(c.reconcile(), throwsStateError);
  });
  test(
      'corruption and malformed response never become new requests or confirmation',
      () async {
    final journal = Journal();
    final transport = Transport();
    final c = coordinator(journal, transport);
    journal.values[c.scope] = 'broken';
    await expectLater(c.prepare(request()), throwsStateError);
    journal.values.clear();
    await c.prepare(request());
    transport.onSubmit =
        (_, __) async => {'order_id': 'fake', 'status': 'paid'};
    expect((await c.submitSaved()).phase, CheckoutPhase.unknown);
    transport.onLookup = (_) async => {
          ...response(request()),
          'quote': {'total': 1}
        };
    expect((await c.reconcile())!.phase, CheckoutPhase.unknown);
  });
}
