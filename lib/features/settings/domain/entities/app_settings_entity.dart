class AppSettingsEntity {
  final bool pinSet;
  final String? pin;
  final Map<String, int> splitRatio;
  final String budgetPeriodType;
  final int budgetResetDay;
  final String backupFormat;
  final DateTime? lastBackupDate;
  final bool biometric;
  final String language;
  final String currency;

  /// 'gabung' (semua dompet jadi uang rumah) atau 'sebagian'.
  final String moneyMode;

  const AppSettingsEntity({
    required this.pinSet,
    this.pin,
    required this.splitRatio,
    required this.budgetPeriodType,
    required this.budgetResetDay,
    required this.backupFormat,
    this.lastBackupDate,
    this.biometric = false,
    this.language = 'id',
    this.currency = 'IDR',
    this.moneyMode = 'gabung',
  });
}
