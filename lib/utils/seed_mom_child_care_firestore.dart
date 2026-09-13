import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/mom_child_care/data/mom_child_content_validator.dart';
import 'seed_mom_child_care.dart';

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

  for (final document in buildMomChildCareSeedDocuments()) {
    final documentId = document['id']! as String;
    final bundledData = document['data']! as Map<String, dynamic>;
    final data = <String, dynamic>{
      ...bundledData,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    final reference = database.collection('mom_child_care').doc(documentId);

    await database.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);

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
