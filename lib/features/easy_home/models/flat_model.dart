class FlatModel {
  final String id;
  final String floor;
  final String unit;
  final String code;

  const FlatModel({
    required this.id,
    required this.floor,
    required this.unit,
    required this.code,
  });

  factory FlatModel.fromMap(Map<String, dynamic> map) {
    return FlatModel(
      id: map['id'],
      floor: map['floor'],
      unit: map['unit'],
      code: map['code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'floor': floor, 'unit': unit, 'code': code};
  }
}
