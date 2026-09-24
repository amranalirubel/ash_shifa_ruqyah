import 'dart:async';

import 'package:ash_shifa_ruqyah/features/bazzer_reminder/models/bazzer_item_model.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/repositories/bazzer_repository.dart';
import 'package:ash_shifa_ruqyah/features/bazzer_reminder/services/voice_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeVoiceRecognizer implements VoiceRecognizer {
  List<String> availableLocales = [];
  final requestedLocales = <String>[];
  bool failLocales = false;
  bool ready = true;
  bool reportListening = true;
  int initializeCount = 0;
  int cancelCount = 0;
  @override
  bool isListening = false;
  late void Function(String) status;
  late void Function(String) error;
  late void Function(String, bool) result;

  @override
  Future<bool> initialize({
    required void Function(String) onStatus,
    required void Function(String) onError,
  }) async {
    initializeCount++;
    status = onStatus;
    error = onError;
    return ready;
  }

  @override
  Future<List<String>> locales() async {
    if (failLocales) throw StateError('device locale enumeration failed');
    return availableLocales;
  }

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String, bool) onResult,
  }) async {
    requestedLocales.add(localeId);
    result = onResult;
    isListening = reportListening;
    if (reportListening) status('listening');
  }

  @override
  Future<void> stop() async {
    isListening = false;
    status('notListening');
  }

  @override
  Future<void> cancel() async {
    cancelCount++;
    isListening = false;
  }
}

class FakeBazzerUser extends Fake implements User {
  FakeBazzerUser(this.uid);
  @override
  final String uid;
  @override
  String get displayName => 'রুবেল';
}

class FakeBazzerRepository extends Fake implements BazzerRepository {
  FakeBazzerRepository({this.owner = false});
  final bool owner;
  final streamCalls = <String, int>{};
  final savedItems = <BazzerItem>[];
  final managementWrites = <(String, String, Object)>[];
  final _familyChanges = StreamController<BazzerFamily?>.broadcast();
  final _memberChanges = StreamController<BazzerMember?>.broadcast();
  final _directoryChanges = StreamController<List<BazzerMember>>.broadcast();
  String? savedAuthor;
  var family = const BazzerFamily(
    id: 'family',
    ownerUid: 'owner',
    inviteCode: 'ABCDEFGHJKLM',
    joiningEnabled: true,
    name: 'আমাদের পরিবার',
  );
  var member = const BazzerMember(
    uid: 'member',
    name: 'মায়ের নাম',
    active: true,
  );

  Stream<T> _stream<T>(String name, T value, [Stream<T>? changes]) {
    streamCalls.update(name, (count) => count + 1, ifAbsent: () => 1);
    return changes == null ? Stream.value(value) : _live(value, changes);
  }

  Stream<T> _live<T>(T initial, Stream<T> changes) async* {
    yield initial;
    yield* changes;
  }

  void updateFamily(BazzerFamily updated) {
    family = updated;
    _familyChanges.add(updated);
  }

  void updateMember(BazzerMember updated) {
    member = updated;
    _memberChanges.add(updated);
    _directoryChanges.add([updated]);
  }

  Future<void> dispose() async {
    await Future.wait([
      _familyChanges.close(),
      _memberChanges.close(),
      _directoryChanges.close(),
    ]);
  }

  @override
  User get signedInUser => FakeBazzerUser(owner ? 'owner' : 'member');

  @override
  Stream<User?> authStateChanges() => _stream('auth', signedInUser);

  @override
  Stream<String?> watchFamilyId(String uid) => _stream('link', 'family');

  @override
  Stream<BazzerFamily?> watchFamily(String familyId) =>
      _stream('family', family, _familyChanges.stream);

  @override
  Stream<BazzerMember?> watchOwnMember(String familyId, String uid) =>
      _stream('own', member, _memberChanges.stream);

  @override
  Stream<List<BazzerMember>> watchMembers(String familyId) =>
      _stream('members', [member], _directoryChanges.stream);

  @override
  Future<void> setJoiningEnabled(String familyId, bool enabled) async {
    managementWrites.add(('joining', familyId, enabled));
    updateFamily(
      BazzerFamily(
        id: family.id,
        ownerUid: family.ownerUid,
        inviteCode: family.inviteCode,
        joiningEnabled: enabled,
        name: family.name,
      ),
    );
  }

  @override
  Future<void> renameMember(String familyId, String uid, String name) async {
    managementWrites.add(('name', uid, name));
    updateMember(
      BazzerMember(
        uid: member.uid,
        name: name,
        active: member.active,
        role: member.role,
        secure: member.secure,
      ),
    );
  }

  @override
  Future<void> setMemberAdmin(String familyId, String uid, bool admin) async {
    managementWrites.add(('admin', uid, admin));
    updateMember(
      BazzerMember(
        uid: member.uid,
        name: member.name,
        active: member.active,
        role: admin ? 'admin' : 'member',
        secure: member.secure,
      ),
    );
  }

  @override
  Future<void> setMemberSecure(String familyId, String uid, bool secure) async {
    managementWrites.add(('secure', uid, secure));
    updateMember(
      BazzerMember(
        uid: member.uid,
        name: member.name,
        active: member.active,
        role: member.role,
        secure: secure,
      ),
    );
  }

  @override
  Stream<List<BazzerItem>> watchItems(
    String familyId, {
    required bool isBought,
  }) => _stream('items/$isBought', []);

  @override
  Stream<List<BazzerItem>> watchSecureItems(
    String familyId, {
    required bool isBought,
    String? authorUid,
  }) => _stream('secure/$isBought/$authorUid', []);

  @override
  Future<void> addItems(
    String familyId,
    List<BazzerItem> items, {
    String? addedBy,
  }) async {
    savedItems.addAll(items);
    savedAuthor = addedBy;
  }
}
