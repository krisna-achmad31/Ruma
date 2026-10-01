import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/check_in_entity.dart';
import '../../domain/entities/conversation_card_entity.dart';
import '../../domain/entities/journal_entry_entity.dart';
import '../../domain/entities/love_moment_entity.dart';
import '../../domain/entities/reflection_entity.dart';
import '../../domain/entities/upcoming_date_entity.dart';

class TogetherRemoteDataSource {
  final FirebaseFirestore _firestore;

  TogetherRemoteDataSource({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<LoveMomentEntity>> watchLoveTimeline(String familyId) {
    return _familyDoc(familyId).collection('loveTimeline').snapshots().map((snapshot) {
      final moments = snapshot.docs.map((doc) {
        final data = doc.data();
        return LoveMomentEntity(
          id: doc.id,
          title: (data['title'] as String?) ?? '',
          icon: (data['icon'] as String?) ?? 'favorite',
          date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
          auto: (data['auto'] as bool?) ?? false,
        );
      }).toList();
      moments.sort((a, b) => b.date.compareTo(a.date));
      return moments;
    });
  }

  Stream<List<ConversationCardEntity>> watchConversationCards(String familyId) {
    return _familyDoc(familyId).collection('conversationCards').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ConversationCardEntity(
          id: doc.id,
          category: (data['category'] as String?) ?? '',
          cardNumber: (data['cardNumber'] as num?)?.toInt() ?? 0,
          question: (data['question'] as String?) ?? '',
          instruction: (data['instruction'] as String?) ?? '',
          isToday: (data['isToday'] as bool?) ?? false,
          lastAnswer: data['lastAnswer'] as String?,
          answeredAt: DateTime.tryParse((data['answeredAt'] as String?) ?? ''),
        );
      }).toList();
    });
  }

  Stream<List<ReflectionEntity>> watchReflections(String familyId) {
    return _familyDoc(familyId).collection('reflections').snapshots().map((snapshot) {
      final reflections = snapshot.docs.map((doc) {
        final data = doc.data();
        final questions = (data['questions'] as List?)?.cast<String>() ?? const <String>[];
        final rawMemberAnswers = (data['memberAnswers'] as Map<String, dynamic>?) ?? {};
        final memberAnswers = rawMemberAnswers.map((uid, value) {
          final map = value as Map<String, dynamic>;
          return MapEntry(
            uid,
            MemberAnswer(
              completed: (map['completed'] as bool?) ?? false,
              answers: (map['answers'] as List?)?.cast<String?>() ?? const <String?>[],
            ),
          );
        });
        return ReflectionEntity(
          monthKey: doc.id,
          questions: questions,
          status: (data['status'] as String?) ?? '',
          openDate: DateTime.tryParse((data['openDate'] as String?) ?? ''),
          closeDate: DateTime.tryParse((data['closeDate'] as String?) ?? ''),
          memberAnswers: memberAnswers,
        );
      }).toList();
      reflections.sort((a, b) => b.monthKey.compareTo(a.monthKey));
      return reflections;
    });
  }

  Stream<UpcomingDateEntity?> watchNextDateNight(String familyId) {
    return _familyDoc(familyId).collection('calendarEvents').snapshots().map((snapshot) {
      final today = DateTime.now();
      final events = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return (
              category: (data['category'] as String?) ?? '',
              title: (data['title'] as String?) ?? '',
              date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime(1970),
            );
          })
          .where((e) => e.category == 'berdua' && !e.date.isBefore(DateTime(today.year, today.month, today.day)))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (events.isEmpty) return null;
      return UpcomingDateEntity(title: events.first.title, date: events.first.date);
    });
  }

  Stream<String> watchFamilyName(String familyId) {
    return _familyDoc(familyId).snapshots().map((doc) => (doc.data()?['name'] as String?) ?? '');
  }

  Stream<List<JournalEntryEntity>> watchJournalEntries(String familyId) {
    return _familyDoc(familyId).collection('journalEntries').snapshots().map((snapshot) {
      final entries = snapshot.docs.map((doc) {
        final data = doc.data();
        return JournalEntryEntity(
          id: doc.id,
          authorUid: (data['authorUid'] as String?) ?? '',
          authorName: (data['authorName'] as String?) ?? '',
          title: (data['title'] as String?) ?? '',
          text: (data['text'] as String?) ?? '',
          date: DateTime.tryParse((data['date'] as String?) ?? '') ?? DateTime.now(),
          time: (data['time'] as String?) ?? '',
          type: (data['type'] as String?) ?? 'cerita',
        );
      }).toList();
      entries.sort((a, b) {
        final byDate = b.date.compareTo(a.date);
        return byDate != 0 ? byDate : b.time.compareTo(a.time);
      });
      return entries;
    });
  }

  Stream<List<CheckInEntity>> watchCheckIns(String familyId) {
    return _familyDoc(familyId).collection('checkIns').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final d = doc.data();
        return CheckInEntity(
          uid: (d['uid'] as String?) ?? '',
          name: (d['name'] as String?) ?? '',
          mood: (d['mood'] as num?)?.toInt() ?? 2,
          energy: (d['energy'] as num?)?.toInt() ?? 3,
          need: (d['need'] as String?) ?? '',
          dateKey: (d['dateKey'] as String?) ?? '',
          createdAt: DateTime.tryParse((d['createdAt'] as String?) ?? '') ?? DateTime.now(),
        );
      }).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<DailyPhotoEntity?> watchDailyPhoto(String familyId) {
    return _familyDoc(familyId).collection('dailyPhoto').doc('current').snapshots().map((doc) {
      final d = doc.data();
      if (d == null || d['base64'] == null) return null;
      return DailyPhotoEntity(
        base64: d['base64'] as String,
        byName: (d['byName'] as String?) ?? '',
        takenAt: DateTime.tryParse((d['takenAt'] as String?) ?? '') ?? DateTime.now(),
      );
    });
  }

  Future<void> addJournalEntry({
    required String familyId,
    required String authorUid,
    required String authorName,
    required String title,
    required String text,
    String type = 'cerita',
  }) {
    final now = DateTime.now();
    return _familyDoc(familyId).collection('journalEntries').add({
      'authorUid': authorUid,
      'authorName': authorName,
      'title': title,
      'text': text,
      'type': type,
      'date': now.toIso8601String().split('T').first,
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
    });
  }

  Future<void> saveReflectionAnswers({
    required String familyId,
    required String monthKey,
    required String uid,
    required List<String?> answers,
  }) {
    return _familyDoc(familyId).collection('reflections').doc(monthKey).set({
      'memberAnswers': {
        uid: {'completed': true, 'answers': answers},
      },
    }, SetOptions(merge: true));
  }

  Future<void> saveCheckIn(String familyId, CheckInEntity c) {
    return _familyDoc(familyId).collection('checkIns').doc('${c.dateKey}_${c.uid}').set({
      'uid': c.uid,
      'name': c.name,
      'mood': c.mood,
      'energy': c.energy,
      'need': c.need,
      'dateKey': c.dateKey,
      'createdAt': c.createdAt.toIso8601String(),
    });
  }

  Future<void> saveDailyPhoto(String familyId, DailyPhotoEntity photo) {
    return _familyDoc(familyId).collection('dailyPhoto').doc('current').set({
      'base64': photo.base64,
      'byName': photo.byName,
      'takenAt': photo.takenAt.toIso8601String(),
    });
  }

  Future<void> addLoveMoment({required String familyId, required String title, required String icon, required DateTime date, bool auto = false}) {
    return _familyDoc(familyId).collection('loveTimeline').add({
      'title': title,
      'icon': icon,
      'date': date.toIso8601String().split('T').first,
      'auto': auto,
    });
  }

  Future<void> saveCardAnswer({required String familyId, required String cardId, required String answer}) {
    return _familyDoc(familyId).collection('conversationCards').doc(cardId).update({
      'lastAnswer': answer,
      'answeredAt': DateTime.now().toIso8601String(),
    });
  }

  DocumentReference<Map<String, dynamic>> _familyDoc(String familyId) => _firestore.collection('families').doc(familyId);
}
