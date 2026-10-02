import 'package:cloud_firestore/cloud_firestore.dart';

String latinDigits(String value) {
  const bangla = '০১২৩৪৫৬৭৮৯';
  for (var i = 0; i < bangla.length; i++) {
    value = value.replaceAll(bangla[i], '$i');
  }
  return value.trim();
}

String bn(Object value) => value.toString().replaceAllMapped(
  RegExp('[0-9]'),
  (m) => '০১২৩৪৫৬৭৮৯'[int.parse(m[0]!)],
);

int? parsePaisa(String input) {
  final value = latinDigits(input).replaceAll(',', '');
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(value)) return null;
  final parts = value.split('.');
  final paisa =
      int.parse(parts.first) * 100 +
      (parts.length == 2 ? int.parse(parts.last.padRight(2, '0')) : 0);
  return paisa <= 100000000 ? paisa : null;
}

String moneyInput(int paisa) =>
    '${paisa ~/ 100}${paisa % 100 == 0 ? '' : '.${(paisa % 100).toString().padLeft(2, '0')}'}';
String money(int paisa) => '৳${bn(moneyInput(paisa))}';
String monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';
DateTime monthDate(String month) => DateTime.parse('$month-01');
String dateText(DateTime date) => bn('${date.day}/${date.month}/${date.year}');
String monthText(String month) {
  const names = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];
  final date = monthDate(month);
  return '${names[date.month - 1]} ${bn(date.year)}';
}

DateTime readDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse('$value') ?? DateTime(1970);
}

String easyHomeError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'এই বাড়ির তথ্য ব্যবহারের অনুমতি নেই। বাড়িওয়ালার সাথে যোগাযোগ করুন।',
      'unavailable' || 'deadline-exceeded' =>
        'সংযোগ পাওয়া যাচ্ছে না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।',
      'not-found' => 'তথ্যটি পাওয়া যায়নি। আবার খুলে দেখুন।',
      _ => 'তথ্য সেভ বা লোড করা যায়নি। আবার চেষ্টা করুন।',
    };
  }
  if (error is StateError) return error.message;
  if (error is ArgumentError) return '${error.message}';
  return 'কাজটি সম্পন্ন হয়নি। আবার চেষ্টা করুন।';
}
