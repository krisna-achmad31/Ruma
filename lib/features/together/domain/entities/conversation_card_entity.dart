class ConversationCardEntity {
  final String id;
  final String category;
  final int cardNumber;
  final String question;
  final String instruction;
  final bool isToday;
  final String? lastAnswer;
  final DateTime? answeredAt;

  const ConversationCardEntity({
    required this.id,
    required this.category,
    required this.cardNumber,
    required this.question,
    required this.instruction,
    required this.isToday,
    this.lastAnswer,
    this.answeredAt,
  });
}
