import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/bazzer_receipt.dart';

/// A saved daily snapshot. Saving the same day replaces this document.
class BazzerExpense {
  const BazzerExpense({
    required this.day,
    required this.totalPaisa,
    required this.itemCount,
    this.savedAt,
    this.hasPendingWrites = false,
  });
  final String day;
  final int totalPaisa;
  final int itemCount;
  final DateTime? savedAt;
  final bool hasPendingWrites;

  factory BazzerExpense.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return BazzerExpense(
      day: data['day'] as String,
      totalPaisa: data['totalPaisa'] as int,
      itemCount: data['itemCount'] as int,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate(),
      hasPendingWrites: doc.metadata.hasPendingWrites,
    );
  }
}

/// Shared and private amounts never travel in the same public document.
class BazzerExpenseDraft {
  BazzerExpenseDraft.fromNote(BazzerDailyNote note)
    : day = note.day,
      sharedPaisa = note.items
          .where((item) => !item.isSecure)
          .fold(0, (amount, item) => amount + (item.pricePaisa ?? 0)),
      sharedCount = note.items.where((item) => !item.isSecure).length,
      totalPaisa = note.totalPaisa,
      itemCount = note.items.length {
    if (!validBazzerDayKey(day) ||
        note.items.isEmpty ||
        itemCount > 1000000 ||
        note.items.any(
          (item) =>
              item.dayKey != day ||
              item.hasPendingWrites ||
              item.pricePaisa == null ||
              item.pricePaisa! < 0 ||
              item.pricePaisa! > bazzerMaxPricePaisa,
        )) {
      throw const FormatException(
        'সব আইটেমের দাম দিয়ে পাঠানো শেষ হলে Save করুন।',
      );
    }
  }
  final String day;
  final int sharedPaisa;
  final int sharedCount;
  final int totalPaisa;
  final int itemCount;
  String get signature => '$sharedPaisa/$sharedCount/$totalPaisa/$itemCount';
}
