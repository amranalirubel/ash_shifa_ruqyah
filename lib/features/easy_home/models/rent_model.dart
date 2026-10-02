import '../utils/easy_home_format.dart';
import 'tenant_model.dart';

enum RentStatus { paid, partial, due }

class RentModel {
  const RentModel({
    required this.id,
    required this.tenantId,
    required this.flatCode,
    required this.month,
    required this.amountPaisa,
    this.paidPaisa = 0,
    required this.dueDate,
    required this.createdAt,
  });
  final String id, tenantId, flatCode, month;
  final int amountPaisa, paidPaisa;
  final DateTime dueDate, createdAt;
  int get duePaisa => amountPaisa - paidPaisa;
  RentStatus get status => duePaisa == 0
      ? RentStatus.paid
      : paidPaisa > 0
      ? RentStatus.partial
      : RentStatus.due;
  String get statusLabel => switch (status) {
    RentStatus.paid => 'পরিশোধিত',
    RentStatus.partial => 'আংশিক পরিশোধ',
    RentStatus.due => 'বকেয়া',
  };
  bool overdue(DateTime today) =>
      duePaisa > 0 &&
      DateTime(today.year, today.month, today.day).isAfter(dueDate);
  factory RentModel.fromMap(Map<String, dynamic> m) => RentModel(
    id: m['id'] as String,
    tenantId: m['tenantId'] as String,
    flatCode: m['flatCode'] as String,
    month: m['month'] as String,
    amountPaisa: (m['amountPaisa'] as num).toInt(),
    paidPaisa: (m['paidPaisa'] as num).toInt(),
    dueDate: readDate(m['dueDate']),
    createdAt: readDate(m['createdAt']),
  );
}

/// Full calendar months, including the move-in and move-out month. Existing
/// invoices are immutable; editing a tenancy never rewrites historical rent.
List<String> rentalMonths(TenantModel tenant, DateTime through) {
  final end = tenant.endDate != null && tenant.endDate!.isBefore(through)
      ? tenant.endDate!
      : through;
  final result = <String>[];
  for (
    var d = DateTime(tenant.startDate.year, tenant.startDate.month);
    !d.isAfter(DateTime(end.year, end.month));
    d = DateTime(d.year, d.month + 1)
  ) {
    result.add(monthKey(d));
  }
  return result;
}

int paymentBalance({
  required int amount,
  required int paid,
  required int change,
}) {
  final next = paid + change;
  if (change == 0 || next < 0 || next > amount) {
    throw StateError(
      'জমার পরিমাণ বকেয়ার বেশি বা সংশোধন জমার বেশি হতে পারবে না।',
    );
  }
  return next;
}

class RentPayment {
  const RentPayment({
    required this.id,
    required this.amountPaisa,
    required this.balancePaisa,
    required this.note,
    required this.method,
    required this.createdAt,
  });
  final String id, note, method;
  final int amountPaisa, balancePaisa;
  final DateTime createdAt;
  factory RentPayment.fromMap(Map<String, dynamic> m) => RentPayment(
    id: m['id'] as String,
    amountPaisa: (m['amountPaisa'] as num).toInt(),
    balancePaisa: (m['balancePaisa'] as num).toInt(),
    note: m['note'] as String,
    method: m['method'] as String,
    createdAt: readDate(m['createdAt']),
  );
}
