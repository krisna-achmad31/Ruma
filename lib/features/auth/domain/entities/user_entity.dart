class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final String familyId;
  final String role;
  final String? photoUrl;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    required this.familyId,
    required this.role,
    this.photoUrl,
  });
}
