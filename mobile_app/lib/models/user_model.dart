import 'enums.dart';

class UserModel {
  final String uid;
  final String email;
  final UserRole role;
  final String name;
  final String clientId;
  final String? clientName;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    required this.name,
    required this.clientId,
    this.clientName,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      role: UserRole.fromString(data['role'] ?? ''),
      name: data['name'] ?? '',
      clientId: data['clientId'] ?? '',
      clientName: data['clientName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role.value,
      'name': name,
      'clientId': clientId,
      'clientName': clientName,
    };
  }
}
