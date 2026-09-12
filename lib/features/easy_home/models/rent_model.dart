enum RentStatus { paid, due }

class RentModel {
  final String id;
  final String tenantId;
  final String month; // "2026-03"
  final double amount;
  final RentStatus status;
  final DateTime createdAt;

  const RentModel({
    required this.id,
    required this.tenantId,
    required this.month,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory RentModel.fromMap(Map<String, dynamic> map) {
    return RentModel(
      id: map['id'],
      tenantId: map['tenantId'],
      month: map['month'],
      amount: (map['amount'] as num).toDouble(),
      status: RentStatus.values.firstWhere((e) => e.name == map['status']),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenantId': tenantId,
      'month': month,
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
