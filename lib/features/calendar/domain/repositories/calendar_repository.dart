import '../entities/calendar_event_entity.dart';
import '../entities/maintenance_item_entity.dart';

abstract class CalendarRepository {
  Stream<List<CalendarEventEntity>> watchEvents(String familyId);
  Stream<List<MaintenanceItemEntity>> watchMaintenanceItems(String familyId);
  Stream<String> watchFamilyName(String familyId);
  Future<void> setEventDone(String familyId, String eventId, bool isDone);
  Future<void> addEvent({required String familyId, required String title, required String category, required DateTime date});
  Future<void> addMaintenanceItem({
    required String familyId,
    required String name,
    required String type,
    required String note,
    required DateTime nextServiceDate,
    required double estimatedCost,
  });

  /// Menandai servis selesai lalu menjadwalkan ulang sesuai jarak hari yang diberikan.
  Future<void> completeMaintenance(String familyId, String itemId, DateTime nextDate);
}
