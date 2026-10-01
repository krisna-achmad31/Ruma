import '../entities/check_in_entity.dart';
import '../entities/conversation_card_entity.dart';
import '../entities/journal_entry_entity.dart';
import '../entities/love_moment_entity.dart';
import '../entities/reflection_entity.dart';
import '../entities/upcoming_date_entity.dart';

abstract class TogetherRepository {
  Stream<List<LoveMomentEntity>> watchLoveTimeline(String familyId);
  Stream<List<ConversationCardEntity>> watchConversationCards(String familyId);
  Stream<List<ReflectionEntity>> watchReflections(String familyId);
  Stream<UpcomingDateEntity?> watchNextDateNight(String familyId);
  Stream<String> watchFamilyName(String familyId);
  Stream<List<JournalEntryEntity>> watchJournalEntries(String familyId);
  Stream<List<CheckInEntity>> watchCheckIns(String familyId);
  Stream<DailyPhotoEntity?> watchDailyPhoto(String familyId);

  Future<void> addJournalEntry({
    required String familyId,
    required String authorUid,
    required String authorName,
    required String title,
    required String text,
    String type = 'cerita',
  });

  Future<void> saveReflectionAnswers({
    required String familyId,
    required String monthKey,
    required String uid,
    required List<String?> answers,
  });

  Future<void> saveCheckIn(String familyId, CheckInEntity checkIn);

  Future<void> saveDailyPhoto(String familyId, DailyPhotoEntity photo);

  Future<void> addLoveMoment({required String familyId, required String title, required String icon, required DateTime date, bool auto = false});

  Future<void> saveCardAnswer({required String familyId, required String cardId, required String answer});
}
