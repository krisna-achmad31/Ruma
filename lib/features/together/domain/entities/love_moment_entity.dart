class LoveMomentEntity {
  final String id;
  final String title;
  final String icon;
  final DateTime date;

  /// True kalau momen dicatat otomatis dari kebiasaan (streak check-in, amplop aman, dan lainnya).
  final bool auto;

  const LoveMomentEntity({
    required this.id,
    required this.title,
    required this.icon,
    required this.date,
    this.auto = false,
  });
}
