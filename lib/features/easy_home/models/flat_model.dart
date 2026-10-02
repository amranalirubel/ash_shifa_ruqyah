class FlatModel {
  const FlatModel({
    required this.id,
    required this.floor,
    required this.unit,
    required this.code,
    this.tenancyId = '',
    this.archived = false,
  });
  final String id, floor, unit, code, tenancyId;
  final bool archived;
  bool get occupied => tenancyId.isNotEmpty;
  factory FlatModel.fromMap(Map<String, dynamic> m) => FlatModel(
    id: m['id'] as String,
    floor: m['floor'] as String,
    unit: m['unit'] as String,
    code: m['code'] as String,
    tenancyId: m['tenancyId'] as String? ?? '',
    archived: m['archived'] == true,
  );
}
