import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/bazzer_item_model.dart';
import '../utils/bazzer_receipt.dart';
import '../utils/store_category.dart';

class BazzerFamily {
  const BazzerFamily({
    required this.id,
    required this.ownerUid,
    required this.inviteCode,
    required this.joiningEnabled,
    required this.name,
  });

  final String id;
  final String ownerUid;
  final String inviteCode;
  final bool joiningEnabled;
  final String name;

  factory BazzerFamily.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BazzerFamily(
      id: doc.id,
      ownerUid: data['ownerUid'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
      joiningEnabled: data['joiningEnabled'] == true,
      name: data['name'] as String? ?? 'পরিবারের বাজার',
    );
  }
}

class BazzerMember {
  const BazzerMember({
    required this.uid,
    required this.name,
    required this.active,
    this.isOwner = false,
    this.role = 'member',
    this.secure = false,
  });

  final String uid;
  final String name;
  final bool active;
  final bool isOwner;
  final String role;
  final bool secure;
  bool get isAdmin => isOwner || role == 'admin';

  factory BazzerMember.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return BazzerMember(
      uid: doc.id,
      name: data['name'] as String? ?? 'সদস্য',
      active: data['active'] == true,
      role: data['role'] as String? ?? 'member',
      secure: data['secure'] == true,
    );
  }
}

class BazzerRepository {
  BazzerRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _codeLength = 12;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  User? get signedInUser => _auth.currentUser;
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User get currentUser {
    final user = _auth.currentUser;
    if (user == null) throw StateError('পরিবারে বাজারের জন্য আগে লগইন করুন।');
    return user;
  }

  static String generateInviteCode({Random? random}) {
    final source = random ?? Random.secure();
    return List.generate(
      _codeLength,
      (_) => _alphabet[source.nextInt(_alphabet.length)],
    ).join();
  }

  String get _displayName {
    final user = currentUser;
    final name = user.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user.email?.split('@').first ?? 'পরিবারের সদস্য';
  }

  DocumentReference<Map<String, dynamic>> _family(String familyId) =>
      _db.collection('shopping_families').doc(familyId);

