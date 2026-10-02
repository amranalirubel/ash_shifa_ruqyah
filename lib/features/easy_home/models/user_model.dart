enum UserRole { landlord, tenant, caretaker }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.landlord => 'বাড়িওয়ালা',
    UserRole.tenant => 'ভাড়াটিয়া',
    UserRole.caretaker => 'কেয়ারটেকার',
  };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.active = true,
    this.tenancyId = '',
    this.flatId = '',
    this.floor = '',
  });
  final String id, name, phone, tenancyId, flatId, floor;
  final UserRole role;
  final bool active;
  bool get isLandlord => active && role == UserRole.landlord;
  bool get canManage => active && role != UserRole.tenant;
  String get accessKey => '$id/${role.name}/$active/$tenancyId/$flatId/$floor';
  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['id'] as String? ?? '',
    name: map['name'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    role: UserRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => UserRole.tenant,
    ),
    active: map['active'] == true,
    tenancyId: map['tenancyId'] as String? ?? '',
    flatId: map['flatId'] as String? ?? '',
    floor: map['floor'] as String? ?? '',
  );
}

class HomeModel {
  const HomeModel({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.inviteCode,
    required this.joiningEnabled,
  });
  final String id, name, ownerUid, inviteCode;
  final bool joiningEnabled;
  factory HomeModel.fromMap(Map<String, dynamic> m) => HomeModel(
    id: m['id'] as String,
    name: m['name'] as String,
    ownerUid: m['ownerUid'] as String,
    inviteCode: m['inviteCode'] as String,
    joiningEnabled: m['joiningEnabled'] == true,
  );
}

class HomeRequest {
  const HomeRequest({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.status = 'pending',
  });
  final String id, name, phone, status;
  final UserRole role;
  factory HomeRequest.fromMap(Map<String, dynamic> m) => HomeRequest(
    id: m['id'] as String,
    name: m['name'] as String,
    phone: m['phone'] as String,
    role: m['role'] == 'caretaker' ? UserRole.caretaker : UserRole.tenant,
    status: m['status'] as String? ?? 'pending',
  );
}
