import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category_entity.dart';
import '../../domain/entities/money_extras_entity.dart';
import '../../domain/entities/monthly_report_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/entities/wallet_transfer_entity.dart';

class FinanceRemoteDataSource {
  final FirebaseFirestore _firestore;

  FinanceRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) => _firestore.collection('families').doc(familyId);

  CollectionReference<Map<String, dynamic>> _col(String familyId, String name) => _familyDoc(familyId).collection(name);

  static String _day(DateTime d) => d.toIso8601String().split('T').first;

  Stream<List<WalletEntity>> watchWallets(String familyId) {
    return _col(familyId, 'wallets').snapshots().map((snapshot) {
      final wallets = snapshot.docs.map((doc) {
        final data = doc.data();
        return WalletEntity(
          id: doc.id,
          name: (data['name'] as String?) ?? '',
          subtitle: (data['subtitle'] as String?) ?? '',
          type: (data['type'] as String?) ?? '',
          balance: (data['balance'] as num?)?.toDouble() ?? 0,
          isDefault: (data['isDefault'] as bool?) ?? false,
          order: (data['order'] as num?)?.toInt() ?? 0,
        );
      }).toList();
      wallets.sort((a, b) => a.order.compareTo(b.order));
      return wallets;
    });
  }

  Stream<List<CategoryEntity>> watchCategories(String familyId) {
    return _col(familyId, 'categories').snapshots().map((snapshot) {
      final categories = snapshot.docs.map((doc) {
        final data = doc.data();
        final subMap = (data['subCategories'] as Map<String, dynamic>?) ?? {};
        final subCategories = subMap.entries.map((e) {
          final subData = e.value as Map<String, dynamic>;
          return SubCategoryEntity(
            id: e.key,
            name: (subData['name'] as String?) ?? '',
            amount: (subData['amount'] as num?)?.toDouble() ?? 0,
          );
        }).toList();
        return CategoryEntity(
          id: doc.id,
          name: (data['name'] as String?) ?? '',
          icon: (data['icon'] as String?) ?? '',
          color: (data['color'] as String?) ?? '#8A8178',
          budgetAmount: (data['budgetAmount'] as num?)?.toDouble() ?? 0,
          spentAmount: (data['spentAmount'] as num?)?.toDouble() ?? 0,
          walletId: (data['walletId'] as String?) ?? '',
          order: (data['order'] as num?)?.toInt() ?? 0,
          subCategories: subCategories,
        );
      }).toList();
      categories.sort((a, b) => a.order.compareTo(b.order));
      return categories;
    });
  }

  Stream<List<TransactionEntity>> watchTransactions(String familyId) {
    return _col(familyId, 'transactions').snapshots().map((snapshot) {
      final transactions = snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionEntity(
          id: doc.id,
          title: (data['title'] as String?) ?? '',
          categoryId: data['categoryId'] as String?,
          walletId: (data['walletId'] as String?) ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          type: (data['type'] as String?) ?? '',
          date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
          createdByName: data['createdByName'] as String?,
        );
      }).toList();
      transactions.sort((a, b) => b.date.compareTo(a.date));
      return transactions;
    });
  }

  Stream<List<WalletTransferEntity>> watchTransfers(String familyId) {
    return _col(familyId, 'walletTransfers').snapshots().map((snapshot) {
      final transfers = snapshot.docs.map((doc) {
        final data = doc.data();
        return WalletTransferEntity(
          id: doc.id,
          fromWalletId: (data['fromWalletId'] as String?) ?? '',
          toWalletId: (data['toWalletId'] as String?) ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          adminFee: (data['adminFee'] as num?)?.toDouble() ?? 0,
          date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();
      transfers.sort((a, b) => b.date.compareTo(a.date));
      return transfers;
    });
  }

  Stream<MonthlyReportEntity?> watchMonthlyReport(String familyId, String monthKey) {
    return _col(familyId, 'monthlyReports').doc(monthKey).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      final trendMap = (data['trend6Months'] as Map<String, dynamic>?) ?? {};
      return MonthlyReportEntity(
        monthKey: monthKey,
        totalWealth: (data['totalWealth'] as num?)?.toDouble() ?? 0,
        cash: (data['cash'] as num?)?.toDouble() ?? 0,
        investment: (data['investment'] as num?)?.toDouble() ?? 0,
        income: (data['income'] as num?)?.toDouble() ?? 0,
        expense: (data['expense'] as num?)?.toDouble() ?? 0,
        investmentContribution: (data['investmentContribution'] as num?)?.toDouble() ?? 0,
        endingBalance: (data['endingBalance'] as num?)?.toDouble() ?? 0,
        wealthChangePercent: (data['wealthChangePercent'] as num?)?.toDouble() ?? 0,
        trend6Months: trendMap.map((k, v) => MapEntry(k, (v as num).toDouble())),
      );
    });
  }

  Stream<String> watchFamilyName(String familyId) {
    return _familyDoc(familyId).snapshots().map((doc) => (doc.data()?['name'] as String?) ?? '');
  }

  Stream<List<GoalEntity>> watchGoals(String familyId) {
    return _col(familyId, 'goals').snapshots().map((s) => s.docs.map((doc) {
          final d = doc.data();
          return GoalEntity(
            id: doc.id,
            name: (d['name'] as String?) ?? '',
            icon: (d['icon'] as String?) ?? 'piggy',
            targetAmount: (d['targetAmount'] as num?)?.toDouble() ?? 0,
            currentAmount: (d['currentAmount'] as num?)?.toDouble() ?? 0,
            lastContribution: (d['lastContribution'] as num?)?.toDouble() ?? 0,
            lastContributorName: d['lastContributorName'] as String?,
            lastDate: DateTime.tryParse((d['date'] as String?) ?? ''),
            targetDate: DateTime.tryParse((d['targetDate'] as String?) ?? ''),
            note: (d['note'] as String?) ?? '',
          );
        }).toList());
  }

  Stream<List<InstallmentEntity>> watchInstallments(String familyId) {
    return _col(familyId, 'installments').snapshots().map((s) {
      final list = s.docs.map((doc) {
        final d = doc.data();
        return InstallmentEntity(
          id: doc.id,
          name: (d['name'] as String?) ?? '',
          provider: (d['provider'] as String?) ?? '',
          icon: (d['icon'] as String?) ?? 'card',
          monthlyAmount: (d['monthlyAmount'] as num?)?.toDouble() ?? 0,
          nextDueDate: DateTime.tryParse((d['nextDueDate'] as String?) ?? '') ?? DateTime.now(),
          paidCount: (d['paidCount'] as num?)?.toInt() ?? 0,
          totalCount: (d['totalCount'] as num?)?.toInt() ?? 1,
        );
      }).where((i) => i.paidCount < i.totalCount).toList();
      list.sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
      return list;
    });
  }

  Stream<List<AssetEntity>> watchAssets(String familyId) {
    return _col(familyId, 'assets').snapshots().map((s) => s.docs.map((doc) {
          final d = doc.data();
          return AssetEntity(
            id: doc.id,
            name: (d['name'] as String?) ?? '',
            note: (d['note'] as String?) ?? '',
            value: (d['value'] as num?)?.toDouble() ?? 0,
            kind: (d['kind'] as String?) ?? 'aset',
            icon: (d['icon'] as String?) ?? 'coins',
          );
        }).toList());
  }

  Stream<List<WishlistItemEntity>> watchWishlist(String familyId) {
    return _col(familyId, 'wishlist').snapshots().map((s) {
      final list = s.docs.map((doc) {
        final d = doc.data();
        return WishlistItemEntity(
          id: doc.id,
          name: (d['name'] as String?) ?? '',
          price: (d['price'] as num?)?.toDouble() ?? 0,
          createdAt: DateTime.tryParse((d['createdAt'] as String?) ?? '') ?? DateTime.now(),
          addedByUid: (d['addedByUid'] as String?) ?? '',
          addedByName: (d['addedByName'] as String?) ?? '',
          response: d['response'] as String?,
          responseByName: d['responseByName'] as String?,
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> transferBetweenWallets({
    required String familyId,
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    required double adminFee,
    required DateTime date,
    String? adminFeeCategoryId,
  }) async {
    final fromRef = _col(familyId, 'wallets').doc(fromWalletId);
    final toRef = _col(familyId, 'wallets').doc(toWalletId);
    final transferRef = _col(familyId, 'walletTransfers').doc();
    final feeCategoryRef = adminFeeCategoryId != null && adminFee > 0 ? _col(familyId, 'categories').doc(adminFeeCategoryId) : null;

    await _firestore.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      final toSnap = await tx.get(toRef);
      final feeSnap = feeCategoryRef != null ? await tx.get(feeCategoryRef) : null;
      final fromBalance = (fromSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
      final toBalance = (toSnap.data()?['balance'] as num?)?.toDouble() ?? 0;

      tx.update(fromRef, {'balance': fromBalance - amount - adminFee});
      tx.update(toRef, {'balance': toBalance + amount});
      tx.set(transferRef, {'fromWalletId': fromWalletId, 'toWalletId': toWalletId, 'amount': amount, 'adminFee': adminFee, 'date': _day(date)});
      if (feeCategoryRef != null && feeSnap != null) {
        final spent = (feeSnap.data()?['spentAmount'] as num?)?.toDouble() ?? 0;
        tx.update(feeCategoryRef, {'spentAmount': spent + adminFee});
      }
    });
  }

  /// Mencatat transaksi sekaligus memperbarui saldo dompet dan pemakaian amplop.
  Future<void> addTransaction({
    required String familyId,
    required String title,
    required double amount,
    required String type,
    required String walletId,
    String? categoryId,
    required DateTime date,
    required String createdByName,
  }) async {
    final walletRef = _col(familyId, 'wallets').doc(walletId);
    final categoryRef = categoryId != null && type == 'expense' ? _col(familyId, 'categories').doc(categoryId) : null;
    final txRef = _col(familyId, 'transactions').doc();
    final signed = type == 'expense' ? -amount.abs() : amount.abs();

    await _firestore.runTransaction((tx) async {
      final walletSnap = await tx.get(walletRef);
      final categorySnap = categoryRef != null ? await tx.get(categoryRef) : null;
      final balance = (walletSnap.data()?['balance'] as num?)?.toDouble() ?? 0;
      tx.update(walletRef, {'balance': balance + signed});
      if (categoryRef != null && categorySnap != null) {
        final spent = (categorySnap.data()?['spentAmount'] as num?)?.toDouble() ?? 0;
        tx.update(categoryRef, {'spentAmount': spent + amount.abs()});
      }
      tx.set(txRef, {
        'title': title,
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': signed,
        'type': type,
        'date': _day(date),
        'createdByName': createdByName,
      });
    });
  }

  Future<void> addWallet({required String familyId, required String name, required String type, required double balance}) {
    return _col(familyId, 'wallets').add({
      'name': name,
      'subtitle': '',
      'type': type,
      'balance': balance,
      'isDefault': false,
      'order': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> addCategory({required String familyId, required String name, required String icon, required double budget}) {
    return _col(familyId, 'categories').add({
      'name': name,
      'icon': icon,
      'color': '#2C6B5A',
      'budgetAmount': budget,
      'spentAmount': 0,
      'walletId': '',
      'order': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });
  }

  Future<void> updateCategoryBudget(String familyId, String categoryId, double newBudget) =>
      _col(familyId, 'categories').doc(categoryId).update({'budgetAmount': newBudget});

  Future<void> renameCategory(String familyId, String categoryId, String newName) =>
      _col(familyId, 'categories').doc(categoryId).update({'name': newName});

  Future<void> setCategoryWallet(String familyId, String categoryId, String walletId) =>
      _col(familyId, 'categories').doc(categoryId).update({'walletId': walletId});

  Future<void> addSubCategory(String familyId, String categoryId, String name) {
    final id = 'sub_${DateTime.now().millisecondsSinceEpoch}';
    return _col(familyId, 'categories').doc(categoryId).set({
      'subCategories': {
        id: {'name': name, 'amount': 0},
      },
    }, SetOptions(merge: true));
  }

  Future<void> addGoal({required String familyId, required String name, required double target, DateTime? targetDate, String icon = 'piggy'}) {
    return _col(familyId, 'goals').add({
      'name': name,
      'icon': icon,
      'targetAmount': target,
      'currentAmount': 0,
      'lastContribution': 0,
      if (targetDate != null) 'targetDate': _day(targetDate),
    });
  }

  Future<void> contributeGoal({required String familyId, required String goalId, required double amount, required String byName}) {
    return _col(familyId, 'goals').doc(goalId).update({
      'currentAmount': FieldValue.increment(amount),
      'lastContribution': amount,
      'lastContributorName': byName,
      'date': _day(DateTime.now()),
    });
  }

  Future<void> addInstallment({
    required String familyId,
    required String name,
    required String provider,
    required double monthlyAmount,
    required DateTime nextDueDate,
    required int totalCount,
    int paidCount = 0,
  }) {
    return _col(familyId, 'installments').add({
      'name': name,
      'provider': provider,
      'monthlyAmount': monthlyAmount,
      'nextDueDate': _day(nextDueDate),
      'paidCount': paidCount,
      'totalCount': totalCount,
    });
  }

  Future<void> payInstallment(String familyId, InstallmentEntity i) {
    final next = DateTime(i.nextDueDate.year, i.nextDueDate.month + 1, i.nextDueDate.day);
    return _col(familyId, 'installments').doc(i.id).update({'paidCount': i.paidCount + 1, 'nextDueDate': _day(next)});
  }

  Future<void> addAsset({required String familyId, required String name, required double value, required String kind, String note = ''}) {
    return _col(familyId, 'assets').add({'name': name, 'value': value, 'kind': kind, 'note': note});
  }

  Future<void> addWishlistItem({required String familyId, required String name, required double price, required String uid, required String byName}) {
    return _col(familyId, 'wishlist').add({
      'name': name,
      'price': price,
      'createdAt': DateTime.now().toIso8601String(),
      'addedByUid': uid,
      'addedByName': byName,
    });
  }

  Future<void> respondWishlist(String familyId, String itemId, String response, String byName) =>
      _col(familyId, 'wishlist').doc(itemId).update({'response': response, 'responseByName': byName});

  Future<void> removeWishlistItem(String familyId, String itemId) => _col(familyId, 'wishlist').doc(itemId).delete();
}
