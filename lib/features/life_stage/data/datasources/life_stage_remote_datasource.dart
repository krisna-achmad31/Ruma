import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/life_stage_entity.dart';

/// Satu dokumen per fase: lifeStages/wedding, lifeStages/baby, lifeStages/lebaran.
class LifeStageRemoteDataSource {
  final FirebaseFirestore _firestore;

  LifeStageRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String familyId, String id) =>
      _firestore.collection('families').doc(familyId).collection('lifeStages').doc(id);

  static String _day(DateTime d) => d.toIso8601String().split('T').first;
  static double _num(dynamic v) => (v as num?)?.toDouble() ?? 0;
  static List<Map<String, dynamic>> _list(dynamic v) => ((v as List?) ?? const []).cast<Map<String, dynamic>>();

  static BudgetLine _line(Map<String, dynamic> m) => BudgetLine(name: (m['name'] as String?) ?? '', used: _num(m['used']), total: _num(m['total']));
  static Map<String, dynamic> _lineMap(BudgetLine l) => {'name': l.name, 'used': l.used, 'total': l.total};
  static ChecklistItem _check(Map<String, dynamic> m) =>
      ChecklistItem(title: (m['title'] as String?) ?? '', note: (m['note'] as String?) ?? '', done: (m['done'] as bool?) ?? false);
  static Map<String, dynamic> _checkMap(ChecklistItem c) => {'title': c.title, 'note': c.note, 'done': c.done};

  Stream<WeddingPlanEntity?> watchWedding(String familyId) {
    return _doc(familyId, 'wedding').snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return null;
      return WeddingPlanEntity(
        weddingDate: DateTime.tryParse((d['weddingDate'] as String?) ?? '') ?? DateTime.now(),
        coupleNames: (d['coupleNames'] as String?) ?? '',
        budgetTotal: _num(d['budgetTotal']),
        savings: _num(d['savings']),
        familyHelp: _num(d['familyHelp']),
        vendors: _list(d['vendors'])
            .map((m) => VendorEntity(
                  id: (m['id'] as String?) ?? '',
                  name: (m['name'] as String?) ?? '',
                  icon: (m['icon'] as String?) ?? 'store',
                  amount: _num(m['amount']),
                  status: (m['status'] as String?) ?? 'dp',
                  note: (m['note'] as String?) ?? '',
                  dueDate: DateTime.tryParse((m['dueDate'] as String?) ?? ''),
                ))
            .toList(),
        prep: _list(d['prep']).map(_check).toList(),
      );
    });
  }

  Future<void> saveWedding(String familyId, WeddingPlanEntity p) {
    return _doc(familyId, 'wedding').set({
      'weddingDate': _day(p.weddingDate),
      'coupleNames': p.coupleNames,
      'budgetTotal': p.budgetTotal,
      'savings': p.savings,
      'familyHelp': p.familyHelp,
      'vendors': p.vendors
          .map((v) => {
                'id': v.id,
                'name': v.name,
                'icon': v.icon,
                'amount': v.amount,
                'status': v.status,
                'note': v.note,
                if (v.dueDate != null) 'dueDate': _day(v.dueDate!),
              })
          .toList(),
      'prep': p.prep.map(_checkMap).toList(),
    });
  }

  Stream<BabyPlanEntity?> watchBaby(String familyId) {
    return _doc(familyId, 'baby').snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return null;
      return BabyPlanEntity(
        dueDate: DateTime.tryParse((d['dueDate'] as String?) ?? '') ?? DateTime.now(),
        budgets: _list(d['budgets']).map(_line).toList(),
        bagReady: (d['bagReady'] as num?)?.toInt() ?? 0,
        bagTotal: (d['bagTotal'] as num?)?.toInt() ?? 22,
        tasks: _list(d['tasks']).map(_check).toList(),
      );
    });
  }

  Future<void> saveBaby(String familyId, BabyPlanEntity p) {
    return _doc(familyId, 'baby').set({
      'dueDate': _day(p.dueDate),
      'budgets': p.budgets.map(_lineMap).toList(),
      'bagReady': p.bagReady,
      'bagTotal': p.bagTotal,
      'tasks': p.tasks.map(_checkMap).toList(),
    });
  }

  Stream<LebaranPlanEntity?> watchLebaran(String familyId) {
    return _doc(familyId, 'lebaran').snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return null;
      return LebaranPlanEntity(
        eidDate: DateTime.tryParse((d['eidDate'] as String?) ?? '') ?? DateTime.now(),
        thrAmount: _num(d['thrAmount']),
        allocations: _list(d['allocations']).map(_line).toList(),
        recipients: _list(d['recipients'])
            .map((m) => RecipientGroup(group: (m['group'] as String?) ?? '', count: (m['count'] as num?)?.toInt() ?? 0, amount: _num(m['amount'])))
            .toList(),
        checklist: _list(d['checklist']).map(_check).toList(),
      );
    });
  }

  Future<void> saveLebaran(String familyId, LebaranPlanEntity p) {
    return _doc(familyId, 'lebaran').set({
      'eidDate': _day(p.eidDate),
      'thrAmount': p.thrAmount,
      'allocations': p.allocations.map(_lineMap).toList(),
      'recipients': p.recipients.map((r) => {'group': r.group, 'count': r.count, 'amount': r.amount}).toList(),
      'checklist': p.checklist.map(_checkMap).toList(),
    });
  }

  Future<void> deletePlan(String familyId, String stage) => _doc(familyId, stage).delete();
}
