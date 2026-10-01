import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/utils/format.dart';
import '../../../home/domain/repositories/home_repository.dart';
import '../../../settings/domain/entities/family_info_entity.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../../domain/entities/check_in_entity.dart';
import '../../domain/entities/conversation_card_entity.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/entities/love_moment_entity.dart';
import '../../domain/entities/reflection_entity.dart';
import '../../domain/entities/upcoming_date_entity.dart';
import '../../domain/repositories/together_repository.dart';
import '../../../../core/l10n/app_locale.dart';

class TogetherViewModel extends ChangeNotifier {
  final TogetherRepository _togetherRepository;
  final SettingsRepository? _settingsRepository;
  final HomeRepository? _homeRepository;
  final String familyId;
  final String uid;
  final String userName;

  final List<StreamSubscription<dynamic>> _subs = [];

  List<LoveMomentEntity> loveTimeline = [];
  List<ConversationCardEntity> conversationCards = [];
  List<ReflectionEntity> reflections = [];
  UpcomingDateEntity? nextDateNight;
  String familyName = '';
  List<JournalEntryEntity> journalEntries = [];
  List<CheckInEntity> checkIns = [];
  DailyPhotoEntity? dailyPhoto;
  List<MemberEntity> members = [];

  // Kategori kartu obrolan: kunci data lama tetap dipakai, labelnya yang baru.
  static const cardCategoryLabels = {'Relationship': 'Kita', 'Deep Talk': 'Dalam', 'Parenting': 'Anak', 'Money': 'Uang'};
  static const cardCategoryDecks = {'Relationship': 'KITA BERDUA', 'Deep Talk': 'NGOBROL DALAM', 'Parenting': 'JADI ORANG TUA', 'Money': 'UANG & MIMPI'};
  String selectedCardCategory = 'Relationship';
  int currentCardIndex = 0;
  String journalFilter = 'Semua';

  // Isian check-in yang sedang disusun.
  int draftMood = 3;
  int draftEnergy = 4;

  static const defaultReflectionQuestions = [
    'Momen apa bulan ini yang bikin kamu bersyukur?',
    'Satu hal kecil yang bisa aku lakukan lebih baik?',
    'Keputusan apa yang terasa paling berat bulan ini?',
    'Satu hal yang mau kita coba bulan depan?',
  ];

  TogetherViewModel({
    required this._togetherRepository,
    required this.familyId,
    this._settingsRepository,
    this._homeRepository,
    this.uid = '',
    this.userName = '',
  }) {
    _subs.addAll([
      _togetherRepository.watchLoveTimeline(familyId).listen((v) => _set(() => loveTimeline = v)),
      _togetherRepository.watchConversationCards(familyId).listen((v) => _set(() {
            conversationCards = v;
            _resetCardIndexToToday();
          })),
      _togetherRepository.watchReflections(familyId).listen((v) => _set(() => reflections = v)),
      _togetherRepository.watchNextDateNight(familyId).listen((v) => _set(() => nextDateNight = v)),
      _togetherRepository.watchFamilyName(familyId).listen((v) => _set(() => familyName = v)),
      _togetherRepository.watchJournalEntries(familyId).listen((v) => _set(() => journalEntries = v)),
      _togetherRepository.watchCheckIns(familyId).listen((v) => _set(() {
            checkIns = v;
            final mine = myCheckInToday;
            if (mine != null) {
              draftMood = mine.mood;
              draftEnergy = mine.energy;
            }
          })),
      _togetherRepository.watchDailyPhoto(familyId).listen((v) => _set(() => dailyPhoto = v)),
      if (_settingsRepository != null) _settingsRepository.watchMembers(familyId).listen((v) => _set(() => members = v)),
    ]);
  }

  void _set(VoidCallback update) {
    update();
    notifyListeners();
  }

  MemberEntity? get partner {
    for (final m in members) {
      if (m.uid != uid) return m;
    }
    return null;
  }

  String get partnerName => partner?.name.split(' ').first ?? tr('Pasangan');
  String get firstName => userName.split(' ').first;

  // Check-in
  String get _today => dayKeyOf(DateTime.now());

  CheckInEntity? get myCheckInToday => checkIns.where((c) => c.uid == uid && c.dateKey == _today).firstOrNull;

  CheckInEntity? get partnerLatestCheckIn {
    final p = partner;
    if (p == null) return null;
    return checkIns.where((c) => c.uid == p.uid).firstOrNull;
  }

