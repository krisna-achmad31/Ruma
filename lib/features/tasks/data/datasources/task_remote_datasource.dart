import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/task_entity.dart';

class TaskRemoteDataSource {
  final FirebaseFirestore _firestore;

  TaskRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String familyId) =>
      _firestore.collection('families').doc(familyId).collection('tasks');

  Stream<List<TaskEntity>> watchTasks(String familyId) {
    return _tasks(familyId).snapshots().map((snapshot) {
      final tasks = snapshot.docs.map((doc) {
        final d = doc.data();
        return TaskEntity(
          id: doc.id,
          title: (d['title'] as String?) ?? '',
          icon: (d['icon'] as String?) ?? 'list',
          thinkerUid: (d['thinkerUid'] as String?) ?? '',
          thinkerName: (d['thinkerName'] as String?) ?? '',
          doerUid: d['doerUid'] as String?,
          doerName: d['doerName'] as String?,
          together: (d['together'] as bool?) ?? false,
          dueDate: DateTime.tryParse((d['dueDate'] as String?) ?? ''),
          time: d['time'] as String?,
          isDone: (d['isDone'] as bool?) ?? false,
          routine: (d['routine'] as bool?) ?? false,
          createdAt: DateTime.tryParse((d['createdAt'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();
      tasks.sort((a, b) => (a.dueDate ?? DateTime(2100)).compareTo(b.dueDate ?? DateTime(2100)));
      return tasks;
    });
  }

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
    return _tasks(familyId).add({
      'title': title,
      'icon': icon,
      'thinkerUid': thinkerUid,
      'thinkerName': thinkerName,
      'doerUid': doerUid,
      'doerName': doerName,
      'together': together,
      'dueDate': dueDate?.toIso8601String().split('T').first,
      'time': time,
      'isDone': false,
      'routine': routine,
      'createdAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setDone(String familyId, String taskId, bool isDone) =>
      _tasks(familyId).doc(taskId).update({'isDone': isDone});

  Future<void> assignDoer(String familyId, String taskId, {String? uid, String? name, bool together = false}) =>
      _tasks(familyId).doc(taskId).update({'doerUid': uid, 'doerName': name, 'together': together});

  Future<void> deleteTask(String familyId, String taskId) => _tasks(familyId).doc(taskId).delete();
}
