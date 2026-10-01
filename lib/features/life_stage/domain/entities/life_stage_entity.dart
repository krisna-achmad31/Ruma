class BudgetLine {
  final String name;
  final double used;
  final double total;

  const BudgetLine({required this.name, this.used = 0, required this.total});

  BudgetLine copyWith({String? name, double? used, double? total}) =>
      BudgetLine(name: name ?? this.name, used: used ?? this.used, total: total ?? this.total);
}

class ChecklistItem {
  final String title;
  final String note;
  final bool done;

  const ChecklistItem({required this.title, this.note = '', this.done = false});

  ChecklistItem toggled() => copyWith(done: !done);

  ChecklistItem copyWith({String? title, String? note, bool? done}) =>
      ChecklistItem(title: title ?? this.title, note: note ?? this.note, done: done ?? this.done);
}

class VendorEntity {
  final String id;
  final String name;
  final String icon;
  final double amount;

  /// 'dp', 'termin', atau 'lunas'.
  final String status;
  final String note;
  final DateTime? dueDate;

  const VendorEntity({required this.id, required this.name, this.icon = 'store', required this.amount, required this.status, this.note = '', this.dueDate});

  VendorEntity withStatus(String s) => VendorEntity(id: id, name: name, icon: icon, amount: amount, status: s, note: note, dueDate: dueDate);
}

class WeddingPlanEntity {
  final DateTime weddingDate;
  final String coupleNames;
  final double budgetTotal;
  final double savings;
  final double familyHelp;
  final List<VendorEntity> vendors;
  final List<ChecklistItem> prep;

  const WeddingPlanEntity({
    required this.weddingDate,
    required this.coupleNames,
    required this.budgetTotal,
    this.savings = 0,
    this.familyHelp = 0,
    this.vendors = const [],
    this.prep = const [],
  });

  double get committed => vendors.fold(0, (s, v) => s + v.amount);
  double get shortfall => (budgetTotal - savings - familyHelp).clamp(0, double.infinity);
  int get prepDone => prep.where((p) => p.done).length;

  WeddingPlanEntity copyWith({
    DateTime? weddingDate,
    String? coupleNames,
    double? budgetTotal,
    double? savings,
    double? familyHelp,
    List<VendorEntity>? vendors,
    List<ChecklistItem>? prep,
  }) =>
      WeddingPlanEntity(
        weddingDate: weddingDate ?? this.weddingDate,
        coupleNames: coupleNames ?? this.coupleNames,
        budgetTotal: budgetTotal ?? this.budgetTotal,
        savings: savings ?? this.savings,
        familyHelp: familyHelp ?? this.familyHelp,
        vendors: vendors ?? this.vendors,
        prep: prep ?? this.prep,
      );
}

class RecipientGroup {
  final String group;
  final int count;
  final double amount;

  const RecipientGroup({required this.group, required this.count, required this.amount});

  double get total => count * amount;
}

class LebaranPlanEntity {
  final DateTime eidDate;
  final double thrAmount;
  final List<BudgetLine> allocations;
  final List<RecipientGroup> recipients;
  final List<ChecklistItem> checklist;

  const LebaranPlanEntity({
    required this.eidDate,
    required this.thrAmount,
    this.allocations = const [],
    this.recipients = const [],
    this.checklist = const [],
  });

  double get recipientsTotal => recipients.fold(0, (s, r) => s + r.total);

  double get allocatedTotal => allocations.fold(0, (s, a) => s + a.total);

  LebaranPlanEntity copyWith({
    DateTime? eidDate,
    double? thrAmount,
    List<BudgetLine>? allocations,
    List<RecipientGroup>? recipients,
    List<ChecklistItem>? checklist,
  }) =>
      LebaranPlanEntity(
        eidDate: eidDate ?? this.eidDate,
        thrAmount: thrAmount ?? this.thrAmount,
        allocations: allocations ?? this.allocations,
        recipients: recipients ?? this.recipients,
        checklist: checklist ?? this.checklist,
      );
}

class BabyPlanEntity {
  final DateTime dueDate;
  final List<BudgetLine> budgets;
  final int bagReady;
  final int bagTotal;
  final List<ChecklistItem> tasks;

  const BabyPlanEntity({required this.dueDate, this.budgets = const [], this.bagReady = 0, this.bagTotal = 22, this.tasks = const []});

  /// Usia kandungan dalam minggu, dihitung mundur dari perkiraan lahir 40 minggu.
  int weekOf(DateTime now) => (40 - dueDate.difference(now).inDays / 7).floor().clamp(0, 42);

  double get budgetTotal => budgets.fold(0, (s, b) => s + b.total);

  double get budgetUsed => budgets.fold(0, (s, b) => s + b.used);

  BabyPlanEntity copyWith({DateTime? dueDate, List<BudgetLine>? budgets, int? bagReady, int? bagTotal, List<ChecklistItem>? tasks}) => BabyPlanEntity(
        dueDate: dueDate ?? this.dueDate,
        budgets: budgets ?? this.budgets,
        bagReady: bagReady ?? this.bagReady,
        bagTotal: bagTotal ?? this.bagTotal,
        tasks: tasks ?? this.tasks,
      );
}
