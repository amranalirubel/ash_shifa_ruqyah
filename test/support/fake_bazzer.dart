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
  String? savedAuthor;
  final family = const BazzerFamily(
    id: 'family',
    ownerUid: 'owner',
    inviteCode: 'ABCDEFGHJKLM',
    joiningEnabled: true,
    name: 'আমাদের পরিবার',
  );
  final member = const BazzerMember(
    uid: 'member',
    name: 'মায়ের নাম',
    active: true,
  );

  Stream<T> _stream<T>(String name, T value) {
    streamCalls.update(name, (count) => count + 1, ifAbsent: () => 1);
    return Stream.value(value);
  }

  @override
  User get signedInUser => FakeBazzerUser(owner ? 'owner' : 'member');

  @override
  Stream<User?> authStateChanges() => _stream('auth', signedInUser);

  @override
  Stream<String?> watchFamilyId(String uid) => _stream('link', 'family');

  @override
  Stream<BazzerFamily?> watchFamily(String familyId) =>
      _stream('family', family);

  @override
  Stream<BazzerMember?> watchOwnMember(String familyId, String uid) =>
      _stream('own', member);

  @override
  Stream<List<BazzerMember>> watchMembers(String familyId) =>
      _stream('members', [member]);

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
