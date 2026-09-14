import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/mom_child_care/data/mom_child_content_validator.dart';
import 'mom_child_content_catalog.dart';

/// Uploads the six canonical documents under `mom_child_care`.
///
/// Each document has its own transaction, so one failure cannot roll back
/// documents already completed. Missing and structurally invalid documents are
/// repaired by default. Canonical existing documents stay untouched unless
/// [mergeExisting] is enabled. Updates merge managed fields and never delete a
/// document.
Future<void> seedMomChildCareFullVersion({
  bool mergeExisting = false,
  FirebaseFirestore? firestore,
}) async {
  final database = firestore ?? FirebaseFirestore.instance;

  for (final document in buildMomChildCarePublishedDocuments()) {
    final documentId = document['id']! as String;
    final bundledData = document['data']! as Map<String, dynamic>;
    final reference = database.collection('mom_child_care').doc(documentId);

    await database.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final existing = snapshot.data() ?? const <String, dynamic>{};
      final safeData = documentId == 'smart_tools'
          ? _preservePublishedSmartToolData(bundledData, existing)
          : bundledData;
      final data = <String, dynamic>{
        ...safeData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists) {
        transaction.set(reference, data);
      } else if (mergeExisting ||
          !MomChildContentValidator.isCanonicalDocument(
            documentId,
            snapshot.data() ?? const <String, dynamic>{},
          )) {
        transaction.set(reference, data, SetOptions(merge: true));
      }
    });
  }
}

Map<String, dynamic> _preservePublishedSmartToolData(
  Map<String, dynamic> bundled,
  Map<String, dynamic> existing,
) {
  final result = Map<String, dynamic>.from(bundled);

  for (final field in const [
    'dailyTips',
    'milestones',
    'vaccinationSchedule',
  ]) {
    final current = existing[field];
    if (current is! List) continue;

    if (field == 'dailyTips') {
      final tips = current
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (tips.isNotEmpty) result[field] = tips;
      continue;
    }

    final records = current
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (records.isNotEmpty) result[field] = records;
  }

  return result;
}
