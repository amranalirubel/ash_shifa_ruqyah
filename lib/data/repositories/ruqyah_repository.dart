// lib/data/repositories/ruqyah_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dua_model.dart';
import '../models/problem_model.dart';

class RuqyahRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== Duas ==================
  Future<List<DuaModel>> getDuaList() async {
    final snap = await _firestore.collection('ruqyah').doc('duas').get();
    final data = snap.data()?['list'] as List<dynamic>? ?? [];
    return data
        .map(
          (e) => DuaModel(
            title: e['title'] ?? '',
            arabic: e['arabic'] ?? '',
            translation: e['translation'] ?? '',
          ),
        )
        .toList();
  }

  // ================== Problems ==================
  Future<List<ProblemModel>> getProblems() async =>
      await _getProblemList('problems');

  // ================== Basics of Ruqyah ==================
  Future<List<ProblemModel>> getBasicsOfRuqyah() async =>
      await _getProblemList('basics_of_ruqyah');

  // ================== Diagnosis ==================
  Future<List<ProblemModel>> getDiagnosisList() async =>
      await _getProblemList('diagnosis');

  // ================== Daily Adhkar ==================
  Future<List<ProblemModel>> getDailyAdhkarList() async =>
      await _getProblemList('daily_adhkar');

  // ================== Step by Step ==================
  Future<List<ProblemModel>> getStepByStepList() async =>
      await _getProblemList('step_by_step');

  // ================== FAQ ==================
  Future<List<ProblemModel>> getFaqList() async =>
      await _getProblemList('faqs');

  Future<List<ProblemModel>> _getProblemList(String docName) async {
    final snap = await _firestore.collection('ruqyah').doc(docName).get();
    final data = snap.data()?['list'] as List<dynamic>? ?? [];
    return data
        .map(
          (e) => ProblemModel(
            title: e['title'] ?? '',
            items: (e['items'] as List<dynamic>? ?? [])
                .map(
                  (i) => SubItem(
                    title: i['title'] ?? '',
                    description: i['description'] ?? '',
                  ),
                )
                .toList(),
          ),
        )
        .toList();
  }

  // ================== Free & Paid Audios ==================
  Future<List<Map<String, dynamic>>> getFreeAudioList() async {
    final snap = await _firestore.collection('ruqyah').doc('free_audios').get();
    return List<Map<String, dynamic>>.from(snap.data()?['list'] ?? []);
  }

  Future<List<Map<String, dynamic>>> getPaidAudioList() async {
    final snap = await _firestore.collection('ruqyah').doc('paid_audios').get();
    return List<Map<String, dynamic>>.from(snap.data()?['list'] ?? []);
  }
}
