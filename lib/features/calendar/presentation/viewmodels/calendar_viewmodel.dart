import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/entities/calendar_event_entity.dart';
import '../../domain/entities/maintenance_item_entity.dart';
import '../../domain/repositories/calendar_repository.dart';

class CalendarViewModel extends ChangeNotifier {
  final CalendarRepository _calendarRepository;
  final String familyId;

  StreamSubscription<List<CalendarEventEntity>>? _eventsSub;
  StreamSubscription<List<MaintenanceItemEntity>>? _maintenanceSub;
  StreamSubscription<String>? _familyNameSub;

  List<CalendarEventEntity> events = [];
  List<MaintenanceItemEntity> maintenanceItems = [];
  String familyName = '';
  DateTime displayedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? selectedDay;

  CalendarViewModel({required this._calendarRepository, required this.familyId}) {
    _eventsSub = _calendarRepository.watchEvents(familyId).listen((value) {
      events = value;
      notifyListeners();
    });
    _maintenanceSub = _calendarRepository.watchMaintenanceItems(familyId).listen((value) {
      maintenanceItems = value;
      notifyListeners();
    });
    _familyNameSub = _calendarRepository.watchFamilyName(familyId).listen((value) {
      familyName = value;
      notifyListeners();
    });
  }

  void nextMonth() {
    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month + 1);
    notifyListeners();
  }

  void previousMonth() {
    displayedMonth = DateTime(displayedMonth.year, displayedMonth.month - 1);
    notifyListeners();
  }

  void selectDay(DateTime day) {
    selectedDay = day;
    notifyListeners();
  }

  List<CalendarEventEntity> eventsOnDay(DateTime day) {
    return events.where((e) => _isSameDay(e.date, day)).toList();
  }

  List<CalendarEventEntity> get billEvents =>
      events.where((e) => e.category == 'bayar_belanja').toList()..sort((a, b) => a.date.compareTo(b.date));

  List<MaintenanceItemEntity> get upcomingMaintenance {
    final sorted = [...maintenanceItems]..sort((a, b) => a.nextServiceDate.compareTo(b.nextServiceDate));
    return sorted;
  }

  int get maintenanceDueSoonCount {
    final threshold = DateTime.now().add(const Duration(days: 14));
    return maintenanceItems.where((m) => !m.nextServiceDate.isAfter(threshold)).length;
  }

  Future<void> toggleEventDone(CalendarEventEntity event) {
    return _calendarRepository.setEventDone(familyId, event.id, !event.isDone);
  }

  Future<void> addEvent(String title, String category, DateTime date) =>
      _calendarRepository.addEvent(familyId: familyId, title: title, category: category, date: date);

  Future<void> addMaintenance({required String name, required String type, required String note, required DateTime next, required double cost}) =>
      _calendarRepository.addMaintenanceItem(familyId: familyId, name: name, type: type, note: note, nextServiceDate: next, estimatedCost: cost);

  Future<void> completeMaintenance(MaintenanceItemEntity item, int intervalDays) =>
      _calendarRepository.completeMaintenance(familyId, item.id, DateTime.now().add(Duration(days: intervalDays)));

  String maintenanceFilter = 'Semua';

  void setMaintenanceFilter(String f) {
    maintenanceFilter = f;
    notifyListeners();
  }

  static const maintenanceTypes = {'Kendaraan': 'kendaraan', 'Rumah': 'rumah', 'Elektronik': 'elektronik'};

  List<MaintenanceItemEntity> get filteredMaintenance {
    final type = maintenanceTypes[maintenanceFilter];
    return upcomingMaintenance.where((m) => type == null || m.type == type).toList();
  }

  List<MaintenanceItemEntity> get dueThisMonth {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month + 1, 0);
    return maintenanceItems.where((m) => !m.nextServiceDate.isAfter(end)).toList();
  }

  /// Label status dihitung dari tanggal, bukan disimpan manual. Berupa teks sumber, terjemahkan saat tampil.
  String statusOf(MaintenanceItemEntity m) {
    final days = DateTime(m.nextServiceDate.year, m.nextServiceDate.month, m.nextServiceDate.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
    if (days < 0) return 'Terlambat';
    if (days == 0) return 'Hari ini';
    if (days <= 7) return 'Minggu ini';
    if (days <= 14) return 'Segera';
    return 'Aman';
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void dispose() {
    _eventsSub?.cancel();
    _maintenanceSub?.cancel();
    _familyNameSub?.cancel();
    super.dispose();
  }
}
