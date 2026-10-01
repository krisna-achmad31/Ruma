import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/l10n/app_locale.dart';
import '../../../../core/utils/format.dart';
import '../../domain/entities/life_stage_entity.dart';
import '../../domain/repositories/life_stage_repository.dart';

/// Rencana fase hidup: siap nikah, menyambut bayi, Lebaran & THR.
/// Semua isian (anggaran, tugas, vendor, penerima) bisa ditambah, diubah, dan dihapus.
class LifeStageViewModel extends ChangeNotifier {
  final LifeStageRepository _repository;
  final String familyId;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  WeddingPlanEntity? wedding;
  BabyPlanEntity? baby;
  LebaranPlanEntity? lebaran;
  bool loaded = false;

  /// Usulan awal anggaran bayi. Hanya contoh di form mulai, pengguna mengubahnya sendiri.
  /// Perkiraan kasar persalinan normal di RS swasta, perlengkapan dasar, dan dana 3 bulan pertama.
  static const babyBudgetSuggestions = [
    ('Persalinan', 9000000.0),
    ('Perlengkapan', 4000000.0),
    ('Dana 3 bulan pertama', 6000000.0),
  ];

  /// Usulan pembagian THR dalam persen. Bisa diubah per baris setelah rencana dibuat.
  static const lebaranSplit = [
    ('Zakat & sedekah', 0.09),
    ('Mudik', 0.26),
    ('Salam tempel', 0.10),
    ('Baju & kue', 0.15),
    ('Tabungan', 0.40),
  ];

