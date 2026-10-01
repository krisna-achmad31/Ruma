import '../entities/app_settings_entity.dart';
import '../entities/family_info_entity.dart';

abstract class SettingsRepository {
  Stream<AppSettingsEntity> watchSettings(String familyId);
  Stream<FamilyInfoEntity> watchFamilyInfo(String familyId);
  Stream<List<MemberEntity>> watchMembers(String familyId);
  Stream<List<VaultItemEntity>> watchVault(String familyId);

  Future<void> setPin(String familyId, String? pin);
  Future<void> updateSplitRatio(String familyId, Map<String, int> ratios);
  Future<void> updatePreference(String familyId, String key, Object value);
  Future<void> updateBudgetPeriod(String familyId, {String? type, int? resetDay});
  Future<void> markBackup(String familyId);
  Future<void> addVaultItem({required String familyId, required String group, required String title, required String value, String note = ''});
  Future<void> updateFamily(String familyId, {String? name, String? location, String? lifeStage});

  /// Menghapus transaksi, jurnal, dan momen keluarga ini.
  Future<void> resetData(String familyId);
}
