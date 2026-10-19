import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/features/lessons/data/lesson_repository.dart';

class FirestoreLessonRepository implements LessonRepository {
  FirestoreLessonRepository(this._db);

  static const int _batchLimit = 450;
  static const int _schemaVersion = 2;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _legacyPlans =>
      _db.collection('lesson_plans');

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('lesson_plans_v2');

  @override
  Future<List<LessonPlan>> getAll() async {
    // List pages still use the legacy collection so opening the catalog does
    // not migrate every lesson. A specific lesson is migrated by getById.
    final snapshot = await _legacyPlans.get();
    final plans = await Future.wait(snapshot.docs.map(_parseAndRepairStepIds));
    return plans..sort((a, b) => a.index.compareTo(b.index));
  }

  @override
  Future<LessonPlan?> getById(String lessonId) async {
    try {
      final newSnapshot = await _plans.doc(lessonId).get();
      if (newSnapshot.exists) {
        try {
          return await _readV2Plan(newSnapshot);
        } on FirebaseException {
          // Fall back to the old source if new-schema reads are not allowed.
        }
      }
    } on FirebaseException {
      // Fall back to the public legacy collection until new rules are deployed.
    }

    return _migrateLegacyLesson(lessonId);
  }

  Future<LessonPlan?> _migrateLegacyLesson(String lessonId) async {
    final legacySnapshot = await _legacyPlans.doc(lessonId).get();
    if (!legacySnapshot.exists) return null;

    final legacyPlan = await _parseAndRepairStepIds(legacySnapshot);
    try {
      await _writeV2Plan(legacyPlan);
      return legacyPlan;
    } on FirebaseException {
      // Keep lessons usable if the new collection's rules are not deployed yet.
      return legacyPlan;
    }
  }

  @override
  Future<LessonPlan?> getByCategory(String category) async {
    final snapshot = await _legacyPlans
        .where('category', isEqualTo: category)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return getById(snapshot.docs.first.id);
  }

  Future<LessonPlan> _parseAndRepairStepIds(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final plan = LessonPlan.fromMap(snapshot.data()!);
    if (!plan.steps.any((step) => step.needsIdMigration)) return plan;

    try {
      return await _db.runTransaction((transaction) async {
        final currentSnapshot = await transaction.get(snapshot.reference);
        final currentData = currentSnapshot.data();
        if (currentData == null) return plan;
        final currentPlan = LessonPlan.fromMap(currentData);
        if (currentPlan.steps.any((step) => step.needsIdMigration)) {
          transaction.update(snapshot.reference, {
            'steps': currentPlan.steps.map((step) => step.toMap()).toList(),
          });
        }
        return currentPlan;
      });
    } on FirebaseException {
      // Public lesson reads must still work when legacy IDs cannot be repaired.
      return plan;
    }
  }

  Future<LessonPlan> _readV2Plan(
    DocumentSnapshot<Map<String, dynamic>> metadataSnapshot,
  ) async {
    final metadata = metadataSnapshot.data()!;
    final stepSnapshot = await metadataSnapshot.reference
        .collection('steps')
        .orderBy('position')
        .get();
    final steps = stepSnapshot.docs
        .map((doc) => LessonStepData.fromMap(doc.data()))
        .toList();

    return LessonPlan(
      id: metadata['id'] as String? ?? metadataSnapshot.id,
      title: metadata['title'] as String? ?? '',
      category: metadata['category'] as String? ?? '',
      categoryEmoji: metadata['categoryEmoji'] as String? ?? '📚',
      emoji: metadata['emoji'] as String? ?? '📝',
      steps: steps,
      creatorId: metadata['creatorId'] as String?,
      createdAt: _parseDate(metadata['createdAt']),
      index: (metadata['index'] as num?)?.toInt() ?? 0,
    );
  }

