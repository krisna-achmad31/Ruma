class FamilySummaryEntity {
  final String name;
  final String location;

  /// Fase hidup pilihan keluarga, lihat FamilyStage. Kosong kalau belum dipilih.
  final String lifeStage;

  const FamilySummaryEntity({required this.name, required this.location, this.lifeStage = ''});
}
