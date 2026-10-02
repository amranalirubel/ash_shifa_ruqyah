import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/easy_home_models.dart';
import '../../utils/easy_home_format.dart';

class EasyHomeRepository {
  EasyHomeRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  String? get userId => _auth.currentUser?.uid;
  String get displayName => _auth.currentUser?.displayName ?? '';
  Stream<String?> authChanges() => _auth.authStateChanges().map((u) => u?.uid);
  String get _uid => userId ?? (throw StateError('আগে লগইন করুন।'));
  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static String randomCode([int length = 12]) {
    final random = Random.secure();
    return List.generate(
      length,
      (_) => _alphabet[random.nextInt(_alphabet.length)],
    ).join();
  }

  DocumentReference<Map<String, dynamic>> _home(String id) =>
      _db.collection('easy_home_buildings').doc(id);
  DocumentReference<Map<String, dynamic>> _link(String uid) => _db
      .collection('users')
      .doc(uid)
      .collection('easy_home')
      .doc('connection');
  CollectionReference<Map<String, dynamic>> _collection(
    String id,
    String name,
  ) => _home(id).collection(name);
  Map<String, dynamic> _data(DocumentSnapshot<Map<String, dynamic>> doc) => {
    ...?doc.data(),
    'id': doc.id,
  };
  Stream<List<T>> _rows<T>(
    Query<Map<String, dynamic>> query,
    T Function(Map<String, dynamic>) parse,
  ) =>
      query.snapshots().map((s) => s.docs.map((d) => parse(_data(d))).toList());

  Stream<String?> watchConnection(String uid) =>
      _link(uid).snapshots().map((s) => s.data()?['homeId'] as String?);
  Stream<HomeModel?> watchHome(String id) => _home(
    id,
  ).snapshots().map((s) => s.exists ? HomeModel.fromMap(_data(s)) : null);
  Stream<bool> watchCached(String id) => _home(
    id,
  ).snapshots(includeMetadataChanges: true).map((s) => s.metadata.isFromCache);
  Stream<UserModel?> watchMember(String id, String uid) =>
      _collection(id, 'members')
          .doc(uid)
          .snapshots()
          .map((s) => s.exists ? UserModel.fromMap(_data(s)) : null);
  Stream<HomeRequest?> watchOwnRequest(String id, String uid) =>
      _collection(id, 'requests')
          .doc(uid)
          .snapshots()
          .map((s) => s.exists ? HomeRequest.fromMap(_data(s)) : null);
  Stream<List<UserModel>> watchMembers(String id) =>
      _rows(_collection(id, 'members'), UserModel.fromMap);
  Stream<List<HomeRequest>> watchRequests(String id) =>
      _rows(_collection(id, 'requests'), HomeRequest.fromMap);
  Stream<List<FlatModel>> watchFlats(String id) =>
      _rows(_collection(id, 'flats'), FlatModel.fromMap);
  Stream<List<TenantModel>> watchTenants(String id, UserModel member) => _rows(
    member.isLandlord
        ? _collection(id, 'tenants')
        : _collection(
            id,
            'tenants',
          ).where(FieldPath.documentId, isEqualTo: member.tenancyId),
    TenantModel.fromMap,
  );
  Stream<List<RentModel>> watchRents(String id, UserModel member) => _rows(
    member.isLandlord
        ? _collection(id, 'rents')
        : _collection(
            id,
            'rents',
          ).where('tenantId', isEqualTo: member.tenancyId),
    RentModel.fromMap,
  );
  Stream<List<ComplaintModel>> watchComplaints(String id, UserModel member) =>
      _rows(
        member.canManage
            ? _collection(id, 'complaints')
            : _collection(
                id,
                'complaints',
              ).where('authorUid', isEqualTo: member.id),
        ComplaintModel.fromMap,
      );
  Stream<List<NotificationModel>> watchNotices(String id, UserModel member) =>
      _rows(
        member.canManage
            ? _collection(id, 'notices')
            : _collection(id, 'notices').where(
                'audience',
                whereIn: [
                  'all',
                  'floor:${member.floor}',
                  'flat:${member.flatId}',
                  'tenant:${member.tenancyId}',
                ],
              ),
        NotificationModel.fromMap,
      );
  Stream<List<RentPayment>> watchPayments(String id, String rentId) => _rows(
    _collection(id, 'rents').doc(rentId).collection('payments'),
    RentPayment.fromMap,
  );

