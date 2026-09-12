import 'package:cloud_firestore/cloud_firestore.dart';

class HealthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ১. রোগের নাম ও খাদ্যের তালিকা (Diseases + Food Map)
  Future<Map<String, Map<String, dynamic>>> getDiseaseFoodMap() async {
    final snap = await _firestore
        .collection('health_tips')
        .doc('diseases')
        .get();
    // সিড ফাইলে 'data' কি (key) ব্যবহার করা হয়েছে
    final data = snap.data()?['data'] as Map<String, dynamic>? ?? {};
    return data.map(
      (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
    );
  }

  // ২. প্রতিদিনের স্বাস্থ্য টিপস (Daily Health Tips)
  Future<List<String>> getDailyHealthTips() async {
    final snap = await _firestore
        .collection('health_tips')
        .doc('daily_tips')
        .get();
    // সিড ফাইলে consistency-র জন্য 'list' কি (key) ব্যবহার করা হয়েছে
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list.map((e) => e.toString()).toList();
  }

  // ৩. ব্যায়াম ও মেডিটেশনের তালিকা (Exercises)
  Future<List<Map<String, String>>> getExercises() async {
    final snap = await _firestore
        .collection('health_tips')
        .doc('exercises')
        .get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, String>.from(e)).toList();
  }

  // ৪. কুইক স্বাস্থ্য কার্ড (Quick Tips)
  Future<List<Map<String, dynamic>>> getQuickTips() async {
    final snap = await _firestore
        .collection('health_tips')
        .doc('quick_tips')
        .get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }
}
