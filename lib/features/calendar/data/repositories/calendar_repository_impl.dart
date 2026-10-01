import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/entities/maintenance_item_entity.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../datasources/calendar_remote_datasource.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final CalendarRemoteDataSource _remoteDataSource;

  CalendarRepositoryImpl(this._remoteDataSource);

  @override
  Stream<List<CalendarEventEntity>> watchEvents(String familyId) {
    return _remoteDataSource.watchEvents(familyId);
  }

  @override
  Stream<List<MaintenanceItemEntity>> watchMaintenanceItems(String familyId) {
    return _remoteDataSource.watchMaintenanceItems(familyId);
  }

  @override
  Stream<String> watchFamilyName(String familyId) {
    return _remoteDataSource.watchFamilyName(familyId);
  }

  @override
  Future<void> setEventDone(String familyId, String eventId, bool isDone) {
    return _remoteDataSource.setEventDone(familyId, eventId, isDone);
  }

  @override
  Future<void> addEvent({required String familyId, required String title, required String category, required DateTime date}) =>
      _remoteDataSource.addEvent(familyId: familyId, title: title, category: category, date: date);

  @override
  Future<void> addMaintenanceItem({
    required String familyId,
    required String name,
    required String type,
    required String note,
    required DateTime nextServiceDate,
    required double estimatedCost,
  }) =>
      _remoteDataSource.addMaintenanceItem(familyId: familyId, name: name, type: type, note: note, nextServiceDate: nextServiceDate, estimatedCost: estimatedCost);

  @override
  Future<void> completeMaintenance(String familyId, String itemId, DateTime nextDate) => _remoteDataSource.completeMaintenance(familyId, itemId, nextDate);
}
