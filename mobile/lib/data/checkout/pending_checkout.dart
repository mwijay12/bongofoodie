import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/checkout_validation.dart';

enum CheckoutPhase { prepared, unknown, confirmed }

class PendingCheckout {
  const PendingCheckout(
      {required this.key,
      required this.requestJson,
      required this.phase,
      this.responseJson});
  final String key;
  // JSON strings prevent callers mutating a saved request through shared maps.
  final String requestJson;
  final CheckoutPhase phase;
  final String? responseJson;
  Map<String, dynamic> get request =>
      jsonDecode(requestJson) as Map<String, dynamic>;
  Map<String, dynamic>? get response => responseJson == null
      ? null
      : jsonDecode(responseJson!) as Map<String, dynamic>;
  PendingCheckout withPhase(CheckoutPhase phase, {String? response}) =>
      PendingCheckout(
          key: key,
          requestJson: requestJson,
          phase: phase,
          responseJson: response);
}

abstract interface class CheckoutJournal {
  Future<String?> read(String scope);
  Future<void> write(String scope, String value);
}

class PreferencesCheckoutJournal implements CheckoutJournal {
  @override
  Future<String?> read(String scope) async =>
      (await SharedPreferences.getInstance()).getString(scope);
  @override
  Future<void> write(String scope, String value) async {
    if (!await (await SharedPreferences.getInstance())
        .setString(scope, value)) {
      throw StateError('checkout_journal_write_failed');
    }
  }
}

abstract interface class CheckoutTransport {
  Future<Map<String, dynamic>> submit(String key, Map<String, dynamic> request);
  Future<Map<String, dynamic>?> lookup(String key);
}

