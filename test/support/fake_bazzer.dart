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
  int localeCount = 0;
  Completer<List<String>>? localeGate;
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
    localeCount++;
    if (localeGate != null) return localeGate!.future;
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
  final items = <BazzerItem>[];
  final priceWrites = <(String, int?)>[];
  Completer<void>? priceGate;
  bool failPrice = false;
  final _itemChanges = StreamController<List<BazzerItem>>.broadcast();
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

  Stream<T> _stream<T>(
    String name,
    T Function() current, [
    Stream<T>? changes,
  ]) {
    streamCalls.update(name, (count) => count + 1, ifAbsent: () => 1);
    // Firestore snapshot streams support new subscriptions after a route or
    // permission change and immediately deliver the current document again.
    return Stream<T>.multi((listener) {
      listener.add(current());
      if (changes == null) {
        listener.close();
        return;
      }
      final subscription = changes.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = subscription.cancel;
    }, isBroadcast: true);
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
      _itemChanges.close(),
    ]);
  }

  @override
  User get signedInUser => FakeBazzerUser(owner ? 'owner' : 'member');

  @override
  Stream<User?> authStateChanges() => _stream('auth', () => signedInUser);

  @override
  Stream<String?> watchFamilyId(String uid) => _stream('link', () => 'family');

  @override
  Stream<BazzerFamily?> watchFamily(String familyId) =>
      _stream('family', () => family, _familyChanges.stream);

  @override
  Stream<BazzerMember?> watchOwnMember(String familyId, String uid) =>
      _stream('own', () => member, _memberChanges.stream);

  @override
  Stream<List<BazzerMember>> watchMembers(String familyId) =>
      _stream('members', () => [member], _directoryChanges.stream);

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
  Stream<List<BazzerItem>> watchItems(String familyId, {bool? isBought}) {
    List<BazzerItem> select(List<BazzerItem> values) => values
        .where(
          (item) =>
              !item.isSecure && (isBought == null || item.isBought == isBought),
        )
        .toList();
    return _stream(
      'items/$isBought',
      () => select(items),
      _itemChanges.stream.map(select),
    );
  }

  @override
  Stream<List<BazzerItem>> watchSecureItems(
    String familyId, {
    bool? isBought,
    String? authorUid,
  }) {
    List<BazzerItem> select(List<BazzerItem> values) => values
        .where(
          (item) =>
              item.isSecure &&
              (isBought == null || item.isBought == isBought) &&
              (authorUid == null || item.createdBy == authorUid),
        )
        .toList();
    return _stream(
      'secure/$isBought/$authorUid',
      () => select(items),
      _itemChanges.stream.map(select),
    );
  }

  void updateItems(List<BazzerItem> updated) {
    items
      ..clear()
      ..addAll(updated);
    _itemChanges.add(List.of(items));
  }

  @override
  Future<void> setPrice(String familyId, BazzerItem item, int? paisa) async {
    priceWrites.add((item.id, paisa));
    if (priceGate != null) await priceGate!.future;
    if (failPrice) throw StateError('price write rejected');
    updateItems([
      for (final existing in items)
        if (existing.id == item.id && existing.isSecure == item.isSecure)
          existing.copyWith(pricePaisa: paisa, clearPrice: paisa == null)
        else
          existing,
    ]);
  }

  @override
  Future<void> setBought(String familyId, BazzerItem item, bool bought) async {
    updateItems([
      for (final existing in items)
        if (existing.id == item.id && existing.isSecure == item.isSecure)
          existing.copyWith(isBought: bought)
        else
          existing,
    ]);
  }

  @override
  Future<void> deleteItem(String familyId, BazzerItem item) async {
    updateItems(
      items
          .where(
            (existing) =>
                existing.id != item.id || existing.isSecure != item.isSecure,
          )
          .toList(),
    );
  }

  @override
  Future<void> addItems(
    String familyId,
    List<BazzerItem> items, {
    String? addedBy,
  }) async {
    savedItems.addAll(items);
    savedAuthor = addedBy;
    updateItems([
      ...this.items,
      ...items.map(
        (item) => item.copyWith(createdBy: signedInUser.uid, addedBy: addedBy),
      ),
    ]);
  }
}