  /// Hari berturut-turut di mana kalian berdua check-in.
  int get streak {
    final byDay = <String, Set<String>>{};
    for (final c in checkIns) {
      byDay.putIfAbsent(c.dateKey, () => {}).add(c.uid);
    }
    final needed = members.length >= 2 ? 2 : 1;
    var day = dateOnly(DateTime.now());
    if ((byDay[dayKeyOf(day)]?.length ?? 0) < needed) day = day.subtract(const Duration(days: 1));
    var count = 0;
    while ((byDay[dayKeyOf(day)]?.length ?? 0) >= needed) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  void setDraftMood(int v) => _set(() => draftMood = v);
  void setDraftEnergy(int v) => _set(() => draftEnergy = v);

  Future<void> sendCheckIn(String need) async {
    await _togetherRepository.saveCheckIn(
      familyId,
      CheckInEntity(uid: uid, name: userName, mood: draftMood, energy: draftEnergy, need: need, dateKey: _today, createdAt: DateTime.now()),
    );
    await _homeRepository?.addNotification(
      familyId: familyId,
      icon: 'heart',
      title: tr('{0} sudah check-in', [firstName]),
      subtitle: tr('{0} · energi {1}/5', [tr(CheckInEntity.moodLabels[draftMood]), draftEnergy]),
      kind: 'untukmu',
      route: '/together',
      fromUid: uid,
    );
    final s = streak + 1;
    if (s == 7 || s == 30 || s == 100) {
      await _togetherRepository.addLoveMoment(familyId: familyId, title: tr('{0} hari check-in berturut-turut', [s]), icon: 'flame', date: DateTime.now(), auto: true);
    }
  }

  Future<void> saveDailyPhoto(String base64) =>
      _togetherRepository.saveDailyPhoto(familyId, DailyPhotoEntity(base64: base64, byName: userName, takenAt: DateTime.now()));

  Future<void> addMoment(String title, DateTime date) =>
      _togetherRepository.addLoveMoment(familyId: familyId, title: title, icon: 'heart', date: date);

  // Jurnal
  void setJournalFilter(String f) => _set(() => journalFilter = f);

  List<JournalEntryEntity> get filteredJournal {
    switch (journalFilter) {
      case 'Cerita':
        return journalEntries.where((j) => !j.isThanks).toList();
      case 'Makasih':
        return journalEntries.where((j) => j.isThanks).toList();
      default:
        return journalEntries;
    }
  }

  Future<void> addJournalEntry({required String title, required String text, String type = 'cerita'}) async {
    await _togetherRepository.addJournalEntry(familyId: familyId, authorUid: uid, authorName: userName, title: title, text: text, type: type);
    if (type == 'makasih') {
      await _homeRepository?.addNotification(
        familyId: familyId,
        icon: 'thanks',
        title: tr('{0} bilang makasih', [firstName]),
        subtitle: title,
        kind: 'untukmu',
        route: '/together/journal',
        fromUid: uid,
      );
    }
  }

  // Kartu obrolan
  List<String> get cardCategories => cardCategoryLabels.keys.toList();

  List<ConversationCardEntity> get filteredCards => conversationCards.where((c) => c.category == selectedCardCategory).toList();

  ConversationCardEntity? get currentCard {
    final cards = filteredCards;
    if (cards.isEmpty) return null;
    return cards[currentCardIndex % cards.length];
  }

  ConversationCardEntity? get todayCard =>
      conversationCards.where((c) => c.isToday).firstOrNull ?? (conversationCards.isEmpty ? null : conversationCards.first);

  ConversationCardEntity? get lastAnswered {
    final answered = conversationCards.where((c) => c.lastAnswer != null && c.answeredAt != null).toList()
      ..sort((a, b) => b.answeredAt!.compareTo(a.answeredAt!));
    return answered.firstOrNull;
  }

  void selectCardCategory(String category) {
    selectedCardCategory = category;
    _resetCardIndexToToday();
    notifyListeners();
  }

  void nextConversationCard() => _set(() => currentCardIndex++);

  void _resetCardIndexToToday() {
    final todayIndex = filteredCards.indexWhere((c) => c.isToday);
    currentCardIndex = todayIndex >= 0 ? todayIndex : 0;
  }

  Future<void> saveCardAnswer(ConversationCardEntity card, String answer) =>
      _togetherRepository.saveCardAnswer(familyId: familyId, cardId: card.id, answer: answer);

  // Ngobrol akhir bulan
  String get currentMonthKey => monthKeyOf(DateTime.now());

  ReflectionEntity? get currentReflection => reflections.where((r) => r.monthKey == currentMonthKey).firstOrNull;

  List<String> get reflectionQuestions {
    final q = currentReflection?.questions ?? const [];
    return q.isNotEmpty ? q : [for (final d in defaultReflectionQuestions) tr(d)];
  }

  /// Dibuka tiap tanggal 25 sampai akhir bulan.
  bool get reflectionOpen => DateTime.now().day >= 25;

  List<String?> get myAnswers => currentReflection?.memberAnswers[uid]?.answers ?? const [];
  bool get iCompleted => currentReflection?.memberAnswers[uid]?.completed ?? false;

  bool get partnerCompleted {
    final r = currentReflection;
    if (r == null) return false;
    return r.memberAnswers.entries.any((e) => e.key != uid && e.value.completed);
  }

  List<String?> get partnerAnswers {
    final r = currentReflection;
    if (r == null) return const [];
    for (final e in r.memberAnswers.entries) {
      if (e.key != uid) return e.value.answers;
    }
    return const [];
  }

  List<ReflectionEntity> get pastReflections => reflections.where((r) => r.monthKey != currentMonthKey).toList();

  bool isComplete(ReflectionEntity r) => r.memberAnswers.values.where((a) => a.completed).length >= 2 || r.status == 'lengkap';

  Future<void> saveReflectionAnswers(List<String?> answers) =>
      _togetherRepository.saveReflectionAnswers(familyId: familyId, monthKey: currentMonthKey, uid: uid, answers: answers);

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }
}
