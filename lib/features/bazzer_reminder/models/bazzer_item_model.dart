class BazzerItem {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool isBought;
  final DateTime createdAt;
  final String addedBy;

  const BazzerItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    this.isBought = false,
    required this.createdAt,
    this.addedBy = "অজানা",
  });

  factory BazzerItem.fromMap(Map<String, dynamic> map, String id) {
    return BazzerItem(
      id: id,
      name: map['name'] ?? '',
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] ?? 'টা',
      category: map['category'] ?? 'নিত্যপণ্য',
      isBought: map['isBought'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      addedBy: map['addedBy'] ?? 'অজানা',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'category': category,
      'isBought': isBought,
      'createdAt': createdAt.toIso8601String(),
      'addedBy': addedBy,
    };
  }

  BazzerItem copyWith({bool? isBought, String? addedBy}) {
    return BazzerItem(
      id: id,
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt,
      addedBy: addedBy ?? this.addedBy,
    );
  }
}
