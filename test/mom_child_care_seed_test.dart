import 'package:flutter_test/flutter_test.dart';

import 'package:ash_shifa_ruqyah/utils/seed_mom_child_care.dart';

void main() {
  test(
    'Mom & Child Care seed contains the six canonical documents in order',
    () {
      final documents = buildMomChildCareSeedDocuments();

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
        _expectFirestoreSafe(data);
      }

      final smartTools = documents[2]['data']! as Map<String, dynamic>;
      expect(smartTools, contains('vaccinationSchedule'));
      expect(smartTools, contains('milestones'));
      expect(smartTools, contains('dailyTips'));
    },
  );
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
