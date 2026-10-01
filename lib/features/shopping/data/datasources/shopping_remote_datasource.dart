import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/shopping_item_entity.dart';

class ShoppingRemoteDataSource {
  final FirebaseFirestore _firestore;

  ShoppingRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _items(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('shoppingItems');

  Stream<List<ShoppingItemEntity>> watchItems(String familyId) {
    return _items(familyId).snapshots().map((s) {
      final list = s.docs.where((doc) => doc.data()['archived'] != true).map((doc) {
        final d = doc.data();
        return ShoppingItemEntity(
          id: doc.id,
          name: (d['name'] as String?) ?? '',
          place: (d['place'] as String?) ?? 'Lainnya',
          lastPrice: (d['lastPrice'] as num?)?.toDouble() ?? 0,
          note: d['note'] as String?,
          isChecked: (d['isChecked'] as bool?) ?? false,
          addedByUid: (d['addedByUid'] as String?) ?? '',
          addedByName: (d['addedByName'] as String?) ?? '',
        );
      }).toList();
      list.sort((a, b) => a.place.compareTo(b.place));
      return list;
    });
  }

  Future<void> addItem({required String familyId, required String name, required String place, double lastPrice = 0, required String uid, required String byName}) async {
    // Barang yang pernah dibeli dimunculkan lagi supaya harga terakhirnya ikut terbawa.
    final existing = await _items(familyId).where('nameKey', isEqualTo: name.toLowerCase().trim()).limit(1).get();
    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({'archived': false, 'isChecked': false, 'addedByUid': uid, 'addedByName': byName, 'place': place});
      return;
    }
    await _items(familyId).add({
      'nameKey': name.toLowerCase().trim(),
      'archived': false,
      'name': name,
      'place': place,
      'lastPrice': lastPrice,
      'isChecked': false,
      'addedByUid': uid,
      'addedByName': byName,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setChecked(String familyId, String itemId, bool checked) => _items(familyId).doc(itemId).update({'isChecked': checked});

  Future<void> updatePrice(String familyId, String itemId, double price) => _items(familyId).doc(itemId).update({'lastPrice': price});

  Future<void> clearChecked(String familyId, List<String> itemIds) async {
    final batch = _firestore.batch();
    for (final id in itemIds) {
      batch.update(_items(familyId).doc(id), {'isChecked': false, 'archived': true});
    }
    await batch.commit();
  }

  Future<void> deleteItem(String familyId, String itemId) => _items(familyId).doc(itemId).delete();
}
