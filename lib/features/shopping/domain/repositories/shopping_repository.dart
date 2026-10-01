import '../entities/shopping_item_entity.dart';

abstract class ShoppingRepository {
  Stream<List<ShoppingItemEntity>> watchItems(String familyId);
  Future<void> addItem({required String familyId, required String name, required String place, double lastPrice = 0, required String uid, required String byName});
  Future<void> setChecked(String familyId, String itemId, bool checked);
  Future<void> updatePrice(String familyId, String itemId, double price);

  /// Mengosongkan centang setelah belanja dicatat, harga terakhir tetap disimpan.
  Future<void> clearChecked(String familyId, List<String> itemIds);
  Future<void> deleteItem(String familyId, String itemId);
}
