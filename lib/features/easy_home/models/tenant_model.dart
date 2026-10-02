import '../utils/easy_home_format.dart';

class TenantModel {
  const TenantModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.flatId,
    required this.flatCode,
    required this.floor,
    required this.rentPaisa,
    required this.startDate,
    this.userId = '',
    this.dueDay = 5,
    this.endDate,
    this.active = true,
  });
  final String id, userId, name, phone, flatId, flatCode, floor;
  final int rentPaisa, dueDay;
  final DateTime startDate;
  final DateTime? endDate;
  final bool active;
  factory TenantModel.fromMap(Map<String, dynamic> m) => TenantModel(
    id: m['id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    userId: m['userId'] as String? ?? '',
    flatId: m['flatId'] as String,
    flatCode: m['flatCode'] as String,
    floor: m['floor'] as String,
    rentPaisa: (m['rentPaisa'] as num).toInt(),
    dueDay: (m['dueDay'] as num).toInt(),
    startDate: readDate(m['startDate']),
    endDate: m['endDate'] == null ? null : readDate(m['endDate']),
    active: m['active'] == true,
  );
}