  DateTime? _parseDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> _metadataFor(LessonPlan plan) => {
    'id': plan.id,
    'title': plan.title,
    'category': plan.category,
    'categoryEmoji': plan.categoryEmoji,
    'emoji': plan.emoji,
    'creatorId': plan.creatorId,
    'createdAt': plan.createdAt?.toIso8601String(),
    'index': plan.index,
    'stepCount': plan.steps.length,
    'schemaVersion': _schemaVersion,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<void> _writeV2Plan(LessonPlan plan) async {
    final metadataRef = _plans.doc(plan.id);
    final stepsRef = metadataRef.collection('steps');
    final existingSteps = await stepsRef.get();
    final retainedIds = plan.steps.map((step) => step.id).toSet();
    final staleSteps = existingSteps.docs
        .where((doc) => !retainedIds.contains(doc.id))
        .toList();

    // Publish the metadata marker last. Readers then never treat a partially
    // copied collection as a complete migrated lesson.
    await metadataRef.delete();

    final operations = <void Function(WriteBatch)>[];
    for (var position = 0; position < plan.steps.length; position++) {
      final step = plan.steps[position];
      final stepPosition = position;
      operations.add((batch) {
        batch.set(stepsRef.doc(step.id), {
          ...step.toMap(),
          'position': stepPosition,
        });
      });
    }
    for (final staleStep in staleSteps) {
      operations.add((batch) => batch.delete(staleStep.reference));
    }

    for (var start = 0; start < operations.length; start += _batchLimit) {
      final batch = _db.batch();
      final end = (start + _batchLimit).clamp(0, operations.length).toInt();
      for (final operation in operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }

    await metadataRef.set(_metadataFor(plan));
  }

  @override
  Future<void> save(LessonPlan plan, {int? nextIndex}) async {
    final docRef = _legacyPlans.doc(plan.id);
    final doc = await docRef.get();
    var index = plan.index;
    var createdAt = plan.createdAt ?? DateTime.now();

    if (doc.exists) {
      final oldData = doc.data()!;
      if (index == 0 && oldData.containsKey('index')) {
        index = (oldData['index'] as num?)?.toInt() ?? 0;
      }
      final oldCreatedAt = _parseDate(oldData['createdAt']);
      if (oldCreatedAt != null) createdAt = oldCreatedAt;
    } else if (index == 0 && nextIndex != null) {
      index = nextIndex;
    } else if (index == 0) {
      final lastPlan = await _legacyPlans
          .orderBy('index', descending: true)
          .limit(1)
          .get();
      if (lastPlan.docs.isNotEmpty) {
        index =
            ((lastPlan.docs.first.data()['index'] as num?)?.toInt() ?? 0) + 1;
      } else if ((await _legacyPlans.limit(1).get()).docs.isNotEmpty) {
        index = 1;
      }
    }

    final normalizedPlan = LessonPlan(
      id: plan.id,
      title: plan.title,
      category: plan.category,
      categoryEmoji: plan.categoryEmoji,
      emoji: plan.emoji,
      steps: plan.steps,
      creatorId: plan.creatorId,
      createdAt: createdAt,
      index: index,
    );

    // Keep the old document current for older app releases, then write the
    // normalized representation used by this release.
    await docRef.set(normalizedPlan.toMap(), SetOptions(merge: true));
    await _writeV2Plan(normalizedPlan);
  }

  @override
  Future<void> delete(String lessonId) async {
    final metadataRef = _plans.doc(lessonId);
    final steps = await metadataRef.collection('steps').get();
    for (var start = 0; start < steps.docs.length; start += _batchLimit) {
      final batch = _db.batch();
      final end = (start + _batchLimit).clamp(0, steps.docs.length).toInt();
      for (final step in steps.docs.sublist(start, end)) {
        batch.delete(step.reference);
      }
      await batch.commit();
    }
    await metadataRef.delete();
    await _legacyPlans.doc(lessonId).delete();
  }

  @override
  Future<void> updateIndices(List<LessonPlan> plans) async {
    final v2Snapshots = await Future.wait(
      plans.map((plan) => _plans.doc(plan.id).get()),
    );
    final operations = <void Function(WriteBatch)>[];
    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      final lessonIndex = index;
      operations.add(
        (batch) =>
            batch.update(_legacyPlans.doc(plan.id), {'index': lessonIndex}),
      );
      if (v2Snapshots[index].exists) {
        operations.add(
          (batch) => batch.update(_plans.doc(plan.id), {'index': lessonIndex}),
        );
      }
    }
    for (var start = 0; start < operations.length; start += _batchLimit) {
      final batch = _db.batch();
      final end = (start + _batchLimit).clamp(0, operations.length).toInt();
      for (final operation in operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }
  }
}
