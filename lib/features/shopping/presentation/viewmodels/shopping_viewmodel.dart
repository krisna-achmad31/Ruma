import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../finance/domain/entities/category_entity.dart';
import '../../../finance/domain/entities/wallet_entity.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../finance/domain/usecases/parse_quick_entry.dart';
import '../../domain/entities/shopping_item_entity.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../../../../core/l10n/app_locale.dart';

class ShoppingViewModel extends ChangeNotifier {
  final ShoppingRepository _shoppingRepository;
  final FinanceRepository _financeRepository;
  final String familyId;
  final String uid;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  List<ShoppingItemEntity> items = [];
  List<CategoryEntity> categories = [];
  List<WalletEntity> wallets = [];

  ShoppingViewModel({
    required this._shoppingRepository,
    required this._financeRepository,
    required this.familyId,
    required this.uid,
    required this.userName,
  }) {
    _subs.addAll([
      _shoppingRepository.watchItems(familyId).listen((v) => _set(() => items = v)),
      _financeRepository.watchCategories(familyId).listen((v) => _set(() => categories = v)),
      _financeRepository.watchWallets(familyId).listen((v) => _set(() => wallets = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    notifyListeners();
  }

  Map<String, List<ShoppingItemEntity>> get byPlace {
    final map = <String, List<ShoppingItemEntity>>{};
    for (final i in items) {
      map.putIfAbsent(i.place, () => []).add(i);
    }
    return map;
  }

  List<ShoppingItemEntity> get checked => items.where((i) => i.isChecked).toList();
  double get checkedTotal => checked.fold(0.0, (s, i) => s + i.lastPrice);

  /// Amplop yang paling cocok untuk belanja harian.
  CategoryEntity? get groceryCategory {
    for (final key in ['makan', 'belanja', 'harian']) {
      final c = categories.where((c) => c.name.toLowerCase().contains(key)).firstOrNull;
      if (c != null) return c;
    }
    return categories.firstOrNull;
  }

  /// "telur 1 kg 28rb" jadi barang "Telur 1 kg" dengan harga Rp28.000.
  Future<void> addFromText(String text, String place) async {
    final price = ParseQuickEntry.parseAmount(text.toLowerCase()) ?? 0;
    var name = text;
    if (price > 0) {
      name = text.replaceAll(RegExp(r'\s*\d+(?:[.,]\d+)*\s*(rb|ribu|k|jt|juta)\b', caseSensitive: false), '').trim();
    }
    if (name.isEmpty) return;
    name = name[0].toUpperCase() + name.substring(1);
    await _shoppingRepository.addItem(familyId: familyId, name: name, place: place, lastPrice: price, uid: uid, byName: userName);
  }

  Future<void> toggle(ShoppingItemEntity i) => _shoppingRepository.setChecked(familyId, i.id, !i.isChecked);
  Future<void> setPrice(ShoppingItemEntity i, double price) => _shoppingRepository.updatePrice(familyId, i.id, price);
  Future<void> delete(ShoppingItemEntity i) => _shoppingRepository.deleteItem(familyId, i.id);

  /// Mencatat barang yang dicentang sebagai satu transaksi, lalu mengosongkannya dari daftar.
  Future<bool> recordChecked() async {
    final list = checked;
    final wallet = wallets.where((w) => w.isDefault).firstOrNull ?? wallets.where((w) => w.type != 'savings').firstOrNull;
    if (list.isEmpty || wallet == null) return false;
    await _financeRepository.addTransaction(
      familyId: familyId,
      title: tr('Belanja: {0}{1}', [list.map((i) => i.name).take(3).join(', '), list.length > 3 ? tr(', dan lainnya') : '']),
      amount: checkedTotal,
      type: 'expense',
      walletId: wallet.id,
      categoryId: groceryCategory?.id,
      date: DateTime.now(),
      createdByName: userName,
    );
    await _shoppingRepository.clearChecked(familyId, list.map((i) => i.id).toList());
    return true;
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
