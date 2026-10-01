import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_settings_entity.dart';
import '../../domain/entities/family_info_entity.dart';

class SettingsRemoteDataSource {
  final FirebaseFirestore _firestore;

  SettingsRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) => _firestore.collection('families').doc(familyId);

  Stream<AppSettingsEntity> watchSettings(String familyId) {
    return _familyDoc(familyId).collection('settings').snapshots().map((snapshot) {
      final docs = {for (final d in snapshot.docs) d.id: d.data()};
      final security = docs['security'] ?? {};
      final splitRatioRaw = docs['splitRatio'] ?? {};
      final budgetPeriod = docs['budgetPeriod'] ?? {};
      final backup = docs['backup'] ?? {};
      final prefs = docs['preferences'] ?? {};

      return AppSettingsEntity(
        pinSet: (security['pinSet'] as bool?) ?? false,
        pin: security['pin'] as String?,
        splitRatio: splitRatioRaw.map((k, v) => MapEntry(k, (v as num).toInt())),
        budgetPeriodType: (budgetPeriod['type'] as String?) ?? 'bulanan',
        budgetResetDay: (budgetPeriod['resetDay'] as num?)?.toInt() ?? 1,
        backupFormat: (backup['format'] as String?) ?? 'excel',
        lastBackupDate: DateTime.tryParse((backup['lastBackupDate'] as String?) ?? ''),
        biometric: (prefs['biometric'] as bool?) ?? false,
        language: (prefs['language'] as String?) ?? 'id',
        currency: (prefs['currency'] as String?) ?? 'IDR',
        moneyMode: (prefs['moneyMode'] as String?) ?? 'gabung',
      );
    });
  }

  Stream<FamilyInfoEntity> watchFamilyInfo(String familyId) {
    return _familyDoc(familyId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      final members = (data['members'] as List?) ?? [];
      return FamilyInfoEntity(
        name: (data['name'] as String?) ?? '',
        location: (data['location'] as String?) ?? '',
        memberCount: members.length,
        inviteCode: (data['inviteCode'] as String?) ?? '',
        lifeStage: (data['lifeStage'] as String?) ?? '',
      );
    });
  }

  Stream<List<MemberEntity>> watchMembers(String familyId) {
    return _firestore.collection('users').where('familyId', isEqualTo: familyId).snapshots().map((s) => s.docs.map((doc) {
          final d = doc.data();
          return MemberEntity(
            uid: doc.id,
            name: (d['name'] as String?) ?? '',
            role: (d['role'] as String?) ?? 'member',
            photoUrl: d['photoUrl'] as String?,
          );
        }).toList());
  }

  Stream<List<VaultItemEntity>> watchVault(String familyId) {
    return _familyDoc(familyId).collection('vault').snapshots().map((s) => s.docs.map((doc) {
          final d = doc.data();
          return VaultItemEntity(
            id: doc.id,
            group: (d['group'] as String?) ?? 'dokumen',
            title: (d['title'] as String?) ?? '',
            value: (d['value'] as String?) ?? '',
            note: (d['note'] as String?) ?? '',
          );
        }).toList());
  }

  Future<void> setPin(String familyId, String? pin) {
    return _familyDoc(familyId).collection('settings').doc('security').set({
      'pinSet': pin != null,
      'pin': pin,
    }, SetOptions(merge: true));
  }

  Future<void> updateSplitRatio(String familyId, Map<String, int> ratios) =>
      _familyDoc(familyId).collection('settings').doc('splitRatio').set(ratios);

  Future<void> updatePreference(String familyId, String key, Object value) =>
      _familyDoc(familyId).collection('settings').doc('preferences').set({key: value}, SetOptions(merge: true));

  Future<void> updateBudgetPeriod(String familyId, {String? type, int? resetDay}) {
    return _familyDoc(familyId).collection('settings').doc('budgetPeriod').set({
      'type': ?type,
      'resetDay': ?resetDay,
    }, SetOptions(merge: true));
  }

  Future<void> markBackup(String familyId) => _familyDoc(familyId)
      .collection('settings')
      .doc('backup')
      .set({'format': 'csv', 'lastBackupDate': DateTime.now().toIso8601String().split('T').first}, SetOptions(merge: true));

  Future<void> addVaultItem({required String familyId, required String group, required String title, required String value, String note = ''}) {
    return _familyDoc(familyId).collection('vault').add({'group': group, 'title': title, 'value': value, 'note': note});
  }

  Future<void> updateFamily(String familyId, {String? name, String? location, String? lifeStage}) {
    return _familyDoc(familyId).set({'name': ?name, 'location': ?location, 'lifeStage': ?lifeStage}, SetOptions(merge: true));
  }

  Future<void> resetData(String familyId) async {
    for (final name in ['transactions', 'journalEntries', 'loveTimeline']) {
      final docs = await _familyDoc(familyId).collection(name).get();
      final batch = _firestore.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }
}
