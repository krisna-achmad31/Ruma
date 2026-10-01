class MemberAnswer {
  final bool completed;
  final List<String?> answers;

  const MemberAnswer({required this.completed, required this.answers});
}

class ReflectionEntity {
  final String monthKey;
  final List<String> questions;
  final String status;
  final DateTime? openDate;
  final DateTime? closeDate;
  final Map<String, MemberAnswer> memberAnswers;

  const ReflectionEntity({
    required this.monthKey,
    required this.questions,
    required this.status,
    this.openDate,
    this.closeDate,
    required this.memberAnswers,
  });
}
