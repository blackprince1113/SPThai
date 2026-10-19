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
    Iterable<int>? legacyImportedStepIndices,
  }) {
    return _progress(userId)
        .doc(lessonId)
        .set(
          _progressData(
            completedStepIds,
            lastStepId,
            legacyImportedStepIndices,
          ),
          SetOptions(merge: true),
        );
  }

  Future<void> saveLessons(
    String userId,
    Map<String, Map<String, dynamic>> lessons,
  ) async {
    final entries = lessons.entries.toList();
    for (var start = 0; start < entries.length; start += 450) {
      final batch = _db.batch();
      final end = (start + 450).clamp(0, entries.length).toInt();
      for (final entry in entries.sublist(start, end)) {
        batch.set(
          _progress(userId).doc(entry.key),
          entry.value,
          SetOptions(merge: true),
        );
      }
      await batch.commit();
    }
  }

  Map<String, dynamic> _progressData(
    Iterable<String> completedStepIds,
    String? lastStepId,
    Iterable<int>? legacyImportedStepIndices,
  ) {
    return {
      'completedStepIds': completedStepIds.toSet().toList(),
      'lastStepId': lastStepId,
      // Kept only as an import marker so old index based records are imported once.
      'legacyImportedStepIndices':
          (legacyImportedStepIndices ?? const <int>[]).toSet().toList()..sort(),
      'updatedAt': FieldValue.serverTimestamp(),
      'schemaVersion': 3,
    };
  }

  Future<void> deleteLesson(String userId, String lessonId) =>
      _progress(userId).doc(lessonId).delete();
}
