import 'package:bongo_foodie/core/l10n/daily_copy.dart';
import 'package:bongo_foodie/core/utils/daily_selection.dart';
import 'package:bongo_foodie/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dar calendar boundary is midnight UTC+3, not device midnight', () {
    expect(darCalendarDay(DateTime.parse('2026-12-31T20:59:59Z')),
        DateTime.utc(2026, 12, 31));
    expect(darCalendarDay(DateTime.parse('2026-12-31T21:00:00Z')),
        DateTime.utc(2027));
  });
  test('full date advances across month and leap-year boundaries', () {
    for (final date in [
      DateTime.utc(2026, 1, 31),
      DateTime.utc(2024, 2, 28),
      DateTime.utc(2024, 2, 29),
      DateTime.utc(2026, 12, 31)
    ]) {
      final next = date.add(const Duration(days: 1));
      expect(selectDaily(DailyCopy.discoveries, date, (d) => d.id)?.id,
          isNot(selectDaily(DailyCopy.discoveries, next, (d) => d.id)?.id));
    }
  });
  test('stable within a Dar day, restart, reorder and locale', () {
    final date = DateTime.utc(2026, 11, 9);
    final selected = selectDaily(DailyCopy.discoveries, date, (d) => d.id)!;
    expect(
        selectDaily(DailyCopy.discoveries.reversed,
            date.add(const Duration(hours: 20)), (d) => d.id)?.id,
        selected.id);
    expect(selectDaily(DailyCopy.discoveriesSw, date, (d) => d.id)?.id,
        selected.id);
    expect(selectDaily(<String>[], date, (s) => s), isNull);
    expect(selectDaily(['only'], date, (s) => s), 'only');
  });
  test('bundled translations preserve identity and answer order', () {
    for (var i = 0; i < DailyCopy.trivia.length; i++) {
      final en = DailyCopy.trivia[i];
      final sw = DailyCopy.question(en, isSw: true);
      expect(sw.id, en.id);
      expect(sw.correctIndex, en.correctIndex);
      expect(sw.options.length, en.options.length);
      expect(sw.correctIndex, inInclusiveRange(0, sw.options.length - 1));
      expect(sw.question, isNot(en.question));
      expect(sw.explainer, isNotEmpty);
    }
    for (final en in DailyCopy.discoveries) {
      final sw = DailyCopy.discovery(en, isSw: true);
      expect(sw.id, en.id);
      expect(sw.description, isNot(en.description));
    }
  });
  test('staff content is not replaced by a bundled ID collision', () {
    const staff = DiscoveryModel(
        id: 'disc-1', title: 'Our own story', description: 'Written by staff');
    expect(identical(DailyCopy.discovery(staff, isSw: true), staff), isTrue);
  });
}
