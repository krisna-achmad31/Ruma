class MaintenanceItemEntity {
  final String id;
  final String name;
  final String type;
  final String note;
  final String status;
  final DateTime nextServiceDate;
  final double estimatedCost;

  const MaintenanceItemEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.note,
    required this.status,
    required this.nextServiceDate,
    required this.estimatedCost,
  });
}
