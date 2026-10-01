import '../entities/agenda_item_entity.dart';
import '../entities/family_summary_entity.dart';
import '../entities/notification_entity.dart';

abstract class HomeRepository {
  Stream<FamilySummaryEntity> watchFamilySummary(String familyId);
  Stream<List<AgendaItemEntity>> watchTodayAgenda(String familyId);
  Stream<List<AgendaItemEntity>> watchWeekAgenda(String familyId);
  Stream<double> watchMonthlyBalance(String familyId);
  Stream<List<NotificationEntity>> watchNotifications(String familyId);
  Future<void> setAgendaDone(String familyId, String eventId, bool isDone);
  Future<void> markNotificationsRead(String familyId, List<String> ids);
  Future<void> addNotification({required String familyId, required String icon, required String title, String subtitle = '', String kind = 'info', String? route, String? fromUid});
}
