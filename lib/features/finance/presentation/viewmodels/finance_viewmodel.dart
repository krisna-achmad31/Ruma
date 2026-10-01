import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/format.dart';
import '../../../settings/domain/entities/app_settings_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/money_extras_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transfer_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../../domain/usecases/parse_quick_entry.dart';

class FinanceViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepository;
  final SettingsRepository? _settingsRepository;
  final String familyId;
  final String uid;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  List<WalletEntity> wallets = [];
  List<CategoryEntity> categories = [];
  List<TransactionEntity> transactions = [];
  List<WalletTransferEntity> transfers = [];
  MonthlyReportEntity? monthlyReport;
  List<GoalEntity> goals = [];
  List<InstallmentEntity> installments = [];
  List<AssetEntity> assets = [];
  List<WishlistItemEntity> wishlist = [];
  AppSettingsEntity? settings;
  String familyName = '';

  String walletFilter = 'Semua';
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  FinanceViewModel({
    required this._financeRepository,
    required this.familyId,
    this._settingsRepository,
    this.uid = '',
    this.userName = '',
  }) {
    _subs.addAll([
      _financeRepository.watchWallets(familyId).listen((v) => _set(() => wallets = v)),
      _financeRepository.watchCategories(familyId).listen((v) => _set(() => categories = v)),
      _financeRepository.watchTransactions(familyId).listen((v) => _set(() => transactions = v)),
      _financeRepository.watchTransfers(familyId).listen((v) => _set(() => transfers = v)),
      _financeRepository.watchMonthlyReport(familyId, currentMonthKey).listen((v) => _set(() => monthlyReport = v)),
      _financeRepository.watchFamilyName(familyId).listen((v) => _set(() => familyName = v)),
      _financeRepository.watchGoals(familyId).listen((v) => _set(() => goals = v)),
      _financeRepository.watchInstallments(familyId).listen((v) => _set(() => installments = v)),
      _financeRepository.watchAssets(familyId).listen((v) => _set(() => assets = v)),
      _financeRepository.watchWishlist(familyId).listen((v) => _set(() => wishlist = v)),
      if (_settingsRepository != null) _settingsRepository.watchSettings(familyId).listen((v) => _set(() => settings = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    notifyListeners();
  }

  String get currentMonthKey => monthKeyOf(DateTime.now());

  void changeMonth(int delta) {
    selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + delta);
    notifyListeners();
  }

  // Dompet
  void setWalletFilter(String filter) {
    walletFilter = filter;
    notifyListeners();
  }

  List<WalletEntity> get spendingWallets => wallets.where((w) => w.type != 'savings').toList();

  List<WalletEntity> get filteredWallets {
    switch (walletFilter) {
      case 'Tunai':
        return wallets.where((w) => w.type == 'cash').toList();
      case 'Bank':
        return wallets.where((w) => w.type == 'bank').toList();
      case 'E-wallet':
        return wallets.where((w) => w.type == 'ewallet').toList();
      default:
        return wallets;
    }
  }

  double get householdMoney => spendingWallets.fold(0.0, (s, w) => s + w.balance);
  double get savingsMoney => wallets.where((w) => w.type == 'savings').fold(0.0, (s, w) => s + w.balance);
  double get totalAllWallets => wallets.fold(0.0, (s, w) => s + w.balance);

  WalletEntity? walletById(String id) => wallets.where((w) => w.id == id).firstOrNull;

  // Transaksi bulan terpilih
  List<TransactionEntity> transactionsIn(DateTime month) =>
      transactions.where((t) => t.date.year == month.year && t.date.month == month.month).toList();

  double get monthIncome => transactionsIn(selectedMonth).where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());
  double get monthExpense => transactionsIn(selectedMonth).where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount.abs());

  // Amplop
  int get resetDay => settings?.budgetResetDay ?? 1;
  double get budgetTotal => categories.fold(0, (s, c) => s + c.budgetAmount);
  double get budgetRemaining => categories.fold(0, (s, c) => s + (c.budgetAmount - c.spentAmount).clamp(0, double.infinity));

  CategoryEntity? categoryById(String? id) => id == null ? null : categories.where((c) => c.id == id).firstOrNull;

  double remainingOf(CategoryEntity c) => (c.budgetAmount - c.spentAmount).clamp(0, double.infinity);
  double remainingFractionOf(CategoryEntity c) => c.budgetAmount <= 0 ? 0 : remainingOf(c) / c.budgetAmount;
  bool isLow(CategoryEntity c) => remainingFractionOf(c) < 0.2;

  int get daysToPayday {
    final now = dateOnly(DateTime.now());
    var next = DateTime(now.year, now.month, resetDay);
    if (!next.isAfter(now)) next = DateTime(now.year, now.month + 1, resetDay);
    return next.difference(now).inDays.clamp(1, 31);
  }

  double safePerDay(CategoryEntity c) => remainingOf(c) / daysToPayday;

  List<TransactionEntity> transactionsOf(String categoryId) => transactions.where((t) => t.categoryId == categoryId).toList();

  /// Persentase perubahan pengeluaran amplop dibanding bulan lalu. Null kalau belum ada data.
  double? changeVsLastMonth(String categoryId) {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month - 1);
    double sum(DateTime m) => transactionsIn(m).where((t) => t.categoryId == categoryId).fold(0.0, (s, t) => s + t.amount.abs());
    final prev = sum(last);
    if (prev <= 0) return null;
    return (sum(now) - prev) / prev * 100;
  }

  /// Saran pindah anggaran: amplop yang hampir habis dan amplop yang paling longgar.
  (CategoryEntity, CategoryEntity)? get rebalanceSuggestion {
    final low = categories.where(isLow).toList();
    if (low.isEmpty) return null;
    final loose = [...categories]..sort((a, b) => remainingFractionOf(b).compareTo(remainingFractionOf(a)));
    if (loose.isEmpty || loose.first.id == low.first.id || remainingFractionOf(loose.first) < 0.5) return null;
    return (low.first, loose.first);
  }

  // Rekap
  double get netWorth {
    final assetsTotal = assets.where((a) => a.kind != 'utang').fold(0.0, (s, a) => s + a.value);
    final debts = assets.where((a) => a.kind == 'utang').fold(0.0, (s, a) => s + a.value);
    return totalAllWallets + assetsTotal - debts;
  }

  double get investmentTotal => assets.where((a) => a.kind == 'aset').fold(0.0, (s, a) => s + a.value);

  /// Kekayaan bersih 6 bulan terakhir dari laporan bulanan, kalau ada.
  List<(String, double)> get trend {
    final map = monthlyReport?.trend6Months ?? {};
    final keys = map.keys.toList()..sort();
    return keys.map((k) => (shortMonthNamesId[int.parse(k.split('-')[1]) - 1], map[k]!)).toList();
  }

  // Cicilan dan paylater
  double get installmentsMonthly => installments.fold(0.0, (s, i) => s + i.monthlyAmount);

  double get monthlyIncomeEstimate {
    final now = DateTime.now();
    final thisMonth = transactionsIn(now).where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    if (thisMonth > 0) return thisMonth;
    final last = transactionsIn(DateTime(now.year, now.month - 1)).where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    if (last > 0) return last;
    return monthlyReport?.income ?? 0;
  }

  double get debtRatio => monthlyIncomeEstimate <= 0 ? 0 : installmentsMonthly / monthlyIncomeEstimate;

  // Aset
  List<AssetEntity> assetsOf(String kind) => assets.where((a) => a.kind == kind).toList();
  double get assetNet => assets.fold(0.0, (s, a) => s + (a.kind == 'utang' ? -a.value : a.value));

  // Aksi
  Future<void> addTransaction({
    required String title,
    required double amount,
    required bool isIncome,
    required String walletId,
    String? categoryId,
    required DateTime date,
  }) {
    return _financeRepository.addTransaction(
      familyId: familyId,
      title: title,
      amount: amount,
      type: isIncome ? 'income' : 'expense',
      walletId: walletId,
      categoryId: isIncome ? null : categoryId,
      date: date,
      createdByName: userName,
    );
  }

  QuickEntry? parse(String text) => ParseQuickEntry()(text, wallets: wallets, categories: categories);

  Future<void> transfer({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required double adminFee,
    required DateTime date,
  }) {
    final feeCategory = categories.where((c) => c.name.toLowerCase().contains('rumah') || c.name.toLowerCase().contains('tagihan')).firstOrNull;
    return _financeRepository.transferBetweenWallets(
      familyId: familyId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      adminFee: adminFee,
      date: date,
      adminFeeCategoryId: feeCategory?.id,
    );
  }

  Future<void> addWallet(String name, String type, double balance) =>
      _financeRepository.addWallet(familyId: familyId, name: name, type: type, balance: balance);

  Future<void> addCategory(String name, double budget) =>
      _financeRepository.addCategory(familyId: familyId, name: name, icon: 'makan', budget: budget);

  Future<void> updateCategoryBudget(String categoryId, double newBudget) => _financeRepository.updateCategoryBudget(familyId, categoryId, newBudget);

  Future<void> renameCategory(String categoryId, String newName) => _financeRepository.renameCategory(familyId, categoryId, newName);

  Future<void> setCategoryWallet(String categoryId, String walletId) => _financeRepository.setCategoryWallet(familyId, categoryId, walletId);

  Future<void> addSubCategory(String categoryId, String name) => _financeRepository.addSubCategory(familyId, categoryId, name);

  Future<void> addGoal(String name, double target, DateTime? date) =>
      _financeRepository.addGoal(familyId: familyId, name: name, target: target, targetDate: date);

  Future<void> contributeGoal(GoalEntity g, double amount) =>
      _financeRepository.contributeGoal(familyId: familyId, goalId: g.id, amount: amount, byName: userName);

  Future<void> addInstallment({required String name, required String provider, required double monthly, required DateTime due, required int total, int paid = 0}) =>
      _financeRepository.addInstallment(familyId: familyId, name: name, provider: provider, monthlyAmount: monthly, nextDueDate: due, totalCount: total, paidCount: paid);

  Future<void> payInstallment(InstallmentEntity i) => _financeRepository.payInstallment(familyId, i);

  Future<void> addAsset(String name, double value, String kind, String note) =>
      _financeRepository.addAsset(familyId: familyId, name: name, value: value, kind: kind, note: note);

  Future<void> addWishlist(String name, double price) =>
      _financeRepository.addWishlistItem(familyId: familyId, name: name, price: price, uid: uid, byName: userName);

  Future<void> respondWishlist(WishlistItemEntity item, String response) => _financeRepository.respondWishlist(familyId, item.id, response, userName);

  Future<void> removeWishlist(WishlistItemEntity item) => _financeRepository.removeWishlistItem(familyId, item.id);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
