import '../../domain/entities/agenda_item_entity.dart';
import '../../domain/entities/family_summary_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;

  HomeRepositoryImpl(this._remoteDataSource);

  @override
  Stream<FamilySummaryEntity> watchFamilySummary(String familyId) {
    return _remoteDataSource.watchFamilySummary(familyId);
  }

  @override
  Stream<List<AgendaItemEntity>> watchTodayAgenda(String familyId) {
    return _remoteDataSource.watchTodayAgenda(familyId);
  }

  @override
  Stream<List<AgendaItemEntity>> watchWeekAgenda(String familyId) {
    return _remoteDataSource.watchWeekAgenda(familyId);
  }

  @override
  Stream<double> watchMonthlyBalance(String familyId) {
    return _remoteDataSource.watchMonthlyBalance(familyId);
  }

  @override
  Future<void> setAgendaDone(String familyId, String eventId, bool isDone) {
    return _remoteDataSource.setAgendaDone(familyId, eventId, isDone);
  }

  @override
  Stream<List<NotificationEntity>> watchNotifications(String familyId) => _remoteDataSource.watchNotifications(familyId);

  @override
  Future<void> markNotificationsRead(String familyId, List<String> ids) => _remoteDataSource.markNotificationsRead(familyId, ids);

  @override
  Future<void> addNotification({required String familyId, required String icon, required String title, String subtitle = '', String kind = 'info', String? route, String? fromUid}) =>
      _remoteDataSource.addNotification(familyId: familyId, icon: icon, title: title, subtitle: subtitle, kind: kind, route: route, fromUid: fromUid);
}
