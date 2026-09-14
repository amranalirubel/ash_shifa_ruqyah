import 'seed_mom_child_care.dart';

/// Verified offline content shown while Firestore is unavailable or empty.
const List<String> defaultMomChildDailyTips = [
  'মায়ের স্বাস্থ্যই শিশুর সবচেয়ে বড় সম্পদ।',
  'প্রথম ১০০০ দিন শিশুর ভবিষ্যৎ গড়ে দেয়।',
  'সঠিক পুষ্টি মেধা ও শারীরিক বিকাশের চাবিকাঠি।',
  'নিয়মিত ঘুম ও খেলা শিশুকে সুস্থ রাখে।',
  'মা-শিশুর বন্ধন সবচেয়ে শক্তিশালী সম্পর্ক।',
  'মায়ের স্নেহপূর্ণ স্পর্শ ও কথা শিশুর বিকাশে সহায়তা করে।',
];

/// Stable IDs bind editable labels to routes that remain inside the app.
const List<String> momChildSmartToolIds = [
  'vaccination_schedule',
  'growth_tracking',
  'development_milestones',
  'nutrition_plan',
  'medicine_reminder',
  'health_record',
];

/// Returns the publishable six-document catalog.
///
/// The original full-version builder remains the authoritative long-form
/// content source. This lightweight catalog adds independently managed
/// defaults without duplicating that large source file.
List<Map<String, dynamic>> buildMomChildCarePublishedDocuments() {
  final documents = buildMomChildCareSeedDocuments();

  for (final document in documents) {
    if (document['id'] != 'smart_tools') continue;

    final data = document['data']! as Map<String, dynamic>;
    final rawSections = data['sections'];
    if (rawSections is List) {
      final sections = rawSections
          .whereType<Map>()
          .map((section) => Map<String, dynamic>.from(section))
          .toList(growable: false);
      if (sections.length == momChildSmartToolIds.length) {
        for (var index = 0; index < sections.length; index++) {
          sections[index]['id'] = momChildSmartToolIds[index];
        }
        data['sections'] = sections;
      }
    }

    final currentTips = data['dailyTips'];
    final hasPublishedTips =
        currentTips is List &&
        currentTips.whereType<String>().any((tip) => tip.trim().isNotEmpty);

    if (!hasPublishedTips) {
      data['dailyTips'] = List<String>.from(defaultMomChildDailyTips);
    }
  }

  return documents;
}
