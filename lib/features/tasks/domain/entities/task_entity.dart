/// Satu urusan rumah. Punya dua peran: yang ingat (thinker) dan yang mengerjakan (doer).
class TaskEntity {
  final String id;
  final String title;
  final String icon;
  final String thinkerUid;
  final String thinkerName;
  final String? doerUid;
  final String? doerName;
  final bool together;
  final DateTime? dueDate;
  final String? time;
  final bool isDone;
  final bool routine;
  final DateTime createdAt;

  const TaskEntity({
    required this.id,
    required this.title,
    required this.icon,
    required this.thinkerUid,
    required this.thinkerName,
    this.doerUid,
    this.doerName,
    this.together = false,
    this.dueDate,
    this.time,
    this.isDone = false,
    this.routine = false,
    required this.createdAt,
  });

  bool get hasDoer => together || doerUid != null;
}
