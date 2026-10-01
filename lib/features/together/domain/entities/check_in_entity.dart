/// Check-in harian 2 menit: mood (0 sampai 4), energi (1 sampai 5), dan satu kebutuhan.
class CheckInEntity {
  final String uid;
  final String name;
  final int mood;
  final int energy;
  final String need;
  final String dateKey;
  final DateTime createdAt;

  const CheckInEntity({
    required this.uid,
    required this.name,
    required this.mood,
    required this.energy,
    required this.need,
    required this.dateKey,
    required this.createdAt,
  });

  static const moodEmojis = ['😞', '😮‍💨', '😐', '🙂', '🥰'];
  static const moodLabels = ['Lagi berat', 'Lagi capek', 'Biasa aja', 'Lagi baik', 'Lagi senang'];

  String get emoji => moodEmojis[mood.clamp(0, 4)];
}

/// Foto harian "Kita, hari ini". Disimpan sebagai thumbnail base64 supaya tidak butuh Storage.
class DailyPhotoEntity {
  final String base64;
  final String byName;
  final DateTime takenAt;

  const DailyPhotoEntity({required this.base64, required this.byName, required this.takenAt});
}
