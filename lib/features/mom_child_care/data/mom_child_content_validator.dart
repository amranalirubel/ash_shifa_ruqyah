class MomChildContentValidator {
  const MomChildContentValidator._();

  static const int supportedSchemaVersion = 1;

  static const List<String> documentIds = [
    'problems',
    'parenting_guide',
    'smart_tools',
    'age_based_care',
    'learning_development',
    'instant_care',
  ];

  /// Prevents an old, partial, or malformed cloud document from replacing the
  /// complete bundled snapshot shown by the app.
  static bool isCanonicalDocument(
    String documentId,
    Map<String, dynamic> data,
  ) {
    final documentIndex = documentIds.indexOf(documentId);
    if (documentIndex < 0 || data.isEmpty) return false;

    final title = data['title'];
    final contentVersion = data['contentVersion'];
    final schemaVersion = data['schemaVersion'];
    final displayOrder = data['displayOrder'];
    final topicCount = data['topicCount'];
    final categoryCount = data['categoryCount'];
    final sections = _mapList(data['sections']);

    if (title is! String || title.trim().isEmpty) return false;
    if (contentVersion is! String || contentVersion.trim().isEmpty) {
      return false;
    }
    if (schemaVersion != supportedSchemaVersion) return false;
    if (displayOrder != documentIndex + 1) return false;
    if (topicCount is! int || topicCount <= 0) return false;
    if (categoryCount is! int || categoryCount <= 0) return false;
    if (sections.length != categoryCount) return false;

    if (documentId == 'problems' || documentId == 'parenting_guide') {
      final topics = sections.expand((section) => _mapList(section['topics']));
      final topicList = topics.toList(growable: false);

      if (topicList.length != topicCount) return false;
      return topicList.every(
        (topic) =>
            _hasText(topic['title']) && _mapList(topic['items']).isNotEmpty,
      );
    }

    if (topicCount != sections.length) return false;

    if (documentId == 'smart_tools') {
      return sections.every(
        (section) =>
            _hasText(section['title']) && _hasText(section['description']),
      );
    }

    return sections.every(
      (section) =>
          _hasText(section['title']) && _mapList(section['items']).isNotEmpty,
    );
  }

  static bool _hasText(dynamic value) =>
      value is String && value.trim().isNotEmpty;

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }
}
