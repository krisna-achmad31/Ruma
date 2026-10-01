import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/home_widget_service.dart';
import '../../../../core/utils/format.dart';
import '../../../finance/domain/entities/category_entity.dart';
import '../../../finance/domain/entities/wallet_entity.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../finance/domain/usecases/parse_quick_entry.dart';
import '../../../settings/domain/entities/app_settings_entity.dart';
import '../../../settings/domain/entities/family_info_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/domain/repositories/task_repository.dart';
import '../../../together/domain/entities/check_in_entity.dart';
import '../../../together/domain/entities/journal_entry_entity.dart';
import '../../../together/domain/repositories/together_repository.dart';
import '../../domain/entities/family_summary_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../../../core/l10n/app_locale.dart';

class HomeViewModel extends ChangeNotifier {
  final HomeRepository _homeRepository;
  final TaskRepository _taskRepository;
  final TogetherRepository _togetherRepository;
  final FinanceRepository _financeRepository;
  final SettingsRepository _settingsRepository;
  final WeatherRepository _weatherRepository;
  final String familyId;
  final String uid;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  FamilySummaryEntity? family;
  List<TaskEntity> tasks = [];
  List<CheckInEntity> checkIns = [];
  List<CategoryEntity> categories = [];
  List<WalletEntity> wallets = [];
  List<JournalEntryEntity> journal = [];
  List<NotificationEntity> notifications = [];
  List<MemberEntity> members = [];
  AppSettingsEntity? settings;
  WeatherSummary? weather;
  String? _weatherCity;

