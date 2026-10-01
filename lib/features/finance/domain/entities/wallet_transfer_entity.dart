class WalletTransferEntity {
  final String id;
  final String fromWalletId;
  final String toWalletId;
  final double amount;
  final double adminFee;
  final DateTime date;

  const WalletTransferEntity({
    required this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.adminFee,
    required this.date,
  });
}
