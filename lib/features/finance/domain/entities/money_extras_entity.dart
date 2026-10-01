/// Target tabungan (koleksi goals).
class GoalEntity {
  final String id;
  final String name;
  final String icon;
  final double targetAmount;
  final double currentAmount;
  final double lastContribution;
  final String? lastContributorName;
  final DateTime? lastDate;
  final DateTime? targetDate;
  final String note;

  const GoalEntity({
    required this.id,
    required this.name,
    this.icon = 'piggy',
    required this.targetAmount,
    required this.currentAmount,
    this.lastContribution = 0,
    this.lastContributorName,
    this.lastDate,
    this.targetDate,
    this.note = '',
  });

  double get progress => targetAmount <= 0 ? 0 : currentAmount / targetAmount;
}

/// Cicilan atau paylater.
class InstallmentEntity {
  final String id;
  final String name;
  final String provider;
  final String icon;
  final double monthlyAmount;
  final DateTime nextDueDate;
  final int paidCount;
  final int totalCount;

  const InstallmentEntity({
    required this.id,
    required this.name,
    required this.provider,
    this.icon = 'card',
    required this.monthlyAmount,
    required this.nextDueDate,
    required this.paidCount,
    required this.totalCount,
  });

  double get progress => totalCount <= 0 ? 0 : paidCount / totalCount;
  double get remaining => (totalCount - paidCount) * monthlyAmount;
}

/// Aset, utang, atau piutang.
class AssetEntity {
  final String id;
  final String name;
  final String note;
  final double value;

  /// 'aset', 'utang', atau 'piutang'.
  final String kind;
  final String icon;

  const AssetEntity({required this.id, required this.name, this.note = '', required this.value, required this.kind, this.icon = 'coins'});
}

/// Barang yang ingin dibeli, ditahan 48 jam dulu.
class WishlistItemEntity {
  final String id;
  final String name;
  final double price;
  final DateTime createdAt;
  final String addedByUid;
  final String addedByName;
  final String? response;
  final String? responseByName;

  const WishlistItemEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.createdAt,
    required this.addedByUid,
    required this.addedByName,
    this.response,
    this.responseByName,
  });

  static const holdDuration = Duration(hours: 48);

  Duration remaining(DateTime now) {
    final left = createdAt.add(holdDuration).difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  double holdProgress(DateTime now) {
    final elapsed = now.difference(createdAt).inMinutes / holdDuration.inMinutes;
    return elapsed.clamp(0.0, 1.0);
  }
}