/// Not wired to checkout UI. Never clears a cart, provisions auth or retries itself.
class PendingCheckoutCoordinator {
  PendingCheckoutCoordinator(
      {required this.project,
      required this.owner,
      required this.currentOwner,
      required this.journal,
      required this.transport});
  final String project;
  final String owner;
  final String? Function() currentOwner;
  final CheckoutJournal journal;
  final CheckoutTransport transport;
  static final Map<String, Future<void>> _queues = {};
  static final _uuid = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
  String get scope =>
      'bongo_checkout_v1:${base64Url.encode(utf8.encode(jsonEncode([
            project,
            owner
          ])))}';
  void _authorize() {
    final uri = Uri.tryParse(project);
    if (uri?.scheme != 'https' ||
        uri?.host.isEmpty != false ||
        !_uuid.hasMatch(owner) ||
        currentOwner() != owner) {
      throw StateError('checkout_owner_unavailable');
    }
  }

  // Same-process scopes share serialization even across new coordinator objects.
  // SharedPreferences is NOT a cross-process/isolate transactional store.
  Future<T> _exclusive<T>(Future<T> Function() work) async {
    final previous = _queues[scope] ?? Future<void>.value();
    final done = Completer<void>();
    _queues[scope] = done.future;
    await previous;
    try {
      _authorize();
      return await work();
    } finally {
      done.complete();
      if (identical(_queues[scope], done.future)) _queues.remove(scope);
    }
  }

  Future<PendingCheckout?> _read() async {
    final raw = await journal.read(scope);
    if (raw == null) return null;
    // Corruption blocks new requests instead of silently discarding uncertainty.
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      if (json['version'] != 1 ||
          json['project'] != project ||
          json['owner'] != owner ||
          !_uuid.hasMatch(json['key'] as String)) throw const FormatException();
      final pending = PendingCheckout(
          key: json['key'] as String,
          requestJson: json['request'] as String,
          phase: CheckoutPhase.values.byName(json['phase'] as String),
          responseJson: json['response'] as String?);
      if (pending.request['version'] != 1 ||
          (pending.phase == CheckoutPhase.confirmed
              ? pending.responseJson == null
              : pending.responseJson != null)) {
        throw const FormatException();
      }
      if (pending.phase == CheckoutPhase.confirmed)
        _validateResponse(pending, pending.response!);
      return pending;
    } catch (_) {
      throw StateError('checkout_journal_corrupt');
    }
  }

  Future<void> _save(PendingCheckout pending) async {
    _authorize();
    await journal.write(
        scope,
        jsonEncode({
          'version': 1,
          'project': project,
          'owner': owner,
          'key': pending.key,
          'request': pending.requestJson,
          'phase': pending.phase.name,
          'response': pending.responseJson
        }));
    _authorize();
  }

  Future<PendingCheckout?> restore() => _exclusive(() async {
        final pending = await _read();
        _authorize();
        return pending;
      });
  Future<PendingCheckout> prepare(Map<String, dynamic> request) =>
      _exclusive(() async {
        final existing = await _read();
        _authorize();
        if (existing != null) {
          if (_canonical(existing.request) != _canonical(request))
            throw StateError('checkout_pending_request_exists');
          return existing;
        }
        if (request['version'] != 1 ||
            request['reviewed_quote'] is! Map ||
            request['items'] is! List ||
            utf8.encode(jsonEncode(request)).length > 65536)
          throw ArgumentError('checkout_invalid_request');
        final pending = PendingCheckout(
            key: CheckoutValidation.newOrderId().substring(3),
            requestJson: jsonEncode(request),
            phase: CheckoutPhase.prepared);
        await _save(pending);
        return pending;
      });

  /// Explicit caller action only. Unknown outcomes reuse the SAME stored request.
  Future<PendingCheckout> submitSaved() => _exclusive(() async {
        final pending = await _read();
        _authorize();
        if (pending == null) throw StateError('checkout_no_pending_request');
        if (pending.phase == CheckoutPhase.confirmed) return pending;
        final unknown = pending.withPhase(CheckoutPhase.unknown);
        // If this write fails, absolutely no network submission is attempted.
        await _save(unknown);
        Map<String, dynamic> result;
        try {
          _authorize();
          result = await transport.submit(
              unknown.key, unknown.request); // NO write timeout.
          _authorize();
          _validateResponse(unknown, result);
        } catch (_) {
          // Even RPC errors stay conservative until typed rejection/review UX exists.
          _authorize();
          return unknown;
        }
        final confirmed = unknown.withPhase(CheckoutPhase.confirmed,
            response: jsonEncode(result));
        // Failure here leaves the durable UNKNOWN journal for subsequent lookup.
        await _save(confirmed);
        return confirmed;
      });
  Future<PendingCheckout?> reconcile() => _exclusive(() async {
        final pending = await _read();
        _authorize();
        if (pending == null || pending.phase == CheckoutPhase.confirmed)
          return pending;
        Map<String, dynamic>? result;
        try {
          _authorize();
          result = await transport
              .lookup(pending.key)
              .timeout(const Duration(seconds: 10));
          _authorize();
          if (result == null)
            return pending; // Not proof of failure; NEVER delete/change key.
          _validateResponse(pending, result);
        } catch (_) {
          _authorize();
          return pending;
        }
        final confirmed = pending.withPhase(CheckoutPhase.confirmed,
            response: jsonEncode(result));
        await _save(confirmed);
        return confirmed;
      });
  static void _validateResponse(
      PendingCheckout pending, Map<String, dynamic> result) {
    final id = result['order_id'];
    if (result['version'] != 1 ||
        id is! String ||
        !id.startsWith('BF-') ||
        !_uuid.hasMatch(id.substring(3)) ||
        result['status'] != 'pending' ||
        result['payment_state'] != 'unconfirmed' ||
        result['items'] is! List ||
        _canonical(result['quote']) !=
            _canonical(pending.request['reviewed_quote'])) {
      throw const FormatException('checkout_invalid_response');
    }
  }

  static String _canonical(dynamic value) {
    dynamic sort(dynamic value) {
      if (value is Map) {
        final keys = value.keys.cast<String>().toList()..sort();
        return {for (final key in keys) key: sort(value[key])};
      }
      if (value is List) return value.map(sort).toList();
      return value;
    }

    return jsonEncode(sort(value));
  }
}
