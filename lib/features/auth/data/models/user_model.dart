import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.phone,
    required super.familyId,
    required super.role,
    super.photoUrl,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] as String,
      email: map['email'] as String,
      phone: map['phone'] as String?,
      familyId: map['familyId'] as String,
      role: map['role'] as String,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'familyId': familyId,
      'role': role,
      'photoUrl': photoUrl,
    };
  }
}