  LifeStageViewModel({required this._repository, required this.familyId, required this.userName}) {
    _subs.addAll([
      _repository.watchWedding(familyId).listen((v) => _set(() => wedding = v)),
      _repository.watchBaby(familyId).listen((v) => _set(() => baby = v)),
      _repository.watchLebaran(familyId).listen((v) => _set(() => lebaran = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    loaded = true;
    notifyListeners();
  }

  int daysUntil(DateTime d) => dateOnly(d).difference(dateOnly(DateTime.now())).inDays;

  static List<T> _replaced<T>(List<T> list, int i, T item) => [...list]..[i] = item;

  static List<T> _removed<T>(List<T> list, int i) => [...list]..removeAt(i);

  // Siap nikah

  Future<void> startWedding({required DateTime date, required String names, required double budget, required double savings, required double familyHelp}) {
    return _repository.saveWedding(
      familyId,
      WeddingPlanEntity(
        weddingDate: date,
        coupleNames: names,
        budgetTotal: budget,
        savings: savings,
        familyHelp: familyHelp,
        prep: [
          for (final t in const [
            'Tentukan tanggal dan lokasi',
            'Daftar ke KUA atau catatan sipil',
            'Pilih katering',
            'Foto dan video',
            'Busana akad dan resepsi',
            'Undangan',
            'Obrolan pranikah: uang',
            'Obrolan pranikah: pembagian urusan rumah',
          ])
            ChecklistItem(title: tr(t)),
        ],
      ),
    );
  }

  Future<void> _saveWedding(WeddingPlanEntity Function(WeddingPlanEntity w) change) {
    final w = wedding;
    if (w == null) return Future.value();
    return _repository.saveWedding(familyId, change(w));
  }

  Future<void> updateWeddingInfo({required DateTime date, required String names, required double budget, required double savings, required double familyHelp}) =>
      _saveWedding((w) => w.copyWith(weddingDate: date, coupleNames: names, budgetTotal: budget, savings: savings, familyHelp: familyHelp));

  Future<void> addVendor({required String name, required double amount, required String status, DateTime? due}) {
    final v = VendorEntity(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, amount: amount, status: status, dueDate: due);
    return _saveWedding((w) => w.copyWith(vendors: [...w.vendors, v]));
  }

  Future<void> updateVendor(VendorEntity updated) =>
      _saveWedding((w) => w.copyWith(vendors: w.vendors.map((x) => x.id == updated.id ? updated : x).toList()));

  Future<void> deleteVendor(String id) => _saveWedding((w) => w.copyWith(vendors: w.vendors.where((x) => x.id != id).toList()));

  Future<void> advanceVendor(VendorEntity v) => updateVendor(v.withStatus(v.status == 'dp' ? 'termin' : 'lunas'));

  Future<void> togglePrep(int i) => _saveWedding((w) => w.copyWith(prep: _replaced(w.prep, i, w.prep[i].toggled())));

  Future<void> addPrep(ChecklistItem item) => _saveWedding((w) => w.copyWith(prep: [...w.prep, item]));

  Future<void> updatePrep(int i, ChecklistItem item) => _saveWedding((w) => w.copyWith(prep: _replaced(w.prep, i, item)));

  Future<void> deletePrep(int i) => _saveWedding((w) => w.copyWith(prep: _removed(w.prep, i)));

  Future<void> deleteWedding() => _repository.deletePlan(familyId, 'wedding');

  // Menyambut bayi

  Future<void> startBaby(DateTime dueDate, List<BudgetLine> budgets) {
    return _repository.saveBaby(
      familyId,
      BabyPlanEntity(
        dueDate: dueDate,
        budgets: budgets,
        tasks: [
          ChecklistItem(title: tr('Jaga malam bergantian'), note: tr('Atur giliran tiap malam')),
          ChecklistItem(title: tr('Kontrol kandungan'), note: tr('Tentukan siapa yang mengantar')),
          ChecklistItem(title: tr('Siapkan tas persalinan'), note: tr('Mulai di minggu 34')),
        ],
      ),
    );
  }

  Future<void> _saveBaby(BabyPlanEntity Function(BabyPlanEntity b) change) {
    final b = baby;
    if (b == null) return Future.value();
    return _repository.saveBaby(familyId, change(b));
  }

  Future<void> updateDueDate(DateTime d) => _saveBaby((b) => b.copyWith(dueDate: d));

  Future<void> addBabyBudgetUse(int i, double amount) =>
      _saveBaby((b) => b.copyWith(budgets: _replaced(b.budgets, i, b.budgets[i].copyWith(used: b.budgets[i].used + amount))));

  Future<void> addBabyBudget(BudgetLine line) => _saveBaby((b) => b.copyWith(budgets: [...b.budgets, line]));

  Future<void> updateBabyBudget(int i, BudgetLine line) => _saveBaby((b) => b.copyWith(budgets: _replaced(b.budgets, i, line)));

  Future<void> deleteBabyBudget(int i) => _saveBaby((b) => b.copyWith(budgets: _removed(b.budgets, i)));

  Future<void> setBagReady(int ready) => _saveBaby((b) => b.copyWith(bagReady: ready.clamp(0, b.bagTotal)));

  Future<void> setBagTotal(int total) => _saveBaby((b) => b.copyWith(bagTotal: total.clamp(1, 99), bagReady: b.bagReady.clamp(0, total.clamp(1, 99))));

  Future<void> toggleBabyTask(int i) => _saveBaby((b) => b.copyWith(tasks: _replaced(b.tasks, i, b.tasks[i].toggled())));

  Future<void> addBabyTask(ChecklistItem item) => _saveBaby((b) => b.copyWith(tasks: [...b.tasks, item]));

  Future<void> updateBabyTask(int i, ChecklistItem item) => _saveBaby((b) => b.copyWith(tasks: _replaced(b.tasks, i, item)));

  Future<void> deleteBabyTask(int i) => _saveBaby((b) => b.copyWith(tasks: _removed(b.tasks, i)));

  Future<void> deleteBaby() => _repository.deletePlan(familyId, 'baby');

  // Lebaran dan THR

  static List<BudgetLine> _splitThr(double thr) => [for (final s in lebaranSplit) BudgetLine(name: tr(s.$1), total: thr * s.$2)];

  Future<void> startLebaran({required DateTime eidDate, required double thr}) {
    return _repository.saveLebaran(
      familyId,
      LebaranPlanEntity(
        eidDate: eidDate,
        thrAmount: thr,
        allocations: _splitThr(thr),
        recipients: [
          RecipientGroup(group: tr('Keponakan SD'), count: 6, amount: 50000),
          RecipientGroup(group: tr('Keponakan SMP-SMA'), count: 4, amount: 100000),
          RecipientGroup(group: tr('Orang tua & mertua'), count: 4, amount: 250000),
        ],
        checklist: [
          ChecklistItem(title: tr('Pesan tiket mudik'), note: tr('Tiket kereta biasanya dibuka H-45')),
          ChecklistItem(title: tr('Servis kendaraan sebelum mudik'), note: tr('Masukkan ke Rumah sehat')),
          ChecklistItem(title: tr('Titip rumah ke tetangga')),
        ],
      ),
    );
  }

  Future<void> _saveLebaran(LebaranPlanEntity Function(LebaranPlanEntity l) change) {
    final l = lebaran;
    if (l == null) return Future.value();
    return _repository.saveLebaran(familyId, change(l));
  }

  Future<void> updateLebaranInfo({required DateTime eidDate, required double thr}) => _saveLebaran((l) => l.copyWith(eidDate: eidDate, thrAmount: thr));

  /// Bagi ulang THR memakai persen usulan. Menimpa alokasi yang ada.
  Future<void> resplitThr() => _saveLebaran((l) => l.copyWith(allocations: _splitThr(l.thrAmount)));

  Future<void> addAllocation(BudgetLine line) => _saveLebaran((l) => l.copyWith(allocations: [...l.allocations, line]));

  Future<void> updateAllocation(int i, BudgetLine line) => _saveLebaran((l) => l.copyWith(allocations: _replaced(l.allocations, i, line)));

  Future<void> deleteAllocation(int i) => _saveLebaran((l) => l.copyWith(allocations: _removed(l.allocations, i)));

  Future<void> addRecipient(String group, int count, double amount) =>
      _saveLebaran((l) => l.copyWith(recipients: [...l.recipients, RecipientGroup(group: group, count: count, amount: amount)]));

  Future<void> updateRecipient(int i, RecipientGroup r) => _saveLebaran((l) => l.copyWith(recipients: _replaced(l.recipients, i, r)));

  Future<void> deleteRecipient(int i) => _saveLebaran((l) => l.copyWith(recipients: _removed(l.recipients, i)));

  Future<void> toggleLebaranItem(int i) => _saveLebaran((l) => l.copyWith(checklist: _replaced(l.checklist, i, l.checklist[i].toggled())));

  Future<void> addLebaranItem(ChecklistItem item) => _saveLebaran((l) => l.copyWith(checklist: [...l.checklist, item]));

  Future<void> updateLebaranItem(int i, ChecklistItem item) => _saveLebaran((l) => l.copyWith(checklist: _replaced(l.checklist, i, item)));

  Future<void> deleteLebaranItem(int i) => _saveLebaran((l) => l.copyWith(checklist: _removed(l.checklist, i)));

  Future<void> deleteLebaran() => _repository.deletePlan(familyId, 'lebaran');

  /// Berapa yang perlu disisihkan tiap bulan sampai Lebaran supaya pengeluaran tidak bergantung penuh pada THR.
  double lebaranMonthlySetAside(LebaranPlanEntity l) {
    final months = (daysUntil(l.eidDate) / 30).ceil().clamp(1, 12);
    final spending = l.allocations.where((a) => a.name != 'Tabungan' && a.name != 'Savings').fold(0.0, (s, a) => s + a.total);
    return spending * 0.3 / months;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
