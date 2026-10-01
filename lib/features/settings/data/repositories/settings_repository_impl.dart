import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/family_info_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource _remote;

  SettingsRepositoryImpl(this._remote);

  @override
  Stream<AppSettingsEntity> watchSettings(String familyId) => _remote.watchSettings(familyId);

  @override
  Stream<FamilyInfoEntity> watchFamilyInfo(String familyId) => _remote.watchFamilyInfo(familyId);

  @override
  Stream<List<MemberEntity>> watchMembers(String familyId) => _remote.watchMembers(familyId);

  @override
  Stream<List<VaultItemEntity>> watchVault(String familyId) => _remote.watchVault(familyId);

  @override
  Future<void> setPin(String familyId, String? pin) => _remote.setPin(familyId, pin);

  @override
  Future<void> updateSplitRatio(String familyId, Map<String, int> ratios) => _remote.updateSplitRatio(familyId, ratios);

  @override
  Future<void> updatePreference(String familyId, String key, Object value) => _remote.updatePreference(familyId, key, value);

  @override
  Future<void> updateBudgetPeriod(String familyId, {String? type, int? resetDay}) =>
      _remote.updateBudgetPeriod(familyId, type: type, resetDay: resetDay);

  @override
  Future<void> markBackup(String familyId) => _remote.markBackup(familyId);

  @override
  Future<void> addVaultItem({required String familyId, required String group, required String title, required String value, String note = ''}) =>
      _remote.addVaultItem(familyId: familyId, group: group, title: title, value: value, note: note);

  @override
  Future<void> updateFamily(String familyId, {String? name, String? location}) => _remote.updateFamily(familyId, name: name, location: location);

  @override
  Future<void> resetData(String familyId) => _remote.resetData(familyId);
}
