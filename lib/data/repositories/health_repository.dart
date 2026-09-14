import '../../features/health_tips/data/health_content_catalog.dart';

/// Read-only gateway for clinically sensitive educational content.
///
/// The current catalogue is version-controlled and available offline. Existing
/// Firestore documents are deliberately left untouched, but they are not used
/// as trusted medical guidance until a reviewed publishing workflow exists.
class HealthRepository {
  const HealthRepository();

  List<HealthBanner> get banners => HealthContentCatalog.banners;

  List<DailyHealthTip> get dailyTips => HealthContentCatalog.dailyTips;

  List<MovementGuide> get movementGuides => HealthContentCatalog.movementGuides;

  List<DietGuide> get dietGuides => HealthContentCatalog.dietGuides;

  Map<String, HealthSource> get sources => HealthContentCatalog.sources;

  /// Compatibility adapter for older screens and external callers.
  Future<Map<String, Map<String, dynamic>>> getDiseaseFoodMap() async {
    return {
      for (final guide in dietGuides)
        guide.title: {
          'eat': guide.chooseMoreOften,
          'avoid': guide.limitMoreOften,
          'extra': guide.clinicalNote,
          'sourceIds': guide.sourceIds,
        },
    };
  }

  /// Compatibility adapter for older screens and external callers.
  Future<List<String>> getDailyHealthTips() async {
    return dailyTips.map((tip) => tip.title + ' — ' + tip.details).toList();
  }

  /// Compatibility adapter that fixes the former title/name schema mismatch.
  Future<List<Map<String, String>>> getExercises() async {
    return movementGuides
        .map(
          (guide) => {
            'id': guide.id,
            'name': guide.title,
            'title': guide.title,
            'time': guide.duration,
            'benefit': guide.summary,
            'description': guide.summary,
            'category': guide.category.name,
          },
        )
        .toList();
  }

  /// Compatibility adapter for the former quick-tips API.
  Future<List<Map<String, dynamic>>> getQuickTips() async {
    return banners
        .map(
          (banner) => {
            'id': banner.id,
            'title': banner.title,
            'description': banner.body,
            'sourceIds': banner.sourceIds,
          },
        )
        .toList();
  }
}
