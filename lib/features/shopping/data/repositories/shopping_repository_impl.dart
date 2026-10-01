import '../../domain/entities/shopping_item_entity.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../datasources/shopping_remote_datasource.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  final ShoppingRemoteDataSource _remote;

  ShoppingRepositoryImpl(this._remote);

  @override
  Stream<List<ShoppingItemEntity>> watchItems(String familyId) => _remote.watchItems(familyId);

  @override
  Future<void> addItem({required String familyId, required String name, required String place, double lastPrice = 0, required String uid, required String byName}) =>
      _remote.addItem(familyId: familyId, name: name, place: place, lastPrice: lastPrice, uid: uid, byName: byName);

  @override
  Future<void> setChecked(String familyId, String itemId, bool checked) => _remote.setChecked(familyId, itemId, checked);

  @override
  Future<void> updatePrice(String familyId, String itemId, double price) => _remote.updatePrice(familyId, itemId, price);

  @override
  Future<void> clearChecked(String familyId, List<String> itemIds) => _remote.clearChecked(familyId, itemIds);

  @override
  Future<void> deleteItem(String familyId, String itemId) => _remote.deleteItem(familyId, itemId);
}
