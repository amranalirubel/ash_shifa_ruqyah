import 'package:ash_shifa_ruqyah/features/bazzer_reminder/models/bazzer_item_model.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/utils/bazzer_receipt.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

BazzerItem receiptItem(
  String id, {
  int? price,
  String day = '2026-09-24',
  bool bought = false,
}) => BazzerItem(
  id: id,
  name: id,
  quantity: 1,
  unit: 'কেজি',
  category: 'সবজি',
  createdAt: DateTime.utc(2026, 9, 24, 10),
  noteDate: day,
  pricePaisa: price,
  isBought: bought,
);

void main() {
  test('integer paisa preserves decimal totals and Bengali price entry', () {
    expect(parseBazzerPrice('১০.২৫'), 1025);
    expect(parseBazzerPrice('২০.৫'), 2050);
    expect(parseBazzerPrice('0'), 0);
    expect(bazzerMoney(1025 + 2050), '৳ ৩০.৭৫');
    for (final invalid in ['', '-10', 'NaN', '1e3', '12.345', '1000000.01']) {
      expect(parseBazzerPrice(invalid), isNull);
    }
  });

  test('running totals recalculate from prices, never accumulate taps', () {
    final first = receiptItem('a', price: 1000);
    final second = receiptItem('b', price: 2000);
    final unpriced = receiptItem('c');
    final initial = BazzerDailyNote('2026-09-24', [second, unpriced, first]);
    expect(initial.runningTotals, [1000, 3000, 3000]);
    expect(initial.unpricedCount, 1);
    final changed = BazzerDailyNote(initial.day, [
      first.copyWith(pricePaisa: 5000),
      second,
      unpriced,
    ]);
    expect(changed.runningTotals, [5000, 7000, 7000]);
    final removed = BazzerDailyNote(initial.day, [second, unpriced]);
    expect(removed.totalPaisa, 2000);
    expect(
      BazzerDailyNote(initial.day, [
        first.copyWith(clearPrice: true),
      ]).totalPaisa,
      0,
    );
  });

  test(
    'Bangladesh midnight starts a new note and each day totals independently',
    () {
      expect(bazzerDayKey(DateTime.utc(2026, 9, 24, 17, 59)), '2026-09-24');
      expect(bazzerDayKey(DateTime.utc(2026, 9, 24, 18)), '2026-09-25');
      final notes = BazzerDailyNote.group([
        receiptItem('a', price: 1000),
        receiptItem('b', price: 2000, bought: true),
        receiptItem('c', price: 5000, day: '2026-09-25'),
      ]);
      expect(notes.map((note) => note.day), ['2026-09-25', '2026-09-24']);
      expect(notes.map((note) => note.totalPaisa), [5000, 3000]);
      expect(bazzerDayLabel('2026-09-24'), '২৪ সেপ্টেম্বর ২০২৬');
    },
  );

  test(
    'offline items keep their note date when server timestamps arrive later',
    () {
      final clientTime = Timestamp.fromDate(DateTime.utc(2026, 9, 24, 17));
      final data = <String, dynamic>{
        'name': 'আদা',
        'noteDate': '2026-09-24',
        'clientCreatedAt': clientTime,
        'createdAt': null,
        'pricePaisa': 1000,
      };
      final pending = BazzerItem.fromMap(data, 'a', hasPendingWrites: true);
      final saved = BazzerItem.fromMap({
        ...data,
        'createdAt': Timestamp.fromDate(DateTime.utc(2026, 9, 26)),
      }, 'a');
      expect(pending.dayKey, saved.dayKey);
      expect(saved.createdAt, clientTime.toDate());
      expect(saved.pricePaisa, 1000);
      final legacy = BazzerItem.fromMap({'createdAt': clientTime}, 'old');
      expect(legacy.dayKey, '2026-09-24');
      expect(legacy.pricePaisa, isNull);
      expect(validBazzerDayKey('2026-02-31'), isFalse);
    },
  );
}
