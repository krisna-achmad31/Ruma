class NotificationEntity {
  final String id;
  final String icon;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final bool isRead;

  /// 'untukmu' kalau butuh tindakan dari penerima, selain itu 'info'.
  final String kind;

  /// Rute yang dibuka saat notifikasi diketuk.
  final String? route;

  /// Pengirim notifikasi, supaya tidak muncul sebagai "untukmu" bagi dirinya sendiri.
  final String? fromUid;

  const NotificationEntity({
    required this.id,
    required this.icon,
    required this.title,
    this.subtitle = '',
    required this.createdAt,
    required this.isRead,
    this.kind = 'info',
    this.route,
    this.fromUid,
  });
}
