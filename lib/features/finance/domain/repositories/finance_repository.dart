import '../entities/category_entity.dart';
import '../entities/money_extras_entity.dart';
import '../entities/monthly_report_entity.dart';
import '../entities/transaction_entity.dart';
import '../entities/wallet_entity.dart';
import '../entities/wallet_transfer_entity.dart';

abstract class FinanceRepository {
  Stream<List<WalletEntity>> watchWallets(String familyId);
  Stream<List<CategoryEntity>> watchCategories(String familyId);
  Stream<List<TransactionEntity>> watchTransactions(String familyId);
  Stream<List<WalletTransferEntity>> watchTransfers(String familyId);
  Stream<MonthlyReportEntity?> watchMonthlyReport(String familyId, String monthKey);
  Stream<String> watchFamilyName(String familyId);
  Stream<List<GoalEntity>> watchGoals(String familyId);
  Stream<List<InstallmentEntity>> watchInstallments(String familyId);
  Stream<List<AssetEntity>> watchAssets(String familyId);
  Stream<List<WishlistItemEntity>> watchWishlist(String familyId);

  Future<void> transferBetweenWallets({
    required String familyId,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required double adminFee,
    required DateTime date,
    String? adminFeeCategoryId,
  });

  Future<void> addTransaction({
    required String familyId,
    required String title,
    required double amount,
    required String type,
    required String walletId,
    String? categoryId,
    required DateTime date,
    required String createdByName,
  });

  Future<void> addWallet({required String familyId, required String name, required String type, required double balance});
  Future<void> addCategory({required String familyId, required String name, required String icon, required double budget});
  Future<void> updateCategoryBudget(String familyId, String categoryId, double newBudget);
  Future<void> renameCategory(String familyId, String categoryId, String newName);
  Future<void> setCategoryWallet(String familyId, String categoryId, String walletId);
  Future<void> addSubCategory(String familyId, String categoryId, String name);

  Future<void> addGoal({required String familyId, required String name, required double target, DateTime? targetDate, String icon = 'piggy'});
  Future<void> contributeGoal({required String familyId, required String goalId, required double amount, required String byName});

  Future<void> addInstallment({
    required String familyId,
    required String name,
    required String provider,
    required double monthlyAmount,
    required DateTime nextDueDate,
    required int totalCount,
    int paidCount = 0,
  });
  Future<void> payInstallment(String familyId, InstallmentEntity installment);

  Future<void> addAsset({required String familyId, required String name, required double value, required String kind, String note = ''});

  Future<void> addWishlistItem({required String familyId, required String name, required double price, required String uid, required String byName});
  Future<void> respondWishlist(String familyId, String itemId, String response, String byName);
  Future<void> removeWishlistItem(String familyId, String itemId);
}
