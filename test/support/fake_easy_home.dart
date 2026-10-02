import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/data/repositories/easy_home_repository.dart';
import 'package:ash_shifa_ruqyah/features/easy_home/models/easy_home_models.dart';

class FakeEasyHomeRepository extends Fake implements EasyHomeRepository {
  FakeEasyHomeRepository({
    UserRole role = UserRole.landlord,
    this.connected = true,
  }) {
    member = UserModel(
      id: 'me',
      name: 'রুবেল',
      phone: '01700000000',
      role: role,
      tenancyId: role == UserRole.tenant ? 'lease' : '',
      flatId: role == UserRole.tenant ? '2_B' : '',
      floor: role == UserRole.tenant ? '2' : '',
    );
  }
  final bool connected;
  late UserModel member;
  final calls = <String, int>{};
  final changes = StreamController<UserModel?>.broadcast();
  final auth = StreamController<String?>.broadcast();
  final rentChanges = StreamController<List<RentModel>>.broadcast();
  Completer<void>? saveGate;
  bool failSave = false;
  String? savedFloor;
  int generationCount = 0;
  final List<TenantModel> tenants = [];
  final List<RentModel> rents = [];
  Stream<T> replay<T>(String key, T value, [Stream<T>? changes]) {
    calls.update(key, (v) => v + 1, ifAbsent: () => 1);
    return Stream<T>.multi((controller) {
      controller.add(value);
      final sub = changes?.listen(controller.add, onError: controller.addError);
      if (sub == null) {
        controller.close();
      } else {
        controller.onCancel = sub.cancel;
      }
    }, isBroadcast: true);
  }

  @override
  String? get userId => 'me';
  @override
  String get displayName => 'রুবেল';
  @override
  Stream<String?> authChanges() => replay('auth', 'me', auth.stream);
  @override
  Stream<String?> watchConnection(String uid) =>
      replay('connection', connected ? 'home' : null);
  @override
  Stream<UserModel?> watchMember(String id, String uid) =>
      replay('member', member, changes.stream);
  @override
  Stream<HomeRequest?> watchOwnRequest(String id, String uid) =>
      replay('request', null);
  @override
  Stream<HomeModel?> watchHome(String id) => replay(
    'home',
    const HomeModel(
      id: 'home',
      name: 'আমাদের বাড়ি',
      ownerUid: 'me',
      inviteCode: 'ABCDEFGHJKLM',
      joiningEnabled: true,
    ),
  );
  @override
  Stream<bool> watchCached(String id) => replay('cache', false);
  @override
  Stream<List<FlatModel>> watchFlats(String id) => replay('flats', [
    const FlatModel(id: '2_B', floor: '2', unit: 'B', code: '2B-K9X4'),
  ]);
  @override
  Stream<List<TenantModel>> watchTenants(String id, UserModel m) =>
      replay('tenants', tenants);
  @override
  Stream<List<RentModel>> watchRents(String id, UserModel m) =>
      replay('rents', rents, rentChanges.stream);
  @override
  Stream<List<ComplaintModel>> watchComplaints(String id, UserModel m) =>
      replay('complaints', []);
  @override
  Stream<List<NotificationModel>> watchNotices(String id, UserModel m) =>
      replay('notices', []);
  @override
  Stream<List<UserModel>> watchMembers(String id) =>
      replay('members', [member]);
  @override
  Stream<List<HomeRequest>> watchRequests(String id) => replay('requests', []);
  @override
  Future<void> generateRents(
    String id,
    List<TenantModel> tenants,
    DateTime now,
  ) async {
    generationCount++;
  }

  @override
  Future<void> addFlat(String id, String floor, String unit) async {
    if (saveGate != null) await saveGate!.future;
    if (failSave) throw StateError('সংযোগ নেই');
    savedFloor = floor;
  }

  Future<void> dispose() async {
    await changes.close();
    await auth.close();
    await rentChanges.close();
  }
}
