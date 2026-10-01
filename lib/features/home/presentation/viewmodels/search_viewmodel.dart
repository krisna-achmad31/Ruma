import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../finance/domain/entities/category_entity.dart';
import '../../../finance/domain/entities/transaction_entity.dart';
import '../../../finance/domain/entities/wallet_entity.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../finance/domain/usecases/parse_quick_entry.dart';
import '../../../settings/domain/entities/family_info_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/repositories/task_repository.dart';

/// Pencarian lintas modul, sekaligus tempat catat cepat dengan kalimat biasa.
class SearchViewModel extends ChangeNotifier {
  final FinanceRepository _financeRepository;
  final TaskRepository _taskRepository;
  final SettingsRepository _settingsRepository;
  final String familyId;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  List<TransactionEntity> transactions = [];
  List<CategoryEntity> categories = [];
  List<WalletEntity> wallets = [];
  List<TaskEntity> tasks = [];
  List<VaultItemEntity> vault = [];
  String query = '';

  SearchViewModel({
    required this._financeRepository,
    required this._taskRepository,
    required this._settingsRepository,
    required this.familyId,
    required this.userName,
  }) {
    _subs.addAll([
      _financeRepository.watchTransactions(familyId).listen((v) => _set(() => transactions = v)),
      _financeRepository.watchCategories(familyId).listen((v) => _set(() => categories = v)),
      _financeRepository.watchWallets(familyId).listen((v) => _set(() => wallets = v)),
      _taskRepository.watchTasks(familyId).listen((v) => _set(() => tasks = v)),
      _settingsRepository.watchVault(familyId).listen((v) => _set(() => vault = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    notifyListeners();
  }

  void setQuery(String q) => _set(() => query = q.trim().toLowerCase());

  bool _match(String s) => query.isNotEmpty && s.toLowerCase().contains(query);

  List<TransactionEntity> get transactionResults => transactions.where((t) => _match(t.title)).take(5).toList();
  List<TaskEntity> get taskResults => tasks.where((t) => _match(t.title)).take(5).toList();
  List<VaultItemEntity> get vaultResults => vault.where((v) => _match(v.title)).take(5).toList();

  CategoryEntity? categoryOf(String? id) => categories.where((c) => c.id == id).firstOrNull;

  /// Kalimat yang bisa langsung dicatat sebagai transaksi, kalau ada nominalnya.
  QuickEntry? get quickEntry => query.isEmpty ? null : ParseQuickEntry()(query, wallets: wallets, categories: categories);

  Future<void> recordQuickEntry() async {
    final e = quickEntry;
    if (e == null || e.walletId == null) return;
    await _financeRepository.addTransaction(
      familyId: familyId,
      title: e.title,
      amount: e.amount,
      type: e.isIncome ? 'income' : 'expense',
      walletId: e.walletId!,
      categoryId: e.categoryId,
      date: DateTime.now(),
      createdByName: userName,
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