  Future<void> createHome(String name, String ownerName, String phone) async {
    _name(name);
    _name(ownerName);
    _phone(phone);
    final uid = _uid;
    final ref = _db.collection('easy_home_buildings').doc();
    final code = randomCode();
    final invite = _db.collection('easy_home_codes').doc(code);
    await _db.runTransaction((tx) async {
      if ((await tx.get(_link(uid))).data()?['homeId'] != null) return;
      if ((await tx.get(invite)).exists) throw StateError('আবার চেষ্টা করুন।');
      tx.set(ref, {
        'name': name.trim(),
        'ownerUid': uid,
        'inviteCode': code,
        'joiningEnabled': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        ref.collection('members').doc(uid),
        _memberData(ownerName, phone, UserRole.landlord),
      );
      tx.set(invite, {
        'homeId': ref.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.set(_link(uid), {'homeId': ref.id});
    });
  }

  Map<String, dynamic> _memberData(
    String name,
    String phone,
    UserRole role, {
    TenantModel? tenant,
  }) => {
    'name': name.trim(),
    'phone': latinDigits(phone),
    'role': role.name,
    'active': true,
    'tenancyId': tenant?.id ?? '',
    'flatId': tenant?.flatId ?? '',
    'floor': tenant?.floor ?? '',
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<void> requestJoin(
    String code,
    String name,
    String phone,
    UserRole role,
  ) async {
    _name(name);
    _phone(phone);
    if (role == UserRole.landlord) {
      throw StateError('বাড়িওয়ালা হিসেবে যোগ দেওয়া যায় না।');
    }
    code = code.trim().toUpperCase().replaceAll(' ', '');
    if (!RegExp(r'^[A-Z2-9]{12}$').hasMatch(code)) {
      throw ArgumentError('সঠিক ১২ অক্ষরের বাড়ির কোড দিন।');
    }
    final uid = _uid;
    await _db.runTransaction((tx) async {
      final invite = await tx.get(_db.collection('easy_home_codes').doc(code));
      if (!invite.exists) throw StateError('বাড়ির কোড পাওয়া যায়নি।');
      final id = invite.data()!['homeId'] as String;
      final member = await tx.get(_collection(id, 'members').doc(uid));
      if (member.data()?['active'] != true) {
        tx.set(_collection(id, 'requests').doc(uid), {
          'name': name.trim(),
          'phone': latinDigits(phone),
          'role': role.name,
          'code': code,
          'status': 'pending',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.set(_link(uid), {'homeId': id});
    });
  }

  Future<void> disconnect() async {
    await _link(_uid).delete();
  }

  Future<void> leaveHome(String id, UserModel member) async {
    await removeMember(id, member);
    await disconnect();
  }

  Future<void> updateHome(String id, String name, bool joiningEnabled) async {
    _name(name);
    await _db.runTransaction((tx) async {
      tx.update(_home(id), {
        'name': name.trim(),
        'joiningEnabled': joiningEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> approveRequest(
    String id,
    HomeRequest request, {
    TenantModel? tenant,
  }) async {
    if (request.role == UserRole.tenant && tenant == null) {
      throw StateError(
        'আগে ভাড়াটিয়ার ফ্ল্যাট ও ভাড়া যোগ করে তাকে নির্বাচন করুন।',
      );
    }
    await _db.runTransaction((tx) async {
      final requestRef = _collection(id, 'requests').doc(request.id);
      final currentRequest = await tx.get(requestRef);
      if (currentRequest.data()?['status'] != 'pending' ||
          currentRequest.data()?['role'] != request.role.name) {
        throw StateError('আবেদনটি বদলে গেছে। আবার খুলুন।');
      }
      TenantModel? latest;
      if (tenant != null) {
        final snapshot = await tx.get(
          _collection(id, 'tenants').doc(tenant.id),
        );
        latest = TenantModel.fromMap(_data(snapshot));
        if (!latest.active ||
            (latest.userId.isNotEmpty && latest.userId != request.id)) {
          throw StateError('এই ভাড়াটিয়ার সাথে অন্য অ্যাকাউন্ট যুক্ত আছে।');
        }
      }
      tx.set(
        _collection(id, 'members').doc(request.id),
        _memberData(
          currentRequest.data()!['name'] as String,
          currentRequest.data()!['phone'] as String,
          request.role,
          tenant: latest,
        ),
      );
      if (latest != null) {
        tx.update(_collection(id, 'tenants').doc(latest.id), {
          'userId': request.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      tx.update(requestRef, {
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> rejectRequest(String id, String uid) async {
    await _db.runTransaction((tx) async {
      tx.update(_collection(id, 'requests').doc(uid), {
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> removeMember(String id, UserModel member) async {
    if (member.role == UserRole.landlord) {
      throw StateError('বাড়িওয়ালাকে সরানো যাবে না।');
    }
    await _db.runTransaction((tx) async {
      final ref = _collection(id, 'members').doc(member.id);
      final snap = await tx.get(ref);
      final current = UserModel.fromMap(_data(snap));
      DocumentSnapshot<Map<String, dynamic>>? tenancy;
      if (current.tenancyId.isNotEmpty) {
        tenancy = await tx.get(
          _collection(id, 'tenants').doc(current.tenancyId),
        );
      }
      tx.update(ref, {
        'active': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (tenancy?.data()?['userId'] == member.id) {
        tx.update(tenancy!.reference, {
          'userId': '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> addFlat(String id, String floor, String unit) async {
    floor = latinDigits(floor).toUpperCase();
    unit = latinDigits(unit).toUpperCase();
    if (!RegExp(r'^(G|B[1-9]|[0-9]{1,2})$').hasMatch(floor) ||
        !RegExp(r'^[A-Z]{1,2}$').hasMatch(unit)) {
      throw ArgumentError(
        'তলা: ০–৯৯, G বা B1–B9; ইউনিট: A–Z (সর্বোচ্চ ২ অক্ষর)।',
      );
    }
    if (int.tryParse(floor) != null) floor = int.parse(floor).toString();
    final ref = _collection(id, 'flats').doc('${floor}_$unit');
    final code = '$floor$unit-${randomCode(4)}';
    await _db.runTransaction((tx) async {
      final old = await tx.get(ref);
      if (old.exists) {
        if (old.data()?['archived'] == true) {
          tx.update(ref, {'archived': false});
          return;
        }
        throw StateError('এই তলা ও ইউনিটের ফ্ল্যাট আগে থেকেই আছে।');
      }
      tx.set(ref, {
        'floor': floor,
        'unit': unit,
        'code': code,
        'tenancyId': '',
        'archived': false,
      });
    });
  }

  Future<void> archiveFlat(String id, FlatModel flat) async {
    await _db.runTransaction((tx) async {
      final ref = _collection(id, 'flats').doc(flat.id);
      if ((await tx.get(ref)).data()?['tenancyId'] != '') {
        throw StateError('আগে ভাড়াটিয়ার বসবাস শেষ করুন।');
      }
      tx.update(ref, {'archived': true});
    });
  }

  Future<void> saveTenant(
    String id, {
    String? tenantId,
    required FlatModel flat,
    required String name,
    required String phone,
    required int rentPaisa,
    required DateTime startDate,
    required int dueDay,
  }) async {
    _name(name);
    _phone(phone);
    if (rentPaisa < 1 ||
        rentPaisa > 100000000 ||
        dueDay < 1 ||
        dueDay > 28 ||
        startDate.year < 2000 ||
        startDate.isAfter(DateTime.now())) {
      throw ArgumentError('ভাড়া, শুরুর তারিখ ও পরিশোধের দিন সঠিকভাবে দিন।');
    }
    final ref = tenantId == null
        ? _collection(id, 'tenants').doc()
        : _collection(id, 'tenants').doc(tenantId);
    if (tenantId != null) {
      final old = await ref.get(const GetOptions(source: Source.server));
      await generateRents(id, [
        TenantModel.fromMap(_data(old)),
      ], DateTime.now());
    }
    await _db.runTransaction((tx) async {
      final currentFlat = await tx.get(_collection(id, 'flats').doc(flat.id));
      final old = tenantId == null ? null : await tx.get(ref);
      if (currentFlat.data()?['archived'] != false ||
          (currentFlat.data()?['tenancyId'] != '' &&
              currentFlat.data()?['tenancyId'] != ref.id)) {
        throw StateError('ফ্ল্যাটটি খালি নেই। তালিকা আবার দেখুন।');
      }
      if (old != null &&
          (old.data()?['active'] != true || old.data()?['flatId'] != flat.id)) {
        throw StateError('এই ভাড়াটিয়ার তথ্য পরিবর্তন করা যাবে না।');
      }
      final details = {
        'name': name.trim(),
        'phone': latinDigits(phone),
        'rentPaisa': rentPaisa,
        'dueDay': dueDay,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (old == null) {
        tx.set(ref, {
          ...details,
          'flatId': flat.id,
          'flatCode': currentFlat.data()!['code'],
          'floor': currentFlat.data()!['floor'],
          'userId': '',
          'active': true,
          'startDate': Timestamp.fromDate(
            DateTime(startDate.year, startDate.month, startDate.day),
          ),
          'endDate': null,
        });
        tx.update(currentFlat.reference, {'tenancyId': ref.id});
      } else {
        tx.update(ref, details);
      }
    });
  }

  Future<void> endTenancy(String id, TenantModel tenant) async {
    await generateRents(id, [tenant], DateTime.now());
    await _db.runTransaction((tx) async {
      final ref = _collection(id, 'tenants').doc(tenant.id);
      final latest = await tx.get(ref);
      final current = TenantModel.fromMap(_data(latest));
      final flat = await tx.get(_collection(id, 'flats').doc(current.flatId));
      if (!current.active) throw StateError('বসবাস ইতিমধ্যে শেষ হয়েছে।');
      tx.update(ref, {
        'active': false,
        'endDate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (flat.data()?['tenancyId'] == tenant.id) {
        tx.update(flat.reference, {'tenancyId': ''});
      }
      if (current.userId.isNotEmpty) {
        tx.update(_collection(id, 'members').doc(current.userId), {
          'active': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Deterministic IDs and server transactions make retries/concurrent owners
  /// safe. Generate once on opening and after tenancy edits; never overwrite bills.
  Future<void> generateRents(
    String id,
    List<TenantModel> tenants,
    DateTime now,
  ) async {
    for (final tenant in tenants) {
      final saved = await _collection(id, 'rents')
          .where('tenantId', isEqualTo: tenant.id)
          .get(const GetOptions(source: Source.server));
      final existingIds = saved.docs.map((doc) => doc.id).toSet();
      for (final month in rentalMonths(tenant, now)) {
        if (existingIds.contains('${tenant.id}_$month')) continue;
        final ref = _collection(id, 'rents').doc('${tenant.id}_$month');
        await _db.runTransaction((tx) async {
          final existing = await tx.get(ref);
          if (existing.exists) return;
          final latest = await tx.get(
            _collection(id, 'tenants').doc(tenant.id),
          );
          final current = TenantModel.fromMap(_data(latest));
          if (!rentalMonths(current, now).contains(month)) return;
          final date = monthDate(month);
          var due = DateTime(date.year, date.month, current.dueDay);
          if (due.isBefore(current.startDate)) due = current.startDate;
          tx.set(ref, {
            'tenantId': current.id,
            'flatCode': current.flatCode,
            'month': month,
            'amountPaisa': current.rentPaisa,
            'paidPaisa': 0,
            'dueDate': Timestamp.fromDate(due),
            'lastPaymentId': '',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
      }
    }
  }

  String newPaymentId() => _db.collection('_ids').doc().id;
  Future<void> recordPayment(
    String id,
    RentModel rent, {
    required String paymentId,
    required int amountPaisa,
    required String method,
    required String note,
  }) async {
    if (!['cash', 'bank', 'mobile', 'correction'].contains(method) ||
        note.trim().length > 300 ||
        amountPaisa == 0 ||
        (amountPaisa < 0 && (method != 'correction' || note.trim().isEmpty)) ||
        (amountPaisa > 0 && method == 'correction')) {
      throw ArgumentError('সঠিক পরিমাণ ও সংশোধনের কারণ দিন।');
    }
    final ref = _collection(id, 'rents').doc(rent.id);
    final receipt = ref.collection('payments').doc(paymentId);
    // Some Firestore backends evaluate ledger rules before reporting a
    // transaction conflict. Retry only after a server read proves the balance
    // changed, with the same receipt ID so response loss cannot double-charge.
    for (var attempt = 0; ; attempt++) {
      int? observedPaid;
      try {
        await _db.runTransaction((tx) async {
          final previous = await tx.get(receipt);
          if (previous.exists) {
            final saved = previous.data()!;
            if (saved['amountPaisa'] != amountPaisa ||
                saved['method'] != method ||
                saved['note'] != note.trim()) {
              throw StateError(
                'আগের জমাটি সেভ হয়েছে। রসিদ দেখুন; নতুন জমার জন্য ফর্ম আবার খুলুন।',
              );
            }
            return;
          }
          final snapshot = await tx.get(ref);
          final latest = RentModel.fromMap(_data(snapshot));
          observedPaid = latest.paidPaisa;
          final paid = paymentBalance(
            amount: latest.amountPaisa,
            paid: latest.paidPaisa,
            change: amountPaisa,
          );
          tx.set(receipt, {
            'amountPaisa': amountPaisa,
            'balancePaisa': paid,
            'method': method,
            'note': note.trim(),
            'recordedBy': _uid,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.update(ref, {
            'paidPaisa': paid,
            'lastPaymentId': paymentId,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        });
        return;
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied' ||
            attempt >= 2 ||
            observedPaid == null) {
          rethrow;
        }
        final current = await ref.get(const GetOptions(source: Source.server));
        if (current.data()?['paidPaisa'] == observedPaid) rethrow;
      }
    }
  }

  Future<void> postNotice(
    String id, {
    required String content,
    required String audience,
    required bool emergency,
  }) async {
    if (content.trim().isEmpty || content.trim().length > 2000) {
      throw ArgumentError('১–২০০০ অক্ষরের নোটিশ লিখুন।');
    }
    await _db.runTransaction((tx) async {
      tx.set(_collection(id, 'notices').doc(), {
        'content': content.trim(),
        'audience': audience,
        'emergency': emergency,
        'senderId': _uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteNotice(String id, String noticeId) async {
    await _db.runTransaction((tx) async {
      tx.delete(_collection(id, 'notices').doc(noticeId));
    });
  }

  Future<void> saveComplaint(
    String id, {
    String? complaintId,
    required String title,
    required String description,
    required Priority priority,
    required String flatCode,
  }) async {
    if (title.trim().isEmpty ||
        title.trim().length > 100 ||
        description.trim().isEmpty ||
        description.trim().length > 2000) {
      throw ArgumentError('শিরোনাম ও সমস্যার বিবরণ লিখুন।');
    }
    final ref = complaintId == null
        ? _collection(id, 'complaints').doc()
        : _collection(id, 'complaints').doc(complaintId);
    await _db.runTransaction((tx) async {
      final content = {
        'title': title.trim(),
        'description': description.trim(),
        'priority': priority.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (complaintId == null) {
        tx.set(ref, {
          ...content,
          'authorUid': _uid,
          'flatCode': flatCode,
          'status': 'pending',
          'response': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        tx.update(ref, content);
      }
    });
  }

  Future<void> updateComplaint(
    String id,
    String complaintId,
    ComplaintStatus status,
    String response,
  ) async {
    if (response.trim().length > 1000) {
      throw ArgumentError('উত্তর ১০০০ অক্ষরের মধ্যে লিখুন।');
    }
    await _db.runTransaction((tx) async {
      tx.update(_collection(id, 'complaints').doc(complaintId), {
        'status': status.name,
        'response': response.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteComplaint(String id, String complaintId) async {
    await _db.runTransaction((tx) async {
      tx.delete(_collection(id, 'complaints').doc(complaintId));
    });
  }

  static void _name(String name) {
    if (name.trim().isEmpty || name.trim().length > 80) {
      throw ArgumentError('নাম ১–৮০ অক্ষরের মধ্যে লিখুন।');
    }
  }

  static void _phone(String phone) {
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(latinDigits(phone))) {
      throw ArgumentError('সঠিক মোবাইল নম্বর লিখুন।');
    }
  }
}
