import 'dart:math';

import 'package:ash_shifa_ruqyah/features/bazzer_reminder/repositories/bazzer_repository.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/utils/store_category.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/utils/voice_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unit endings split garlic and ginger from the reported recording', () {
    for (final text in [
      'রসুন ১ কেজি আদা ১ কেজি',
      'রসুন এক কেজি আদা এক কেজি',
      'রসুন ১ কেজি আদা ১ কেজি.',
    ]) {
      final result = VoiceParser.parsePreview(text);
      expect(result.needsReview, isEmpty);
      expect(result.items.map((item) => item.name), ['রসুন', 'আদা']);
      expect(result.items.map((item) => item.quantity), [1, 1]);
      expect(result.items.map((item) => item.unit), ['কেজি', 'কেজি']);
      expect(
        result.items.every((item) => item.category == StoreCategory.vegetable),
        isTrue,
      );
    }
  });

  test('units split unfamiliar multiword products without a dictionary', () {
    final result = VoiceParser.parsePreview(
      'দেশি জলপাই ৫০০ গ্রাম টক দই ১ কিলোগ্রাম নতুন কাপড় ২ প্যাকেট',
    );
    expect(result.needsReview, isEmpty);
    expect(result.items.map((item) => item.name), [
      'দেশি জলপাই',
      'টক দই',
      'নতুন কাপড়',
    ]);
    expect(result.items.map((item) => item.quantity), [500, 1, 2]);
    expect(result.items.map((item) => item.unit), ['গ্রাম', 'কেজি', 'প্যাকেট']);
  });

  test(
    'quantity-first single items and newline boundaries remain supported',
    () {
      final result = VoiceParser.parsePreview('১ কেজি রসুন\nআদা আধা কেজি');
      expect(result.needsReview, isEmpty);
      expect(result.items.map((item) => item.name), ['রসুন', 'আদা']);
      expect(result.items.map((item) => item.quantity), [1, 0.5]);
    },
  );

  test('one unpunctuated sentence becomes separate store-specific items', () {
    final result = VoiceParser.parsePreview(
      'তেল এক লিটার সাবান দুইটা আঠা একটা '
      'কাঁচা মরিচ হাফ কেজি পুই শাক এক আঁটি ধনিয়া পাতা ১০০ গ্রাম',
    );
    expect(result.needsReview, isEmpty);
    expect(result.items.map((item) => item.name), [
      'তেল',
      'সাবান',
      'আঠা',
      'কাঁচামরিচ',
      'পুঁইশাক',
      'ধনেপাতা',
    ]);
    expect(result.items.map((item) => item.quantity), [1, 2, 1, 0.5, 1, 100]);
    expect(result.items.map((item) => item.unit), [
      'লিটার',
      'টা',
      'টা',
      'কেজি',
      'আঁটি',
      'গ্রাম',
    ]);
    expect(result.items.map((item) => item.category), [
      StoreCategory.grocery,
      StoreCategory.grocery,
      StoreCategory.grocery,
      StoreCategory.vegetable,
      StoreCategory.vegetable,
      StoreCategory.vegetable,
    ]);
  });

  test('বাংলা সংখ্যা, সাড়ে, আধা, ডজন and separators are preserved', () {
    final parsed = VoiceParser.parsePreview(
      'আলু আধা কেজি, ডিম এক ডজন; চাল সাড়ে দুই কেজি।',
    );
    expect(parsed.needsReview, isEmpty);
    expect(parsed.items.map((item) => item.quantity), [0.5, 1, 2.5]);
    expect(parsed.items.map((item) => item.unit), ['কেজি', 'ডজন', 'কেজি']);
  });

  test(
    'unknown item is retained for manual review without guessing a store',
    () {
      final parsed = VoiceParser.parsePreview('নতুন কাপড় ২ প্যাকেট');
      expect(parsed.items.single.name, 'নতুন কাপড়');
      expect(parsed.items.single.category, StoreCategory.other);
      expect(parsed.items.single.quantity, 2);
    },
  );

  test('ambiguous multiple quantities are not silently sent to the family', () {
    final parsed = VoiceParser.parsePreview('তেল ১ লিটার ২ বোতল');
    expect(parsed.items, isEmpty);
    expect(parsed.needsReview, isNotEmpty);
  });

  test('unexpected words after a recognized quantity require review', () {
    final parsed = VoiceParser.parsePreview('তেল ১ লিটার অজানা কথা');
    expect(parsed.items, isEmpty);
    expect(parsed.needsReview, isNotEmpty);
  });

  test('fractional pieces are rejected, but ৫০০ গ্রাম is accepted', () {
    final parsed = VoiceParser.parsePreview(
      'সাবান আধা টা, কাঁচামরিচ ৫০০ গ্রাম',
    );
    expect(parsed.needsReview, isNotEmpty);
    expect(parsed.items.single.name, 'কাঁচামরিচ');
    expect(parsed.items.single.quantity, 500);
  });

  test('invite code has 12 non-confusable characters', () {
    final code = BazzerRepository.generateInviteCode(random: Random(11));
    expect(code, hasLength(12));
    expect(RegExp(r'^[A-HJ-NP-Z2-9]{12}$').hasMatch(code), isTrue);
  });

  test('typed vegetable aliases map to the vegetable shop', () {
    expect(StoreCategory.guess('কাঁচা মরিচ'), StoreCategory.vegetable);
    expect(StoreCategory.guess('পুই শাক'), StoreCategory.vegetable);
    expect(StoreCategory.guess('ধনিয়া পাতা'), StoreCategory.vegetable);
  });
}
