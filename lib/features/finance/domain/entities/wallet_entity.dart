class WalletEntity {
  final String id;
  final String name;
  final String subtitle;
  final String type;
  final double balance;
  final bool isDefault;
  final int order;

  const WalletEntity({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.type,
    required this.balance,
    required this.isDefault,
    required this.order,
  });
}
