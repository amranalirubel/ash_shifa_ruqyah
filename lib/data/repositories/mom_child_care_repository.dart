import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../features/mom_child_care/data/mom_child_content_validator.dart';
import '../../utils/seed_mom_child_care.dart';

enum MomChildCloudStatus { checking, current, missing, invalid, unavailable }

@immutable
class MomChildContentResult {
  const MomChildContentResult({required this.data, required this.cloudStatus});

  final Map<String, dynamic> data;
  final MomChildCloudStatus cloudStatus;

  bool get isCloudCurrent => cloudStatus == MomChildCloudStatus.current;
}

class MomChildCareRepository {
  MomChildCareRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static final Map<String, Map<String, dynamic>> _bundledDocuments = {
    for (final document in buildMomChildCareSeedDocuments())
      document['id']! as String: document['data']! as Map<String, dynamic>,
  };

  Map<String, dynamic> getBundledDocument(String documentId) {
    return Map<String, dynamic>.from(
      _bundledDocuments[documentId] ?? const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> getContentDocument(String documentId) async {
    final result = await getResolvedContentDocument(documentId);
    return result.data;
  }

  Future<MomChildContentResult> getResolvedContentDocument(
    String documentId,
  ) async {
    final bundled = getBundledDocument(documentId);

    try {
      final cloud = await _getDocument(documentId);

      if (cloud.isEmpty) {
        return MomChildContentResult(
          data: bundled,
          cloudStatus: MomChildCloudStatus.missing,
        );
      }

      if (!MomChildContentValidator.isCanonicalDocument(documentId, cloud)) {
        if (kDebugMode) {
          debugPrint(
            'MomChildCare/$documentId ignored: incomplete cloud schema.',
          );
        }
        return MomChildContentResult(
          data: bundled,
          cloudStatus: MomChildCloudStatus.invalid,
        );
      }

      return MomChildContentResult(
        data: cloud,
        cloudStatus: MomChildCloudStatus.current,
      );
    } catch (_) {
      return MomChildContentResult(
        data: bundled,
        cloudStatus: MomChildCloudStatus.unavailable,
      );
    }
  }

  Future<Map<String, dynamic>> _getDocument(String docName) async {
    final ref = _firestore.collection('mom_child_care').doc(docName);

    try {
      final snap = await ref
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 8));

      if (kDebugMode) {
        debugPrint(
          'MomChildCare/$docName -> exists=${snap.exists}, '
          'fromCache=${snap.metadata.isFromCache}',
        );
      }

      if (!snap.exists) return <String, dynamic>{};
      return Map<String, dynamic>.from(snap.data() ?? const {});
    } on TimeoutException {
      if (kDebugMode) {
        debugPrint('MomChildCare/$docName server read timed out; trying cache');
      }

      try {
        final cached = await ref
            .get(const GetOptions(source: Source.cache))
            .timeout(const Duration(seconds: 2));

        if (!cached.exists) return <String, dynamic>{};
        return Map<String, dynamic>.from(cached.data() ?? const {});
      } catch (e) {
        if (kDebugMode) {
          debugPrint('MomChildCare/$docName cache read failed: $e');
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MomChildCare/$docName read failed: $e');
      }
      rethrow;
    }
  }

  // ১. সমস্যা সমাধান — full nested document
  Future<Map<String, dynamic>> getProblemsContent() =>
      getContentDocument('problems');

  // ২. প্যারেন্টিং গাইড — full nested document
  Future<Map<String, dynamic>> getParentingGuideContent() =>
      getContentDocument('parenting_guide');

  // Backward-compatible flat APIs, in case another old widget still uses them.
  Future<List<Map<String, dynamic>>> getProblems() async {
    final data = await getProblemsContent();
    return _toMapList(data['list']);
  }

  Future<List<Map<String, dynamic>>> getMistakes() async {
    final data = await getParentingGuideContent();
    return _toMapList(data['list']);
  }

  // Smart tools
  Future<List<Map<String, dynamic>>> getMilestones() async {
    final data = await getContentDocument('smart_tools');
    return _toMapList(data['milestones']);
  }

  Future<List<Map<String, dynamic>>> getVaccinationSchedule() async {
    final data = await getContentDocument('smart_tools');
    return _toMapList(data['vaccinationSchedule']);
  }

  Future<List<Map<String, dynamic>>> getFeatures() async {
    final data = await getContentDocument('smart_tools');
    return _toMapList(data['sections']);
  }

  Future<List<String>> getDailyTips() async {
    final data = await getContentDocument('smart_tools');
    final raw = data['dailyTips'];
    final list = raw is List ? raw : const [];
    return list.map((e) => e.toString()).toList();
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
