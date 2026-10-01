class FamilyInfoEntity {
  final String name;
  final String location;
  final int memberCount;
  final String inviteCode;

  /// Fase hidup pilihan keluarga, lihat FamilyStage. Kosong kalau belum dipilih.
  final String lifeStage;

  const FamilyInfoEntity({required this.name, required this.location, required this.memberCount, this.inviteCode = '', this.lifeStage = ''});
}

class MemberEntity {
  final String uid;
  final String name;
  final String role;
  final String? photoUrl;

  const MemberEntity({required this.uid, required this.name, required this.role, this.photoUrl});
}

/// Isi Brankas: nomor penting, dokumen, dan tautan keluarga.
class VaultItemEntity {
  final String id;

  /// 'nomor', 'dokumen', atau 'link'.
  final String group;
  final String title;
  final String value;
  final String note;
  final String icon;

  const VaultItemEntity({required this.id, required this.group, required this.title, required this.value, this.note = '', this.icon = 'file'});

  String get masked {
    final v = value.replaceAll(' ', '');
    if (group != 'nomor' || v.length < 8) return value;
    return '${v.substring(0, 4)} •••• ${v.substring(v.length - 4)}';
  }
}
