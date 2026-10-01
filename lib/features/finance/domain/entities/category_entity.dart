class SubCategoryEntity {
  final String id;
  final String name;
  final double amount;

  const SubCategoryEntity({required this.id, required this.name, required this.amount});
}

class CategoryEntity {
  final String id;
  final String name;
  final String icon;
  final String color;
  final double budgetAmount;
  final double spentAmount;
  final String walletId;
  final int order;
  final List<SubCategoryEntity> subCategories;

  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.budgetAmount,
    required this.spentAmount,
    required this.walletId,
    required this.order,
    required this.subCategories,
  });
}
