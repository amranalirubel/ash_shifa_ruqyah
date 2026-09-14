import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/features/mom_child_care/data/mom_child_content_validator.dart';
import 'package:ash_shifa_ruqyah/utils/mom_child_content_catalog.dart';

void main() {
  test(
    'Mom & Child Care seed contains the six canonical documents in order',
    () {
      final documents = buildMomChildCarePublishedDocuments();

      expect(documents.map((document) => document['id']), const [
        'problems',
        'parenting_guide',
        'smart_tools',
        'age_based_care',
        'learning_development',
        'instant_care',
      ]);

      for (var index = 0; index < documents.length; index++) {
        final document = documents[index];
        final data = document['data']! as Map<String, dynamic>;
        expect(data['title'], isNotEmpty);
        expect(data['displayOrder'], index + 1);
        expect(
          MomChildContentValidator.isCanonicalDocument(
            document['id']! as String,
            data,
          ),
          isTrue,
        );
        _expectFirestoreSafe(data);
      }

      final smartTools = documents[2]['data']! as Map<String, dynamic>;
      expect(smartTools, contains('vaccinationSchedule'));
      expect(smartTools, contains('milestones'));
      expect(smartTools, contains('dailyTips'));
      expect(smartTools['dailyTips'], isA<List<String>>());
      expect(smartTools['dailyTips'], isNotEmpty);
      final smartToolSections = (smartTools['sections']! as List)
          .whereType<Map>()
          .toList(growable: false);
      expect(
        smartToolSections.map((section) => section['id']),
        momChildSmartToolIds,
      );
    },
  );

  test('old or incomplete cloud documents cannot replace bundled content', () {
    expect(
      MomChildContentValidator.isCanonicalDocument('problems', {
        'title': 'পুরোনো সমস্যা সমাধান',
        'intro': 'অসম্পূর্ণ',
        'sections': const [],
      }),
      isFalse,
    );

    expect(
      MomChildContentValidator.isCanonicalDocument('parenting_guide', {
        'title': 'পুরোনো প্যারেন্টিং গাইড',
        'sections': [
          {
            'title': 'শিশুর সাথে যোগাযোগ',
            'topics': [
              {'title': 'একটি পুরোনো বিষয়'},
            ],
          },
        ],
      }),
      isFalse,
    );

    expect(
      MomChildContentValidator.isCanonicalDocument('problems', {
        'title': 'ভুল schema',
        'contentVersion': 'legacy',
        'schemaVersion': 1,
        'displayOrder': 1,
        'topicCount': 1,
        'categoryCount': 1,
        'sections': 'this should have been a list',
      }),
      isFalse,
    );
  });

  test('Smart Tool sections require stable route IDs', () {
    final documents = buildMomChildCarePublishedDocuments();
    final smartTools = Map<String, dynamic>.from(
      documents[2]['data']! as Map<String, dynamic>,
    );
    final sections = (smartTools['sections']! as List)
        .whereType<Map>()
        .map((section) => Map<String, dynamic>.from(section))
        .toList(growable: false);
    sections.first.remove('id');
    smartTools['sections'] = sections;

    expect(
      MomChildContentValidator.isCanonicalDocument('smart_tools', smartTools),
      isFalse,
    );
  });
}

void _expectFirestoreSafe(dynamic value, {bool insideArray = false}) {
  if (value is Map) {
    for (final child in value.values) {
      _expectFirestoreSafe(child);
    }
    return;
  }

  if (value is List) {
    expect(
      insideArray,
      isFalse,
      reason: 'Cloud Firestore does not support arrays nested in arrays.',
    );

    for (final child in value) {
      _expectFirestoreSafe(child, insideArray: true);
    }
  }
}
