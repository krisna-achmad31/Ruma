import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/entities/maintenance_item_entity.dart';

class CalendarRemoteDataSource {
  final FirebaseFirestore _firestore;

  CalendarRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<CalendarEventEntity>> watchEvents(String familyId) {
    return _familyDoc(familyId).collection('calendarEvents').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return CalendarEventEntity(
          id: doc.id,
          title: (data['title'] as String?) ?? '',
          category: (data['category'] as String?) ?? '',
          date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
          isDone: (data['isDone'] as bool?) ?? false,
        );
      }).toList();
    });
  }

  Stream<List<MaintenanceItemEntity>> watchMaintenanceItems(String familyId) {
    return _familyDoc(familyId).collection('maintenanceItems').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return MaintenanceItemEntity(
          id: doc.id,
          name: (data['name'] as String?) ?? '',
          type: (data['type'] as String?) ?? '',
          note: (data['note'] as String?) ?? '',
          status: (data['status'] as String?) ?? '',
          nextServiceDate: DateTime.tryParse((data['nextServiceDate'] as String?) ?? '') ?? DateTime.now(),
          estimatedCost: (data['estimatedCost'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    });
  }

  Stream<String> watchFamilyName(String familyId) {
    return _familyDoc(familyId).snapshots().map((doc) => (doc.data()?['name'] as String?) ?? '');
  }

  Future<void> setEventDone(String familyId, String eventId, bool isDone) {
    return _familyDoc(familyId).collection('calendarEvents').doc(eventId).update({'isDone': isDone});
  }

  Future<void> addEvent({required String familyId, required String title, required String category, required DateTime date}) {
    return _familyDoc(familyId).collection('calendarEvents').add({
      'title': title,
      'category': category,
      'date': date.toIso8601String().split('T').first,
      'isDone': false,
    });
  }

  Future<void> addMaintenanceItem({
    required String familyId,
    required String name,
    required String type,
    required String note,
    required DateTime nextServiceDate,
    required double estimatedCost,
  }) {
    return _familyDoc(familyId).collection('maintenanceItems').add({
      'name': name,
      'type': type,
      'note': note,
      'status': '',
      'nextServiceDate': nextServiceDate.toIso8601String().split('T').first,
      'estimatedCost': estimatedCost,
    });
  }

  Future<void> completeMaintenance(String familyId, String itemId, DateTime nextDate) {
    return _familyDoc(familyId).collection('maintenanceItems').doc(itemId).update({
      'nextServiceDate': nextDate.toIso8601String().split('T').first,
      'lastServiceDate': DateTime.now().toIso8601String().split('T').first,
    });
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) {
    return _firestore.collection('families').doc(familyId);
  }
}