  HomeViewModel({
    required this._homeRepository,
    required this._taskRepository,
    required this._togetherRepository,
    required this._financeRepository,
    required this._settingsRepository,
    required this._weatherRepository,
    required this.familyId,
    required this.uid,
    required this.userName,
  }) {
    _subs.addAll([
      _homeRepository.watchFamilySummary(familyId).listen((v) {
        family = v;
        _loadWeather(v.location);
        _changed();
      }),
      _taskRepository.watchTasks(familyId).listen((v) => _set(() => tasks = v)),
      _togetherRepository.watchCheckIns(familyId).listen((v) => _set(() => checkIns = v)),
      _togetherRepository.watchJournalEntries(familyId).listen((v) => _set(() => journal = v)),
      _financeRepository.watchCategories(familyId).listen((v) => _set(() => categories = v)),
      _financeRepository.watchWallets(familyId).listen((v) => _set(() => wallets = v)),
      _homeRepository.watchNotifications(familyId).listen((v) => _set(() => notifications = v)),
      _settingsRepository.watchMembers(familyId).listen((v) => _set(() => members = v)),
      _settingsRepository.watchSettings(familyId).listen((v) => _set(() => settings = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    _changed();
  }

  void _changed() {
    notifyListeners();
    _pushWidget();
  }

  Future<void> _loadWeather(String city) async {
    if (city.isEmpty || city == _weatherCity) return;
    _weatherCity = city;
    weather = await _weatherRepository.todayFor(city);
    notifyListeners();
  }

  String get firstName => userName.split(' ').first;

  MemberEntity? get partner {
    for (final m in members) {
      if (m.uid != uid) return m;
    }
    return null;
  }

  String get partnerName => partner?.name.split(' ').first ?? tr('Pasangan');

  CheckInEntity? get partnerCheckIn {
    final p = partner;
    if (p == null) return null;
    final today = dayKeyOf(DateTime.now());
    for (final c in checkIns) {
      if (c.uid == p.uid && c.dateKey == today) return c;
    }
    return null;
  }

  // Uang aman dipakai: sisa semua amplop dibagi hari sampai tanggal isi ulang.
  int get resetDay => settings?.budgetResetDay ?? 1;

  int get daysToPayday {
    final now = dateOnly(DateTime.now());
    var next = DateTime(now.year, now.month, resetDay);
    if (!next.isAfter(now)) next = DateTime(now.year, now.month + 1, resetDay);
    return next.difference(now).inDays.clamp(1, 31);
  }

  double get budgetTotal => categories.fold(0, (s, c) => s + c.budgetAmount);
  double get budgetRemaining => categories.fold(0, (s, c) => s + (c.budgetAmount - c.spentAmount).clamp(0, double.infinity));
  double get safeToSpendToday => budgetRemaining / daysToPayday;
  double get budgetRemainingFraction => budgetTotal <= 0 ? 0 : budgetRemaining / budgetTotal;

  // Urusan
  List<TaskEntity> get openTasks => tasks.where((t) => !t.isDone).toList();

  List<TaskEntity> get priorities {
    final horizon = dateOnly(DateTime.now()).add(const Duration(days: 7));
    return openTasks.where((t) => t.dueDate == null || !t.dueDate!.isAfter(horizon)).take(3).toList();
  }

  List<TaskEntity> get _weekTasks {
    final today = dateOnly(DateTime.now());
    final end = today.add(const Duration(days: 7));
    return tasks.where((t) => t.dueDate != null && !t.dueDate!.isBefore(today) && !t.dueDate!.isAfter(end)).toList();
  }

  int get weekDone => _weekTasks.where((t) => t.isDone).length;
  int get weekTotal => _weekTasks.length;

  int get doneThisWeek {
    final since = DateTime.now().subtract(const Duration(days: 7));
    return tasks.where((t) => t.isDone && t.createdAt.isAfter(since)).length;
  }

  /// Jumlah urusan terbuka yang sedang dipegang pasangan, termasuk yang ia ingat.
  int get partnerOpenLoad {
    final p = partner;
    if (p == null) return 0;
    return openTasks.where((t) => t.thinkerUid == p.uid || t.doerUid == p.uid).length;
  }

  JournalEntryEntity? get latestThanksFromPartner {
    final p = partner;
    final since = DateTime.now().subtract(const Duration(days: 7));
    for (final j in journal) {
      if (j.isThanks && j.authorUid != uid && (p == null || j.authorUid == p.uid) && j.date.isAfter(since)) return j;
    }
    return null;
  }

  int get unreadCount => notifications.where((n) => !n.isRead && n.fromUid != uid).length;

  String roleLine(TaskEntity t) {
    final thinker = t.thinkerUid == uid ? tr('Kamu yang ingat') : tr('{0} yang ingat', [t.thinkerName.split(' ').first]);
    final String doer;
    if (t.together) {
      doer = tr('dikerjakan berdua');
    } else if (t.doerUid == null) {
      doer = tr('belum ada pelaksana');
    } else if (t.doerUid == uid) {
      doer = tr('kamu yang kerjakan');
    } else {
      doer = tr('{0} yang kerjakan', [(t.doerName ?? '').split(' ').first]);
    }
    return '$thinker · $doer';
  }

  Future<void> toggleTask(TaskEntity t) => _taskRepository.setDone(familyId, t.id, !t.isDone);

  /// Catat cepat dari kalimat. Mengembalikan pesan hasil untuk ditampilkan.
  Future<String> quickAdd(String text) async {
    final entry = ParseQuickEntry()(text, wallets: wallets, categories: categories);
    if (entry == null || entry.walletId == null) {
      return tr('Belum kebaca nominalnya. Coba tulis seperti "sayur 45rb gopay".');
    }
    await _financeRepository.addTransaction(
      familyId: familyId,
      title: entry.title,
      amount: entry.amount,
      type: entry.isIncome ? 'income' : 'expense',
      walletId: entry.walletId!,
      categoryId: entry.categoryId,
      date: DateTime.now(),
      createdByName: userName,
    );
    return tr('{0} {1} tercatat.', [entry.title, formatRupiah(entry.amount)]);
  }

  void _pushWidget() {
    final pc = partnerCheckIn;
    HomeWidgetService.update(
      safeToSpend: formatRupiahShort(safeToSpendToday),
      partnerMood: pc == null ? tr('Belum check-in') : '$partnerName ${pc.emoji} ${pc.energy}/5',
      tasksLine: priorities.isEmpty ? tr('Belum ada urusan') : priorities.map((t) => t.title).join('\n'),
      tasksCount: '$weekDone/$weekTotal beres',
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
