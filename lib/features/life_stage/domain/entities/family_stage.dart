/// Fase hidup keluarga yang dipilih saat onboarding, disimpan di field `lifeStage` dokumen keluarga.
/// Dipakai untuk menentukan sorotan fase hidup di Hari ini dan urutan kartu di Rumah.
class FamilyStage {
  FamilyStage._();

  static const wedding = 'siap_nikah';
  static const newlywed = 'baru_menikah';
  static const expecting = 'menanti_bayi';
  static const parents = 'punya_anak';

  static const all = [wedding, newlywed, expecting, parents];

  /// Rencana fase hidup yang paling cocok untuk fase ini: 'wedding', 'baby', atau 'lebaran'.
  static String planFor(String? stage) => switch (stage) {
        wedding => 'wedding',
        expecting => 'baby',
        _ => 'lebaran',
      };
}
