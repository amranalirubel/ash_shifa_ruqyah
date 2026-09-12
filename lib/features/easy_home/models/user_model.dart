enum UserRole { landlord, tenant, caretaker }

class UserModel {
  final String id;
  final String name;
  final String phone;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      role: UserRole.values.firstWhere((e) => e.name == map['role']),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'phone': phone, 'role': role.name};
  }
}
