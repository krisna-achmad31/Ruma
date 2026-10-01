import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/format.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../../core/l10n/app_locale.dart';

class NotificationsViewModel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  final String familyId;
  final String uid;

  StreamSubscription<List<NotificationEntity>>? _sub;
  List<NotificationEntity> notifications = [];
  int segment = 0;

  NotificationsViewModel({required this._homeRepository, required this.familyId, required this.uid}) {
    _sub = _homeRepository.watchNotifications(familyId).listen((v) {
      notifications = v.where((n) => n.fromUid != uid).toList();
      notifyListeners();
    });
  }

  void setSegment(int i) {
    segment = i;
    notifyListeners();
  }

  List<NotificationEntity> get visible {
    switch (segment) {
      case 0:
        return notifications.where((n) => n.kind == 'untukmu' && !n.isRead).toList();
      case 2:
        return notifications.where((n) => n.isRead).toList();
      default:
        return notifications;
    }
  }

  /// Dikelompokkan jadi "Hari ini", "Kemarin", atau tanggal.
  Map<String, List<NotificationEntity>> get grouped {
    final map = <String, List<NotificationEntity>>{};
    for (final n in visible) {
      final local = n.createdAt.toLocal();
      final key = relativeDayLabel(local);
      map.putIfAbsent(key == tr('Hari ini') || key == tr('Kemarin') ? key : formatShortDate(local), () => []).add(n);
    }
    return map;
  }

  String timeAgo(NotificationEntity n) {
    final diff = DateTime.now().difference(n.createdAt.toLocal());
    if (diff.inMinutes < 1) return 'barusan';
    if (diff.inMinutes < 60) return tr('{0} menit lalu', [diff.inMinutes]);
    if (diff.inHours < 24) return tr('{0} jam lalu', [diff.inHours]);
    return formatShortDate(n.createdAt.toLocal());
  }

  Future<void> markAllRead() => _homeRepository.markNotificationsRead(familyId, notifications.where((n) => !n.isRead).map((n) => n.id).toList());

  Future<void> markRead(NotificationEntity n) => _homeRepository.markNotificationsRead(familyId, [n.id]);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
