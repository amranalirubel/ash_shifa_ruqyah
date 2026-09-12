class TenantModel {
  final String id;
  final String userId;
  final String flatId;
  final double rentAmount;
  final DateTime startDate;

  const TenantModel({
    required this.id,
    required this.userId,
    required this.flatId,
    required this.rentAmount,
    required this.startDate,
  });

  factory TenantModel.fromMap(Map<String, dynamic> map) {
    return TenantModel(
      id: map['id'],
      userId: map['userId'],
      flatId: map['flatId'],
      rentAmount: (map['rentAmount'] as num).toDouble(),
      startDate: DateTime.parse(map['startDate']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'flatId': flatId,
      'rentAmount': rentAmount,
      'startDate': startDate.toIso8601String(),
    };
  }
}
