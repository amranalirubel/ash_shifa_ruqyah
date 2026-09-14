import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<void> createProfile({required User user, required String name}) async {
    final trimmedName = name.trim();

    await user.updateDisplayName(trimmedName);
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': trimmedName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'photoUrl': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Repairs a missing or incomplete profile after a successful login without
  /// changing role/administrative fields that may have been set server-side.
  Future<void> syncCurrentProfile(User user) async {
    final displayName = user.displayName?.trim();
    final reference = _firestore.collection('users').doc(user.uid);
    final existing = await reference.get();
    final fallbackName = user.email?.split('@').first.trim();
    final safeFallbackName = fallbackName != null && fallbackName.isNotEmpty
        ? fallbackName
        : 'User';

    await reference.set({
      'uid': user.uid,
      if (displayName != null && displayName.isNotEmpty)
        'name': displayName
      else if (!existing.exists)
        'name': safeFallbackName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateName({required User user, required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.length < 2 || trimmedName.length > 120) {
      throw ArgumentError.value(
        name,
        'name',
        'Name must contain between 2 and 120 characters.',
      );
    }

    await user.updateDisplayName(trimmedName);
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'name': trimmedName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
