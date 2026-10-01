import '../../domain/entities/category_entity.dart';
import '../../domain/entities/money_extras_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transfer_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource _remote;

  FinanceRepositoryImpl(this._remote);

  @override
  Stream<List<WalletEntity>> watchWallets(String familyId) => _remote.watchWallets(familyId);

  @override
  Stream<List<CategoryEntity>> watchCategories(String familyId) => _remote.watchCategories(familyId);

  @override
  Stream<List<TransactionEntity>> watchTransactions(String familyId) => _remote.watchTransactions(familyId);

  @override
  Stream<List<WalletTransferEntity>> watchTransfers(String familyId) => _remote.watchTransfers(familyId);

  @override
  Stream<MonthlyReportEntity?> watchMonthlyReport(String familyId, String monthKey) => _remote.watchMonthlyReport(familyId, monthKey);

  @override
  Stream<String> watchFamilyName(String familyId) => _remote.watchFamilyName(familyId);

  @override
  Stream<List<GoalEntity>> watchGoals(String familyId) => _remote.watchGoals(familyId);

  @override
  Stream<List<InstallmentEntity>> watchInstallments(String familyId) => _remote.watchInstallments(familyId);

  @override
  Stream<List<AssetEntity>> watchAssets(String familyId) => _remote.watchAssets(familyId);

  @override
  Stream<List<WishlistItemEntity>> watchWishlist(String familyId) => _remote.watchWishlist(familyId);

  @override
  Future<void> transferBetweenWallets({
    required String familyId,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required double adminFee,
    required DateTime date,
    String? adminFeeCategoryId,
  }) {
    return _remote.transferBetweenWallets(
      familyId: familyId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      amount: amount,
      adminFee: adminFee,
      date: date,
      adminFeeCategoryId: adminFeeCategoryId,
    );
  }

  @override
  Future<void> addTransaction({
    required String familyId,
    required String title,
    required double amount,
    required String type,
    required String walletId,
    String? categoryId,
    required DateTime date,
    required String createdByName,
  }) {
    return _remote.addTransaction(
      familyId: familyId,
      title: title,
      amount: amount,
      type: type,
      walletId: walletId,
      categoryId: categoryId,
      date: date,
      createdByName: createdByName,
    );
  }

  @override
  Future<void> addWallet({required String familyId, required String name, required String type, required double balance}) =>
      _remote.addWallet(familyId: familyId, name: name, type: type, balance: balance);

  @override
  Future<void> addCategory({required String familyId, required String name, required String icon, required double budget}) =>
      _remote.addCategory(familyId: familyId, name: name, icon: icon, budget: budget);

  @override
  Future<void> updateCategoryBudget(String familyId, String categoryId, double newBudget) =>
      _remote.updateCategoryBudget(familyId, categoryId, newBudget);

  @override
  Future<void> renameCategory(String familyId, String categoryId, String newName) => _remote.renameCategory(familyId, categoryId, newName);

  @override
  Future<void> setCategoryWallet(String familyId, String categoryId, String walletId) =>
      _remote.setCategoryWallet(familyId, categoryId, walletId);

  @override
  Future<void> addSubCategory(String familyId, String categoryId, String name) => _remote.addSubCategory(familyId, categoryId, name);

  @override
  Future<void> addGoal({required String familyId, required String name, required double target, DateTime? targetDate, String icon = 'piggy'}) =>
      _remote.addGoal(familyId: familyId, name: name, target: target, targetDate: targetDate, icon: icon);

  @override
  Future<void> contributeGoal({required String familyId, required String goalId, required double amount, required String byName}) =>
      _remote.contributeGoal(familyId: familyId, goalId: goalId, amount: amount, byName: byName);

  @override
  Future<void> addInstallment({
    required String familyId,
    required String name,
    required String provider,
    required double monthlyAmount,
    required DateTime nextDueDate,
    required int totalCount,
    int paidCount = 0,
  }) {
    return _remote.addInstallment(
      familyId: familyId,
      name: name,
      provider: provider,
      monthlyAmount: monthlyAmount,
      nextDueDate: nextDueDate,
      totalCount: totalCount,
      paidCount: paidCount,
    );
  }

  @override
  Future<void> payInstallment(String familyId, InstallmentEntity installment) => _remote.payInstallment(familyId, installment);

  @override
  Future<void> addAsset({required String familyId, required String name, required double value, required String kind, String note = ''}) =>
      _remote.addAsset(familyId: familyId, name: name, value: value, kind: kind, note: note);

  @override
  Future<void> addWishlistItem({required String familyId, required String name, required double price, required String uid, required String byName}) =>
      _remote.addWishlistItem(familyId: familyId, name: name, price: price, uid: uid, byName: byName);

  @override
  Future<void> respondWishlist(String familyId, String itemId, String response, String byName) =>
      _remote.respondWishlist(familyId, itemId, response, byName);

  @override
  Future<void> removeWishlistItem(String familyId, String itemId) => _remote.removeWishlistItem(familyId, itemId);
}