  DocumentReference<Map<String, dynamic>> _link(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('bazzer_reminder')
      .doc('family');

  Stream<String?> watchFamilyId(String uid) => _link(uid)
      .snapshots(includeMetadataChanges: true)
      .map((snapshot) => snapshot.data()?['familyId'] as String?);

  Stream<BazzerFamily?> watchFamily(String familyId) => _family(familyId)
      .snapshots(includeMetadataChanges: true)
      .map(
        (snapshot) =>
            snapshot.exists ? BazzerFamily.fromDocument(snapshot) : null,
      );

  Stream<BazzerMember?> watchOwnMember(String familyId, String uid) =>
      _family(familyId)
          .collection('members')
          .doc(uid)
          .snapshots(includeMetadataChanges: true)
          .map(
            (snapshot) =>
                snapshot.exists ? BazzerMember.fromDocument(snapshot) : null,
          );

  Stream<List<BazzerMember>> watchMembers(String familyId) => _family(familyId)
      .collection('members')
      .snapshots()
      .map((snapshot) => snapshot.docs.map(BazzerMember.fromDocument).toList());

  Stream<List<BazzerItem>> watchItems(String familyId, {bool? isBought}) {
    final collection = _family(familyId).collection('items');
    final Query<Map<String, dynamic>> query = isBought == null
        ? collection
        : collection.where('isBought', isEqualTo: isBought);
    return query.snapshots(includeMetadataChanges: true).map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => BazzerItem.fromMap(
              doc.data(),
              doc.id,
              hasPendingWrites: doc.metadata.hasPendingWrites,
            ),
          )
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<BazzerItem>> watchSecureItems(
    String familyId, {
    bool? isBought,
    String? authorUid,
  }) {
    final collection = _family(familyId).collection('secure_items');
    final Query<Map<String, dynamic>> query = authorUid == null
        ? (isBought == null
              ? collection
              : collection.where('isBought', isEqualTo: isBought))
        : collection.where('createdBy', isEqualTo: authorUid);
    return query.snapshots(includeMetadataChanges: true).map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => BazzerItem.fromMap(
              doc.data(),
              doc.id,
              hasPendingWrites: doc.metadata.hasPendingWrites,
              isSecure: true,
            ),
          )
          .where((item) => isBought == null || item.isBought == isBought)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Invite creation and joining are online-only; ordinary item writes are
  /// queued by Firestore on Android/iOS while offline.
  Future<BazzerFamily> createFamily() async {
    final user = currentUser;
    final currentLink = await _link(
      user.uid,
    ).get(const GetOptions(source: Source.server));
    if (currentLink.data()?['familyId'] is String) {
      throw StateError('আপনি ইতিমধ্যে একটি পরিবারের বাজারে যুক্ত আছেন।');
    }
    final familyRef = _db.collection('shopping_families').doc();
    final code = generateInviteCode();
    final inviteRef = _db.collection('shopping_invites').doc(code);
    final existing = await inviteRef.get(
      const GetOptions(source: Source.server),
    );
    if (existing.exists) {
      throw StateError('কোডটি ব্যবহার হচ্ছে; আবার চেষ্টা করুন।');
    }

    final batch = _db.batch();
    batch.set(familyRef, {
      'ownerUid': user.uid,
      'name': 'পরিবারের বাজার',
      'inviteCode': code,
      'joiningEnabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(inviteRef, {
      'familyId': familyRef.id,
      'ownerUid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(_link(user.uid), {
      'familyId': familyRef.id,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return BazzerFamily(
      id: familyRef.id,
      ownerUid: user.uid,
      inviteCode: code,
      joiningEnabled: true,
      name: 'পরিবারের বাজার',
    );
  }

  Future<void> joinFamily(String rawCode) async {
    final user = currentUser;
    final currentLink = await _link(
      user.uid,
    ).get(const GetOptions(source: Source.server));
    if (currentLink.data()?['familyId'] is String) {
      throw StateError('আপনি ইতিমধ্যে একটি পরিবারের বাজারে যুক্ত আছেন।');
    }
    final code = rawCode.toUpperCase().replaceAll(RegExp(r'[^A-Z2-9]'), '');
    if (code.length != _codeLength) {
      throw FormatException('১২ অক্ষরের সঠিক পরিবারের কোড লিখুন।');
    }
    final invite = await _db
        .collection('shopping_invites')
        .doc(code)
        .get(const GetOptions(source: Source.server));
    final familyId = invite.data()?['familyId'] as String?;
    if (familyId == null || familyId.isEmpty) {
      throw StateError('এই কোডে কোনো পরিবার পাওয়া যায়নি।');
    }
    // Family documents stay private until membership has been created.
    // The server rules verify both the invite code and joiningEnabled.
    if (invite.data()?['ownerUid'] == user.uid) {
      throw StateError('এটি আপনার নিজের পরিবারের কোড।');
    }
    final familyRef = _family(familyId);
    final memberRef = familyRef.collection('members').doc(user.uid);
    final previous = await memberRef.get(
      const GetOptions(source: Source.server),
    );
    if (previous.exists) {
      throw StateError(
        'আগে যুক্ত ছিলেন; বাদ গেলে মূল অ্যাকাউন্ট থেকে ফিরিয়ে নিতে হবে।',
      );
    }
    final batch = _db.batch();
    batch.set(memberRef, {
      'uid': user.uid,
      'name': _displayName,
      'inviteCode': code,
      'active': true,
      'role': 'member',
      'secure': false,
      'joinedAt': FieldValue.serverTimestamp(),
      'removedAt': null,
    });
    batch.set(_link(user.uid), {
      'familyId': familyId,
      'joinedAt': FieldValue.serverTimestamp(),
    });
    try {
      await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') {
        throw StateError(
          'এই পরিবারের কোড বন্ধ অথবা সদস্য যোগ করার অনুমতি নেই।',
        );
      }
      rethrow;
    }
  }

  Future<void> setJoiningEnabled(String familyId, bool enabled) async {
    await _family(familyId).get(const GetOptions(source: Source.server));
    await _family(familyId).update({
      'joiningEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setMemberActive(String familyId, String uid, bool active) async {
    final member = _family(familyId).collection('members').doc(uid);
    await member.get(const GetOptions(source: Source.server));
    await member.update({
      'active': active,
      'removedAt': active ? null : FieldValue.serverTimestamp(),
    });
  }

  Future<void> renameMember(String familyId, String uid, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 80) {
      throw FormatException('সদস্যের নাম ১–৮০ অক্ষরের মধ্যে লিখুন।');
    }
    await _family(
      familyId,
    ).collection('members').doc(uid).update({'name': trimmed});
  }

  Future<void> setMemberAdmin(String familyId, String uid, bool admin) async {
    await _family(familyId).collection('members').doc(uid).update({
      'role': admin ? 'admin' : 'member',
    });
  }

  Future<void> setMemberSecure(String familyId, String uid, bool secure) async {
    await _family(
      familyId,
    ).collection('members').doc(uid).update({'secure': secure});
  }

  DocumentReference<Map<String, dynamic>> _item(
    String familyId,
    BazzerItem item,
  ) => _family(
    familyId,
  ).collection(item.isSecure ? 'secure_items' : 'items').doc(item.id);

  Future<void> addItems(
    String familyId,
    List<BazzerItem> items, {
    String? addedBy,
  }) async {
    if (items.isEmpty) return;
    final user = currentUser;
    final requestedName = addedBy?.trim();
    final displayName = requestedName != null && requestedName.isNotEmpty
        ? requestedName
        : _displayName;
    final safeDisplayName = displayName.length > 80
        ? displayName.substring(0, 80)
        : displayName;
    final batch = _db.batch();
    for (final item in items) {
      if (item.name.trim().isEmpty ||
          item.name.length > 120 ||
          !item.quantity.isFinite ||
          item.quantity <= 0 ||
          item.quantity > 1000 ||
          !StoreCategory.all.contains(item.category) ||
          (item.pricePaisa != null &&
              (item.pricePaisa! < 0 ||
                  item.pricePaisa! > bazzerMaxPricePaisa))) {
        throw FormatException('আইটেমের নাম, পরিমাণ বা দোকান ঠিক নেই।');
      }
      batch.set(_item(familyId, item), {
        'name': item.name.trim(),
        'quantity': item.quantity,
        'unit': item.unit,
        'category': item.category,
        'isBought': false,
        'createdAt': FieldValue.serverTimestamp(),
        'clientCreatedAt': Timestamp.fromDate(item.createdAt),
        'noteDate': item.dayKey,
        'pricePaisa': item.pricePaisa,
        'addedBy': safeDisplayName,
        'createdBy': user.uid,
        'boughtBy': null,
        'boughtAt': null,
      });
    }
    await batch.commit();
  }

  Future<void> setBought(String familyId, BazzerItem item, bool bought) async {
    final user = currentUser;
    await _item(familyId, item).update({
      'isBought': bought,
      'boughtBy': bought ? user.uid : null,
      'boughtAt': bought ? FieldValue.serverTimestamp() : null,
    });
  }

  Future<void> setPrice(String familyId, BazzerItem item, int? paisa) async {
    if (paisa != null && (paisa < 0 || paisa > bazzerMaxPricePaisa)) {
      throw const FormatException('সঠিক দাম লিখুন।');
    }
    await _item(familyId, item).update({'pricePaisa': paisa});
  }

  Future<void> editItem(
    String familyId,
    BazzerItem item, {
    required String name,
    required double quantity,
    required String unit,
    required String category,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty ||
        trimmed.length > 120 ||
        !quantity.isFinite ||
        quantity <= 0 ||
        quantity > 1000 ||
        !StoreCategory.all.contains(category) ||
        ![
          'টা',
          'কেজি',
          'গ্রাম',
          'লিটার',
          'মিলি',
          'আঁটি',
          'প্যাকেট',
          'বোতল',
          'হালি',
          'ডজন',
        ].contains(unit) ||
        (unit == 'টা' && quantity % 1 != 0)) {
      throw FormatException('জিনিসের নাম, পরিমাণ বা দোকান ঠিক নেই।');
    }
    await _item(familyId, item).update({
      'name': trimmed,
      'quantity': quantity,
      'unit': unit,
      'category': category,
    });
  }

  Future<void> deleteItem(String familyId, BazzerItem item) =>
      _item(familyId, item).delete();
}
