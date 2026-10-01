class WeatherSummary {
  final double morning;
  final double noon;
  final String condition;

  const WeatherSummary({required this.morning, required this.noon, required this.condition});

  String get label => '${morning.round()}° pagi, ${noon.round()}° siang';
}

abstract class WeatherRepository {
  /// Perkiraan suhu pagi dan siang hari ini untuk nama kota. Null kalau gagal.
  Future<WeatherSummary?> todayFor(String city);
}
