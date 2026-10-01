import '../entities/task_entity.dart';

abstract class TaskRepository {
  Stream<List<TaskEntity>> watchTasks(String familyId);

  Future<void> addTask({
    required String familyId,
    required String title,
    required String icon,
    required String thinkerUid,
    required String thinkerName,
    String? doerUid,
    String? doerName,
    bool together = false,
    DateTime? dueDate,
    String? time,
    bool routine = false,
  });

  Future<void> setDone(String familyId, String taskId, bool isDone);

  Future<void> assignDoer(String familyId, String taskId, {String? uid, String? name, bool together = false});

  Future<void> deleteTask(String familyId, String taskId);
}
