import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/agenda_item_entity.dart';
import '../../domain/entities/family_summary_entity.dart';
import '../../domain/entities/notification_entity.dart';

class HomeRemoteDataSource {
  final FirebaseFirestore _firestore;

  HomeRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<FamilySummaryEntity> watchFamilySummary(String familyId) {
    return _firestore.collection('families').doc(familyId).snapshots().map((doc) {
      final data = doc.data() ?? {};
      return FamilySummaryEntity(
        name: (data['name'] as String?) ?? '',
        location: (data['location'] as String?) ?? '',
        lifeStage: (data['lifeStage'] as String?) ?? '',
      );
    });
  }

  Stream<List<AgendaItemEntity>> watchTodayAgenda(String familyId) {
    return _calendarEventsCollection(familyId).snapshots().map((snapshot) {
      final today = DateTime.now();
      return _mapDocsToAgenda(snapshot.docs)
          .where((item) => _isSameDay(item.date, today))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Stream<List<AgendaItemEntity>> watchWeekAgenda(String familyId) {
    return _calendarEventsCollection(familyId).snapshots().map((snapshot) {
      final today = _dateOnly(DateTime.now());
      final weekEnd = today.add(const Duration(days: 6));
      return _mapDocsToAgenda(snapshot.docs)
          .where((item) {
            final d = _dateOnly(item.date);
            return !d.isBefore(today) && !d.isAfter(weekEnd);
          })
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  Stream<double> watchMonthlyBalance(String familyId) {
    return _firestore
        .collection('families')
        .doc(familyId)
        .collection('transactions')
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dateStr = data['date'] as String?;
        if (dateStr == null) continue;
        final date = DateTime.tryParse(dateStr);
        if (date == null || date.year != now.year || date.month != now.month) continue;
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    });
  }

  Stream<List<NotificationEntity>> watchNotifications(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('notifications').snapshots().map((s) {
      final list = s.docs.map((doc) {
        final d = doc.data();
        return NotificationEntity(
          id: doc.id,
          icon: (d['icon'] as String?) ?? 'bell',
          title: (d['title'] as String?) ?? '',
          subtitle: (d['subtitle'] as String?) ?? '',
          createdAt: DateTime.tryParse((d['createdAt'] as String?) ?? '') ?? DateTime.now(),
          isRead: (d['isRead'] as bool?) ?? false,
          kind: (d['kind'] as String?) ?? 'info',
          route: d['route'] as String?,
          fromUid: d['fromUid'] as String?,
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> markNotificationsRead(String familyId, List<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_firestore.collection('families').doc(familyId).collection('notifications').doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> addNotification({required String familyId, required String icon, required String title, String subtitle = '', String kind = 'info', String? route, String? fromUid}) {
    return _firestore.collection('families').doc(familyId).collection('notifications').add({
      'icon': icon,
      'title': title,
      'subtitle': subtitle,
      'kind': kind,
      'route': route,
      'fromUid': fromUid,
      'isRead': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> setAgendaDone(String familyId, String eventId, bool isDone) {
    return _calendarEventsCollection(familyId).doc(eventId).update({'isDone': isDone});
  }

  CollectionReference<Map<String, dynamic>> _calendarEventsCollection(String familyId) {
    return _firestore.collection('families').doc(familyId).collection('calendarEvents');
  }

  List<AgendaItemEntity> _mapDocsToAgenda(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      final dateStr = data['date'] as String? ?? '';
      return AgendaItemEntity(
        id: doc.id,
        title: (data['title'] as String?) ?? '',
        category: (data['category'] as String?) ?? '',
        date: DateTime.tryParse(dateStr) ?? DateTime.now(),
        isDone: (data['isDone'] as bool?) ?? false,
      );
    }).toList();
  }

  DateTime _dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
