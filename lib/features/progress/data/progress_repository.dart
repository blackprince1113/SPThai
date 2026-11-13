import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressRepository {
  final FirebaseFirestore _db;

  ProgressRepository(this._db);

  CollectionReference<Map<String, dynamic>> _progress(String userId) =>
      _db.collection('users').doc(userId).collection('progress');

  Future<Map<String, Map<String, dynamic>>> getAll(String userId) async {
    final snapshot = await _progress(userId).get();
    return {for (final doc in snapshot.docs) doc.id: doc.data()};
  }

  Future<void> saveLesson(
    String userId,
    String lessonId, {
    required Iterable<String> completedStepIds,
    required String? lastStepId,
  }) {
    return _progress(userId)
        .doc(lessonId)
        .set(
          _progressData(completedStepIds, lastStepId),
          SetOptions(merge: true),
        );
  }

  Future<void> saveLessons(
    String userId,
    Map<String, Map<String, dynamic>> lessons, {
    Iterable<String> deleteLessonIds = const [],
  }) async {
    final writes = <({String lessonId, Map<String, dynamic>? data})>[
      for (final entry in lessons.entries)
        (lessonId: entry.key, data: entry.value),
      for (final lessonId in deleteLessonIds)
        if (!lessons.containsKey(lessonId)) (lessonId: lessonId, data: null),
    ];
    for (var start = 0; start < writes.length; start += 450) {
      final batch = _db.batch();
      final end = (start + 450).clamp(0, writes.length).toInt();
      for (final write in writes.sublist(start, end)) {
        final ref = _progress(userId).doc(write.lessonId);
        if (write.data == null) {
          batch.delete(ref);
        } else {
          batch.set(ref, write.data!, SetOptions(merge: true));
        }
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _progressData(
    Iterable<String> completedStepIds,
    String? lastStepId,
  ) {
    return {
      'completedStepIds': completedStepIds.toSet().toList(),
      'lastStepId': lastStepId,
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 3,
    };
  }

  Future<void> deleteLesson(String userId, String lessonId) =>
      _progress(userId).doc(lessonId).delete();
}
