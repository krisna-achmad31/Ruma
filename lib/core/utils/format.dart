import '../l10n/app_locale.dart';

/// Format angka dan tanggal yang dipakai di semua layar, mengikuti bahasa aktif.
String formatRupiah(double value, {bool withSign = false}) {
  final isNegative = value < 0;
  final digits = value.abs().round().toString();
  final buffer = StringBuffer();
  for (int i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(AppLocale.instance.isEn ? ',' : '.');
    buffer.write(digits[i]);
  }
  final sign = isNegative ? '−' : (withSign ? '+' : '');
  return '${sign}Rp$buffer';
}

/// Versi ringkas: Rp2,18 jt, Rp640rb.
String formatRupiahShort(double value) {
  final abs = value.abs();
  final sign = value < 0 ? '−' : '';
  if (abs >= 1000000) {
    final jt = abs / 1000000;
    final text = jt >= 100 ? jt.toStringAsFixed(0) : _trimZeros(jt.toStringAsFixed(2));
    if (AppLocale.instance.isEn) return '${sign}Rp${text}M';
    return '${sign}Rp${text.replaceAll('.', ',')} jt';
  }
  if (abs >= 1000) return '${sign}Rp${(abs / 1000).round()}${AppLocale.instance.isEn ? 'K' : 'rb'}';
  return '${sign}Rp${abs.round()}';
}

String _trimZeros(String s) {
  if (!s.contains('.')) return s;
  s = s.replaceAll(RegExp(r'0+$'), '');
  return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
}

const _monthNamesIdSrc = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];
const _monthNamesEn = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
const _shortMonthNamesIdSrc = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
const _shortMonthNamesEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _dayNamesIdSrc = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
const _dayNamesEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _shortDayNamesIdSrc = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _shortDayNamesEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Nama bulan dan hari sesuai bahasa aktif.
List<String> get monthNamesId => AppLocale.instance.isEn ? _monthNamesEn : _monthNamesIdSrc;

List<String> get shortMonthNamesId => AppLocale.instance.isEn ? _shortMonthNamesEn : _shortMonthNamesIdSrc;

List<String> get dayNamesId => AppLocale.instance.isEn ? _dayNamesEn : _dayNamesIdSrc;

List<String> get shortDayNamesId => AppLocale.instance.isEn ? _shortDayNamesEn : _shortDayNamesIdSrc;

String formatShortDate(DateTime d) => AppLocale.instance.isEn ? '${shortMonthNamesId[d.month - 1]} ${d.day}' : '${d.day} ${shortMonthNamesId[d.month - 1]}';

String formatLongDate(DateTime d) => AppLocale.instance.isEn
    ? '${dayNamesId[d.weekday - 1]}, ${monthNamesId[d.month - 1]} ${d.day}'
    : '${dayNamesId[d.weekday - 1]}, ${d.day} ${monthNamesId[d.month - 1]}';

String formatFullDate(DateTime d) => AppLocale.instance.isEn
    ? '${shortMonthNamesId[d.month - 1]} ${d.day}, ${d.year}'
    : '${d.day} ${shortMonthNamesId[d.month - 1]} ${d.year}';

String monthKeyOf(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}';

String dayKeyOf(DateTime d) => '${monthKeyOf(d)}-${d.day.toString().padLeft(2, '0')}';

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Hari ini", "Besok", "Sab" atau "3 Okt", untuk label jatuh tempo.
String relativeDayLabel(DateTime date, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final diff = dateOnly(date).difference(today).inDays;
  if (diff == 0) return tr('Hari ini');
  if (diff == 1) return tr('Besok');
  if (diff == -1) return tr('Kemarin');
  if (diff > 1 && diff < 7) return dayNamesId[date.weekday - 1];
  return formatShortDate(date);
}

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 11) return tr('Selamat pagi');
  if (h < 15) return tr('Selamat siang');
  if (h < 18) return tr('Selamat sore');
  return tr('Selamat malam');
}

String initialOf(String name) => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
