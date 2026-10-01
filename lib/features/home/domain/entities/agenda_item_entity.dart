class AgendaItemEntity {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final bool isDone;

  const AgendaItemEntity({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.isDone,
  });
}
