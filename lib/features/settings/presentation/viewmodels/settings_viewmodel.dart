import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/family_info_entity.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsViewModel extends ChangeNotifier {
  final SettingsRepository _settingsRepository;
  final String familyId;

  final List<StreamSubscription<dynamic>> _subs = [];

  AppSettingsEntity settings = const AppSettingsEntity(
    pinSet: false,
    splitRatio: {},
    budgetPeriodType: 'bulanan',
    budgetResetDay: 1,
    backupFormat: 'excel',
  );
  FamilyInfoEntity familyInfo = const FamilyInfoEntity(name: '', location: '', memberCount: 0);
  List<MemberEntity> members = [];
  List<VaultItemEntity> vault = [];

  /// Brankas terbuka sementara setelah PIN benar, lalu terkunci lagi otomatis.
  DateTime? vaultUnlockedUntil;
  Timer? _lockTimer;

  SettingsViewModel({required this._settingsRepository, required this.familyId}) {
    _subs.addAll([
      _settingsRepository.watchSettings(familyId).listen((v) => _set(() => settings = v)),
      _settingsRepository.watchFamilyInfo(familyId).listen((v) => _set(() => familyInfo = v)),
      _settingsRepository.watchMembers(familyId).listen((v) => _set(() => members = v)),
      _settingsRepository.watchVault(familyId).listen((v) => _set(() => vault = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    notifyListeners();
  }

  bool get vaultUnlocked => vaultUnlockedUntil != null && DateTime.now().isBefore(vaultUnlockedUntil!);

  bool tryUnlock(String pin) {
    if (settings.pin == null || pin != settings.pin) return false;
    vaultUnlockedUntil = DateTime.now().add(const Duration(minutes: 1));
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(minutes: 1), () => _set(() => vaultUnlockedUntil = null));
    notifyListeners();
    return true;
  }

  void unlockWithoutPin() {
    vaultUnlockedUntil = DateTime.now().add(const Duration(minutes: 1));
    _lockTimer?.cancel();
    _lockTimer = Timer(const Duration(minutes: 1), () => _set(() => vaultUnlockedUntil = null));
    notifyListeners();
  }

  List<VaultItemEntity> vaultOf(String group) => vault.where((v) => v.group == group).toList();

  Future<void> setPin(String? pin) => _settingsRepository.setPin(familyId, pin);
  Future<void> setBiometric(bool v) => _settingsRepository.updatePreference(familyId, 'biometric', v);
  Future<void> setLanguage(String v) => _settingsRepository.updatePreference(familyId, 'language', v);
  Future<void> setCurrency(String v) => _settingsRepository.updatePreference(familyId, 'currency', v);
  Future<void> setMoneyMode(String v) => _settingsRepository.updatePreference(familyId, 'moneyMode', v);
  Future<void> setBudgetPeriod(String type) => _settingsRepository.updateBudgetPeriod(familyId, type: type);
  Future<void> setResetDay(int day) => _settingsRepository.updateBudgetPeriod(familyId, resetDay: day);
  Future<void> markBackup() => _settingsRepository.markBackup(familyId);
  Future<void> resetData() => _settingsRepository.resetData(familyId);
  Future<void> updateFamily({String? name, String? location}) => _settingsRepository.updateFamily(familyId, name: name, location: location);

  Future<void> addVaultItem(String group, String title, String value) =>
      _settingsRepository.addVaultItem(familyId: familyId, group: group, title: title, value: value);

  @override
  void dispose() {
    _lockTimer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
