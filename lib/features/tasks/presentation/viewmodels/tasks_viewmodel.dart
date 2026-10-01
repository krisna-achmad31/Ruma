import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/format.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../settings/domain/entities/family_info_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../together/domain/repositories/together_repository.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../../../../core/l10n/app_locale.dart';

/// Urusan rumah tanpa skor: siapa yang ingat, siapa yang kerjakan, dan saling bantu.
class TasksViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final SettingsRepository _settingsRepository;
  final TogetherRepository _togetherRepository;
  final HomeRepository _homeRepository;
  final String familyId;
  final String uid;
  final String userName;

  StreamSubscription<List<TaskEntity>>? _tasksSub;
  StreamSubscription<List<MemberEntity>>? _membersSub;

  List<TaskEntity> tasks = [];
  List<MemberEntity> members = [];
  int segment = 0;

  TasksViewModel({
    required this._taskRepository,
    required this._settingsRepository,
    required this._togetherRepository,
    required this._homeRepository,
    required this.familyId,
    required this.uid,
    required this.userName,
  }) {
    _tasksSub = _taskRepository.watchTasks(familyId).listen((v) {
      tasks = v;
      notifyListeners();
    });
    _membersSub = _settingsRepository.watchMembers(familyId).listen((v) {
      members = v;
      notifyListeners();
    });
  }

  MemberEntity? get partner {
    for (final m in members) {
      if (m.uid != uid) return m;
    }
    return null;
  }

  String get partnerName => partner?.name.split(' ').first ?? tr('Pasangan');

  void setSegment(int i) {
    segment = i;
    notifyListeners();
  }

  /// Hal-hal yang diingat pasangan minggu ini, supaya kerja yang tak terlihat jadi terlihat.
  List<TaskEntity> get invisibleWork {
    final p = partner;
    if (p == null) return [];
    final since = DateTime.now().subtract(const Duration(days: 7));
    return tasks.where((t) => t.thinkerUid == p.uid && t.createdAt.isAfter(since)).take(4).toList();
  }

  List<TaskEntity> get _visible {
    switch (segment) {
      case 1:
        return tasks.where((t) => t.routine && !t.isDone).toList();
      case 2:
        return tasks.where((t) => t.isDone).toList();
      default:
        final today = dateOnly(DateTime.now());
        final start = today.subtract(const Duration(days: 1));
        final end = today.add(const Duration(days: 7));
        return tasks.where((t) {
          if (t.dueDate == null) return !t.isDone;
          final d = dateOnly(t.dueDate!);
          if (t.isDone) return !d.isBefore(start) && !d.isAfter(end);
          return !d.isAfter(end);
        }).toList();
    }
  }

  /// Urusan dikelompokkan per hari: "Hari ini", "Besok", "Sabtu", atau "Tanpa tanggal".
  Map<String, List<TaskEntity>> get grouped {
    final map = <String, List<TaskEntity>>{};
    for (final t in _visible) {
      final key = t.dueDate == null ? tr('Tanpa tanggal') : relativeDayLabel(t.dueDate!);
      map.putIfAbsent(key, () => []).add(t);
    }
    return map;
  }

  bool isMe(String? memberUid) => memberUid == uid;

  String firstNameOf(String? name) => (name ?? '').split(' ').first;

  Future<void> toggle(TaskEntity t) => _taskRepository.setDone(familyId, t.id, !t.isDone);

  Future<void> takeOver(TaskEntity t) => _taskRepository.assignDoer(familyId, t.id, uid: uid, name: userName);

  Future<void> delete(TaskEntity t) => _taskRepository.deleteTask(familyId, t.id);

  Future<void> addTask({required String title, required String doer, DateTime? dueDate, bool routine = false}) async {
    final p = partner;
    String? doerUid;
    String? doerName;
    var together = false;
    if (doer == 'me') {
      doerUid = uid;
      doerName = userName;
    } else if (doer == 'partner' && p != null) {
      doerUid = p.uid;
      doerName = p.name;
    } else if (doer == 'together') {
      together = true;
    }
    await _taskRepository.addTask(
      familyId: familyId,
      title: title,
      icon: guessTaskIcon(title),
      thinkerUid: uid,
      thinkerName: userName,
      doerUid: doerUid,
      doerName: doerName,
      together: together,
      dueDate: dueDate,
      routine: routine,
    );
    if (doer == 'none') {
      await _homeRepository.addNotification(
        familyId: familyId,
        icon: 'wrench',
        title: tr('{0} belum ada yang ambil', [title]),
        subtitle: tr('{0} yang ingat', [userName.split(' ').first]),
        kind: 'untukmu',
        route: '/urusan',
        fromUid: uid,
      );
    }
  }

  /// Ucapan terima kasih masuk ke jurnal keluarga dan notifikasi pasangan.
  Future<void> sendThanks(String message) async {
    await _togetherRepository.addJournalEntry(
      familyId: familyId,
      authorUid: uid,
      authorName: userName,
      title: message,
      text: tr('Makasih dari {0}.', [userName.split(' ').first]),
      type: 'makasih',
    );
    await _homeRepository.addNotification(
      familyId: familyId,
      icon: 'thanks',
      title: tr('{0} bilang makasih', [userName.split(' ').first]),
      subtitle: message,
      kind: 'untukmu',
      route: '/together/journal',
      fromUid: uid,
    );
  }

  @override
  void dispose() {
    _tasksSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}
