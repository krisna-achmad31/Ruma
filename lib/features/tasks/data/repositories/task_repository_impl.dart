import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remote;

  TaskRepositoryImpl(this._remote);

  @override
  Stream<List<TaskEntity>> watchTasks(String familyId) => _remote.watchTasks(familyId);

  @override
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
  }) {
    return _remote.addTask(
      familyId: familyId,
      title: title,
      icon: icon,
      thinkerUid: thinkerUid,
      thinkerName: thinkerName,
      doerUid: doerUid,
      doerName: doerName,
      together: together,
      dueDate: dueDate,
      time: time,
      routine: routine,
    );
  }

  @override
  Future<void> setDone(String familyId, String taskId, bool isDone) => _remote.setDone(familyId, taskId, isDone);

  @override
  Future<void> assignDoer(String familyId, String taskId, {String? uid, String? name, bool together = false}) =>
      _remote.assignDoer(familyId, taskId, uid: uid, name: name, together: together);

  @override
  Future<void> deleteTask(String familyId, String taskId) => _remote.deleteTask(familyId, taskId);
}
