class JournalEntryEntity {
  final String id;
  final String authorUid;
  final String authorName;
  final String title;
  final String text;
  final DateTime date;
  final String time;

  /// 'cerita' untuk cerita biasa, 'makasih' untuk ucapan terima kasih.
  final String type;

  const JournalEntryEntity({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.title,
    required this.text,
    required this.date,
    required this.time,
    this.type = 'cerita',
  });

  bool get isThanks => type == 'makasih';
}
