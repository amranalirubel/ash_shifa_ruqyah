import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../utils/seed_mom_child_care.dart';

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

  Future<Map<String, dynamic>> getContentDocument(String documentId) {
    return _getDocument(documentId);
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
  Future<Map<String, dynamic>> getProblemsContent() => _getDocument('problems');

  // ২. প্যারেন্টিং গাইড — full nested document
  Future<Map<String, dynamic>> getParentingGuideContent() async {
    final guide = await _getDocument('parenting_guide');
    if (guide.isNotEmpty) return guide;

    // পুরোনো project-এ "mistakes" doc থাকলে temporary backward compatibility.
    final legacy = await _getDocument('mistakes');
    if (legacy.isEmpty) return const {};

    final list = (legacy['list'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    return {
      'title': 'প্যারেন্টিং গাইড',
      'intro': '',
      'sections': [
        {'title': 'প্যারেন্টিং বিষয়সমূহ', 'description': '', 'topics': list},
      ],
      'footerSections': const [],
      'list': list,
    };
  }

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
    final data = await _getDocument('smart_tools');
    return _toMapList(data['milestones']);
  }

  Future<List<Map<String, dynamic>>> getVaccinationSchedule() async {
    final data = await _getDocument('smart_tools');
    return _toMapList(data['vaccinationSchedule']);
  }

  Future<List<Map<String, dynamic>>> getFeatures() async {
    final data = await _getDocument('smart_tools');
    return _toMapList(data['sections']);
  }

  Future<List<String>> getDailyTips() async {
    final data = await _getDocument('smart_tools');
    final list = data['dailyTips'] as List<dynamic>? ?? const [];
    return list.map((e) => e.toString()).toList();
  }

  List<Map<String, dynamic>> _toMapList(dynamic value) {
    final list = value as List<dynamic>? ?? const [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
