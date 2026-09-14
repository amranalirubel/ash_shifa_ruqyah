import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/features/health_tips/data/health_content_catalog.dart';

void main() {
  test('health catalogue identifiers are unique', () {
    expect(_ids(HealthContentCatalog.banners.map((item) => item.id)), isTrue);
    expect(_ids(HealthContentCatalog.dailyTips.map((item) => item.id)), isTrue);
    expect(
      _ids(HealthContentCatalog.movementGuides.map((item) => item.id)),
      isTrue,
    );
    expect(
      _ids(HealthContentCatalog.dietGuides.map((item) => item.id)),
      isTrue,
    );
  });

  test('every health claim resolves to an HTTPS source', () {
    final referencedIds = <String>{
      ...HealthContentCatalog.banners.expand((item) => item.sourceIds),
      ...HealthContentCatalog.dailyTips.expand((item) => item.sourceIds),
      ...HealthContentCatalog.movementGuides.expand((item) => item.sourceIds),
      ...HealthContentCatalog.dietGuides.expand((item) => item.sourceIds),
    };

    for (final id in referencedIds) {
      final source = HealthContentCatalog.sources[id];
      expect(source, isNotNull, reason: 'Missing health source: ' + id);
      expect(
        Uri.parse(source!.url).scheme,
        'https',
        reason: 'Source must use HTTPS: ' + id,
      );
      expect(source.organization.trim(), isNotEmpty);
      expect(source.title.trim(), isNotEmpty);
      expect(source.reviewedOn, HealthContentCatalog.editorialReviewDate);
    }
  });

  test('requested pain and mindfulness categories are fully represented', () {
    final categories = HealthContentCatalog.movementGuides
        .map((guide) => guide.category)
        .toSet();

    expect(categories, containsAll(HealthGuideCategory.values));
    expect(
      HealthContentCatalog.movementGuides
          .where((guide) => guide.category == HealthGuideCategory.kneeCare),
      isNotEmpty,
    );
    expect(
      HealthContentCatalog.movementGuides
          .where((guide) => guide.category == HealthGuideCategory.backCare),
      isNotEmpty,
    );
    expect(
      HealthContentCatalog.movementGuides
          .where((guide) => guide.category == HealthGuideCategory.handCare),
      isNotEmpty,
    );
    expect(
      HealthContentCatalog.movementGuides.where(
        (guide) => guide.category == HealthGuideCategory.mindfulness,
      ),
      isNotEmpty,
    );
  });

  test('movement guides contain steps, dosage, warnings, and sources', () {
    for (final guide in HealthContentCatalog.movementGuides) {
      expect(guide.steps.length, greaterThanOrEqualTo(3));
      expect(guide.dosage.trim(), isNotEmpty);
      expect(guide.stopAndSeekHelp, isNotEmpty);
      expect(guide.sourceIds, isNotEmpty);
    }
  });

  test('diet guides never omit the clinical safety note', () {
    for (final guide in HealthContentCatalog.dietGuides) {
      expect(guide.chooseMoreOften, isNotEmpty);
      expect(guide.limitMoreOften, isNotEmpty);
      expect(guide.clinicalNote.trim(), isNotEmpty);
      expect(guide.sourceIds, isNotEmpty);
    }
  });
}

bool _ids(Iterable<String> ids) {
  final values = ids.toList();
  return values.toSet().length == values.length;
}
