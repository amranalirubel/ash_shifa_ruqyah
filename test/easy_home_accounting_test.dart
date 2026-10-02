import 'package:flutter_test/flutter_test.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/models/easy_home_models.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/screens/easy_home_rents.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/utils/easy_home_format.dart';

TenantModel tenant({DateTime? end, DateTime? start}) => TenantModel(
  id: 'lease',
  name: 'মাহমুদ',
  phone: '01700000000',
  flatId: '2_B',
  flatCode: '2B-K9X4',
  floor: '2',
  rentPaisa: 650050,
  dueDay: 5,
  startDate: start ?? DateTime(2025, 12, 20),
  endDate: end,
  active: end == null,
);
void main() {
  test('Bangla decimal rent is exact integer paisa; malformed and huge amounts fail', () {
    expect(parsePaisa('৬,৫০০.৫০'), 650050);
    expect(parsePaisa('০.০১'), 1);
    for (final invalid in [
      '-1',
      'NaN',
      'Infinity',
      '1e4',
      '1.001',
      '1000000.01',
      '',
    ]) {
      expect(parsePaisa(invalid), isNull, reason: invalid);
    }
    expect(money(650050), '৳৬৫০০.৫০');
  });
  test(
    'billing crosses year and leap February and stops at move-out month',
    () {
      expect(rentalMonths(tenant(), DateTime(2026, 2, 1)), [
        '2025-12',
        '2026-01',
        '2026-02',
      ]);
      expect(
        rentalMonths(tenant(end: DateTime(2026, 1, 1)), DateTime(2026, 4)),
        ['2025-12', '2026-01'],
      );
      expect(
        rentalMonths(
          tenant(start: DateTime(2028, 2, 29)),
          DateTime(2028, 3, 2),
        ),
        ['2028-02', '2028-03'],
      );
      expect(
        rentalMonths(tenant(start: DateTime(2027)), DateTime(2026)),
        isEmpty,
      );
    },
  );
  test('partial payments and corrections cannot overpay or make the ledger negative', () {
    expect(
      paymentBalance(amount: 650050, paid: 200000, change: 450050),
      650050,
    );
    expect(
      paymentBalance(amount: 650050, paid: 200000, change: -50000),
      150000,
    );
    for (final delta in [0, -200001, 450051]) {
      expect(
        () => paymentBalance(amount: 650050, paid: 200000, change: delta),
        throwsStateError,
      );
    }
  });
  test('due calculations and receipts preserve amount and ledger identity', () {
    final rent = RentModel(
      id: 'lease_2026-02',
      tenantId: 'lease',
      flatCode: '2B-K9X4',
      month: '2026-02',
      amountPaisa: 650050,
      paidPaisa: 200000,
      dueDate: DateTime(2026, 2, 5),
      createdAt: DateTime(2026, 2),
    );
    expect(rent.status, RentStatus.partial);
    expect(rent.duePaisa, 450050);
    expect(rent.overdue(DateTime(2026, 2, 5, 23)), isFalse);
    expect(rent.overdue(DateTime(2026, 2, 6)), isTrue);
    final text = rentReceipt(
      'আমাদের বাড়ি',
      rent,
      RentPayment(
        id: 'receipt-1',
        amountPaisa: -50000,
        balancePaisa: 150000,
        note: 'ভুল এন্ট্রি সংশোধন',
        method: 'correction',
        createdAt: DateTime(2026, 2, 6),
      ),
    );
    expect(text, contains('সংশোধন: ৳৫০০'));
    expect(text, contains('রসিদ নম্বর: receipt-1'));
    expect(text, isNot(contains('01700000000')));
  });
}
