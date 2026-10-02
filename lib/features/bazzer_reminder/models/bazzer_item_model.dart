import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/bazzer_format.dart';

class BazzerItem {
  const BazzerItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.category,
    required this.createdAt,
    this.isBought = false,
    this.addedBy = 'অজানা',
    this.createdBy = '',
    this.boughtBy,
    this.hasPendingWrites = false,
    this.isSecure = false,
    this.noteDate,
    this.pricePaisa,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final bool isBought;
  final DateTime createdAt;
  final String addedBy;
  final String createdBy;
  final String? boughtBy;
  final bool hasPendingWrites;
  final bool isSecure;
  final String? noteDate;
  final int? pricePaisa;
  String get dayKey => noteDate != null && validBazzerDayKey(noteDate!)
      ? noteDate!
      : bazzerDayKey(createdAt);

  factory BazzerItem.fromMap(
    Map<String, dynamic> map,
    String id, {
    bool hasPendingWrites = false,
    bool isSecure = false,
  }) {
    final rawDate = map['clientCreatedAt'] ?? map['createdAt'];
    DateTime date = DateTime.now();
    if (rawDate is DateTime) {
      date = rawDate;
    } else if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? date;
    } else if (rawDate is Timestamp) {
      date = rawDate.toDate();
    }
    final rawQuantity = map['quantity'];
    return BazzerItem(
      id: id,
      name: (map['name'] as String? ?? '').trim(),
      quantity: rawQuantity is num ? rawQuantity.toDouble() : 1,
      unit: map['unit'] as String? ?? 'টা',
      category: map['category'] as String? ?? 'অন্যান্য',
      isBought: map['isBought'] == true,
      createdAt: date,
      addedBy: map['addedBy'] as String? ?? 'অজানা',
      createdBy: map['createdBy'] as String? ?? '',
      boughtBy: map['boughtBy'] as String?,
      hasPendingWrites: hasPendingWrites,
      isSecure: isSecure,
      noteDate: map['noteDate'] as String?,
      pricePaisa: map['pricePaisa'] is int ? map['pricePaisa'] as int : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name.trim(),
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'isBought': isBought,
    'createdAt': createdAt.toIso8601String(),
    'addedBy': addedBy,
    'createdBy': createdBy,
    'noteDate': dayKey,
    'pricePaisa': pricePaisa,
  };

  BazzerItem copyWith({
    bool? isBought,
    String? addedBy,
    String? createdBy,
    bool? hasPendingWrites,
    bool? isSecure,
    int? pricePaisa,
    bool clearPrice = false,
    DateTime? createdAt,
    String? noteDate,
  }) => BazzerItem(
    id: id,
    name: name,
    quantity: quantity,
    unit: unit,
    category: category,
    isBought: isBought ?? this.isBought,
    createdAt: createdAt ?? this.createdAt,
    addedBy: addedBy ?? this.addedBy,
    createdBy: createdBy ?? this.createdBy,
    boughtBy: boughtBy,
    hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
    isSecure: isSecure ?? this.isSecure,
    noteDate: noteDate ?? this.noteDate,
    pricePaisa: clearPrice ? null : pricePaisa ?? this.pricePaisa,
  );
}
