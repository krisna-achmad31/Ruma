class ShoppingItemEntity {
  final String id;
  final String name;

  /// Tempat belanja, misalnya Pasar atau Minimarket.
  final String place;
  final double lastPrice;
  final String? note;
  final bool isChecked;
  final String addedByUid;
  final String addedByName;

  const ShoppingItemEntity({
    required this.id,
    required this.name,
    required this.place,
    required this.lastPrice,
    this.note,
    required this.isChecked,
    required this.addedByUid,
    required this.addedByName,
  });
}
