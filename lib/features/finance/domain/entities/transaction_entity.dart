class TransactionEntity {
  final String id;
  final String title;
  final String? categoryId;
  final String walletId;
  final double amount;

  /// 'income' atau 'expense'.
  final String type;
  final DateTime date;
  final String? createdByName;

  const TransactionEntity({
    required this.id,
    required this.title,
    this.categoryId,
    required this.walletId,
    required this.amount,
    required this.type,
    required this.date,
    this.createdByName,
  });

  bool get isIncome => type == 'income';
}
