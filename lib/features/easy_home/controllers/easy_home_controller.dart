import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/repositories/easy_home_repository.dart';
import '../models/easy_home_models.dart';
import '../utils/easy_home_format.dart';

class EasyHomeController extends ChangeNotifier {
  EasyHomeController(this.repository);
  final EasyHomeRepository repository;
  StreamSubscription<String?>? _auth, _connection;
  final _membership = <StreamSubscription<dynamic>>[];
  final _data = <StreamSubscription<dynamic>>[];
  int _accountEpoch = 0, _homeEpoch = 0, _dataEpoch = 0;
  bool _disposed = false;
  String? uid, homeId, error, billingError;
  HomeModel? home;
  UserModel? member;
  HomeRequest? request;
  bool loading = true, cached = false, generating = false;
  final _loaded = <String>{};
  String _generationKey = '';
  List<FlatModel> flats = [];
  List<TenantModel> tenants = [];
  List<RentModel> rents = [];
  List<ComplaintModel> complaints = [];
  List<NotificationModel> notices = [];
  List<UserModel> members = [];
  List<HomeRequest> requests = [];
  bool get ready => _loaded.containsAll([
    'home',
    'flats',
    'complaints',
    'notices',
    if (isLandlord || (member?.tenancyId.isNotEmpty ?? false)) ...[
      'tenants',
      'rents',
    ],
    if (isLandlord) ...['members', 'requests'],
  ]);
  bool get active => member?.active == true;
  bool get isLandlord => member?.isLandlord == true;
  bool get canManage => member?.canManage == true;
  List<FlatModel> get visibleFlats =>
      flats.where((f) => !f.archived).toList()
        ..sort((a, b) => a.code.compareTo(b.code));
  int get totalDue => rents.fold(0, (v, r) => v + r.duePaisa);

  void start() {
    _auth = repository.authChanges().listen(_onUser, onError: _failed);
  }

  void _emit() {
    if (!_disposed) notifyListeners();
  }

  void _failed(Object e) {
    if (!_disposed) {
      error = easyHomeError(e);
      loading = false;
      _emit();
    }
  }

  void _cancel(List<StreamSubscription<dynamic>> subscriptions) {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
    subscriptions.clear();
  }

  void _clearData() {
    _dataEpoch++;
    _cancel(_data);
    _loaded.clear();
    _generationKey = '';
    home = null;
    flats = [];
    tenants = [];
    rents = [];
    complaints = [];
    notices = [];
    members = [];
    requests = [];
    cached = false;
    billingError = null;
    generating = false;
  }

  void _onUser(String? next) {
    final accountEpoch = ++_accountEpoch;
    unawaited(_connection?.cancel());
    uid = next;
    _onHome(null);
    if (next == null) {
      loading = false;
      _emit();
      return;
    }
    loading = true;
    _emit();
    _connection = repository
        .watchConnection(next)
        .listen(
          (id) {
            if (accountEpoch == _accountEpoch) _onHome(id);
          },
          onError: (Object e) {
            if (accountEpoch == _accountEpoch) _failed(e);
          },
        );
  }

  void _onHome(String? id) {
    final epoch = ++_homeEpoch;
    _cancel(_membership);
    _clearData();
    member = null;
    request = null;
    homeId = id;
    error = null;
    loading = id != null;
    _emit();
    if (id == null || uid == null) return;
    _membership.add(
      repository
          .watchOwnRequest(id, uid!)
          .listen(
            (value) {
              if (epoch != _homeEpoch || _disposed) return;
              request = value;
              _emit();
            },
            onError: (Object e) {
              if (epoch == _homeEpoch) _failed(e);
            },
          ),
    );
    _membership.add(
      repository
          .watchMember(id, uid!)
          .listen(
            (value) {
              if (epoch != _homeEpoch || _disposed) return;
              final changed = member?.accessKey != value?.accessKey;
              member = value;
              loading = false;
              if (!active) {
                _clearData();
              } else if (changed || _data.isEmpty) {
                _listenData(id, value!);
              }
              _emit();
            },
            onError: (Object e) {
              if (epoch == _homeEpoch) {
                _clearData();
                member = null;
                _failed(e);
              }
            },
          ),
    );
  }

  void _listenData(String id, UserModel role) {
    _clearData();
    error = null;
    final epoch = _dataEpoch;
    void listen<T>(String key, Stream<T> stream, void Function(T) setValue) {
      _data.add(
        stream.listen(
          (value) {
            if (_disposed || epoch != _dataEpoch) return;
            setValue(value);
            _loaded.add(key);
            _emit();
            if (_loaded.contains('tenants') && _loaded.contains('rents')) {
              unawaited(ensureRents());
            }
          },
          onError: (Object e) {
            if (epoch == _dataEpoch && !_disposed) {
              // Stop displaying privileged data if the server rejects access.
              _clearData();
              _failed(e);
            }
          },
        ),
      );
    }

    listen('home', repository.watchHome(id), (v) => home = v);
    listen('cache', repository.watchCached(id), (v) => cached = v);
    listen('flats', repository.watchFlats(id), (v) => flats = v);
    listen(
      'complaints',
      repository.watchComplaints(id, role),
      (v) => complaints = v,
    );
    listen('notices', repository.watchNotices(id, role), (v) => notices = v);
    if (role.isLandlord || role.tenancyId.isNotEmpty) {
      listen('tenants', repository.watchTenants(id, role), (v) => tenants = v);
      listen('rents', repository.watchRents(id, role), (v) => rents = v);
    }
    if (role.isLandlord) {
      listen('members', repository.watchMembers(id), (v) => members = v);
      listen('requests', repository.watchRequests(id), (v) => requests = v);
    }
  }

  Future<void> ensureRents({bool force = false}) async {
    if (!isLandlord ||
        generating ||
        homeId == null ||
        !_loaded.contains('rents') ||
        !_loaded.contains('tenants')) {
      return;
    }
    final now = DateTime.now();
    final existing = rents.map((r) => r.id).toSet();
    final missing = tenants
        .where(
          (t) =>
              rentalMonths(t, now).any((m) => !existing.contains('${t.id}_$m')),
        )
        .toList();
    final key =
        '${monthKey(now)}/${missing.map((t) => '${t.id}:${t.rentPaisa}:${t.active}').join(',')}';
    if (missing.isEmpty || (!force && key == _generationKey)) return;
    _generationKey = key;
    generating = true;
    billingError = null;
    _emit();
    final epoch = _dataEpoch;
    try {
      await repository.generateRents(homeId!, missing, now);
    } catch (e) {
      if (epoch == _dataEpoch) billingError = easyHomeError(e);
    } finally {
      if (epoch == _dataEpoch) {
        generating = false;
        _emit();
      }
    }
  }

  void retry() {
    if (uid != null) _onUser(uid);
  }

  @override
  void dispose() {
    _disposed = true;
    _accountEpoch++;
    _homeEpoch++;
    _dataEpoch++;
    unawaited(_auth?.cancel());
    unawaited(_connection?.cancel());
    _cancel(_membership);
    _cancel(_data);
    super.dispose();
  }
}
