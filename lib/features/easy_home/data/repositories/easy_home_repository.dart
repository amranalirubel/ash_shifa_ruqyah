import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/flat_model.dart';
import '../../models/tenant_model.dart';
import '../../models/rent_model.dart';
import '../../models/complaint_model.dart';
import '../../models/notification_model.dart';
import '../../models/user_model.dart';

class EasyHomeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ================== Flats ==================
  Future<List<FlatModel>> getFlats() async {
    final snap = await _firestore.collection('easy_home').doc('flats').get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => FlatModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== Tenants ==================
  Future<List<TenantModel>> getTenants() async {
    final snap = await _firestore.collection('easy_home').doc('tenants').get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => TenantModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== Rents ==================
  Future<List<RentModel>> getRents() async {
    final snap = await _firestore.collection('easy_home').doc('rents').get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => RentModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== Complaints ==================
  Future<List<ComplaintModel>> getComplaints() async {
    final snap = await _firestore
        .collection('easy_home')
        .doc('complaints')
        .get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => ComplaintModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== Notifications ==================
  Future<List<NotificationModel>> getNotifications() async {
    final snap = await _firestore
        .collection('easy_home')
        .doc('notifications')
        .get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => NotificationModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== Users (for role-based) ==================
  Future<List<UserModel>> getUsers() async {
    final snap = await _firestore.collection('easy_home').doc('users').get();
    final list = snap.data()?['list'] as List<dynamic>? ?? [];
    return list
        .map((e) => UserModel.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  // ================== CRUD Helpers (Future use) ==================
  Future<void> addTenant(TenantModel tenant) async {
    await _firestore.collection('easy_home').doc('tenants').update({
      'list': FieldValue.arrayUnion([tenant.toMap()]),
    });
  }

  Future<void> addRent(RentModel rent) async {
    await _firestore.collection('easy_home').doc('rents').update({
      'list': FieldValue.arrayUnion([rent.toMap()]),
    });
  }

  Future<void> updateComplaintStatus(String id, ComplaintStatus status) async {
    // You can expand this later with subcollections for better scalability
  }
}
