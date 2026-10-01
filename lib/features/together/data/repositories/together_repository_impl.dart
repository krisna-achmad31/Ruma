import '../../domain/entities/check_in_entity.dart';
import '../../domain/entities/conversation_card_entity.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/entities/love_moment_entity.dart';
import '../../domain/entities/reflection_entity.dart';
import '../../domain/entities/upcoming_date_entity.dart';
import '../../domain/repositories/together_repository.dart';
import '../datasources/together_remote_datasource.dart';

class TogetherRepositoryImpl implements TogetherRepository {
  final TogetherRemoteDataSource _remote;

  TogetherRepositoryImpl(this._remote);

  @override
  Stream<List<LoveMomentEntity>> watchLoveTimeline(String familyId) => _remote.watchLoveTimeline(familyId);

  @override
  Stream<List<ConversationCardEntity>> watchConversationCards(String familyId) => _remote.watchConversationCards(familyId);

  @override
  Stream<List<ReflectionEntity>> watchReflections(String familyId) => _remote.watchReflections(familyId);

  @override
  Stream<UpcomingDateEntity?> watchNextDateNight(String familyId) => _remote.watchNextDateNight(familyId);

  @override
  Stream<String> watchFamilyName(String familyId) => _remote.watchFamilyName(familyId);

  @override
  Stream<List<JournalEntryEntity>> watchJournalEntries(String familyId) => _remote.watchJournalEntries(familyId);

  @override
  Stream<List<CheckInEntity>> watchCheckIns(String familyId) => _remote.watchCheckIns(familyId);

  @override
  Stream<DailyPhotoEntity?> watchDailyPhoto(String familyId) => _remote.watchDailyPhoto(familyId);

  @override
  Future<void> addJournalEntry({
    required String familyId,
    required String authorUid,
    required String authorName,
    required String title,
    required String text,
    String type = 'cerita',
  }) {
    return _remote.addJournalEntry(
      familyId: familyId,
      authorUid: authorUid,
      authorName: authorName,
      title: title,
      text: text,
      type: type,
    );
  }

  @override
  Future<void> saveReflectionAnswers({
    required String familyId,
    required String monthKey,
    required String uid,
    required List<String?> answers,
  }) {
    return _remote.saveReflectionAnswers(familyId: familyId, monthKey: monthKey, uid: uid, answers: answers);
  }

  @override
  Future<void> saveCheckIn(String familyId, CheckInEntity checkIn) => _remote.saveCheckIn(familyId, checkIn);

  @override
  Future<void> saveDailyPhoto(String familyId, DailyPhotoEntity photo) => _remote.saveDailyPhoto(familyId, photo);

  @override
  Future<void> addLoveMoment({required String familyId, required String title, required String icon, required DateTime date, bool auto = false}) {
    return _remote.addLoveMoment(familyId: familyId, title: title, icon: icon, date: date, auto: auto);
  }

  @override
  Future<void> saveCardAnswer({required String familyId, required String cardId, required String answer}) {
    return _remote.saveCardAnswer(familyId: familyId, cardId: cardId, answer: answer);
  }
}
