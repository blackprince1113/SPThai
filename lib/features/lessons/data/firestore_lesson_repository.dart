import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/features/lessons/data/lesson_repository.dart';

class FirestoreLessonRepository implements LessonRepository {
  FirestoreLessonRepository(this._db);

  static const int _batchLimit = 450;
  static const int _schemaVersion = 2;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _plans =>
      _db.collection('lesson_plans_v2');

  @override
  Future<List<LessonPlan>> getAll() async {
    try {
      final snapshot = await _plans.get();
      final plans = snapshot.docs.map(_parsePlanFromMetadata).toList();
      return plans..sort((a, b) => a.index.compareTo(b.index));
    } catch (_) {
      return [];
    }
  }

  @override
  Future<LessonPlan?> getById(String lessonId) async {
    try {
      final snapshot = await _plans.doc(lessonId).get();
      if (!snapshot.exists) return null;
      return await _readPlan(snapshot);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<LessonPlan?> getByCategory(String category) async {
    try {
      final snapshot = await _plans
          .where('category', isEqualTo: category)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return await _readPlan(snapshot.docs.first);
    } catch (_) {
      return null;
    }
  }

  Future<LessonPlan> _readPlan(
    DocumentSnapshot<Map<String, dynamic>> metadataSnapshot,
  ) async {
    final metadata = metadataSnapshot.data();
    if (metadata == null) {
      return _parsePlanFromMetadata(metadataSnapshot);
    }

    List<LessonStepData> steps = [];
    try {
      final stepSnapshot = await metadataSnapshot.reference
          .collection('steps')
          .get();
      if (stepSnapshot.docs.isNotEmpty) {
        final sortedDocs = stepSnapshot.docs.toList()
          ..sort((a, b) {
            final posA = (a.data()['position'] as num?)?.toInt() ?? 0;
            final posB = (b.data()['position'] as num?)?.toInt() ?? 0;
            return posA.compareTo(posB);
          });
        steps = sortedDocs
            .map((doc) => LessonStepData.fromMap(doc.data()))
            .toList();
      }
    } catch (_) {}

    if (steps.isEmpty && metadata['steps'] is List) {
      steps = (metadata['steps'] as List)
          .map((s) => LessonStepData.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    }

    return LessonPlan(
      id: metadata['id'] as String? ?? metadataSnapshot.id,
      title: metadata['title'] as String? ?? '',
      category: metadata['category'] as String? ?? '',
      categoryEmoji: metadata['categoryEmoji'] as String? ?? '📚',
      categoryLottieUrl: metadata['categoryLottieUrl'] as String?,
      categoryBackgroundImageUrl: metadata['categoryBackgroundImageUrl'] as String? ?? metadata['categoryBgUrl'] as String?,
      emoji: metadata['emoji'] as String? ?? '📝',
      lottieUrl: metadata['lottieUrl'] as String?,
      steps: steps,
      creatorId: metadata['creatorId'] as String?,
      createdAt: _parseDate(metadata['createdAt']),
      index: (metadata['index'] as num?)?.toInt() ?? 0,
    );
  }

  LessonPlan _parsePlanFromMetadata(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final metadata = doc.data() ?? {};
    final stepCount = (metadata['stepCount'] as num?)?.toInt() ?? 0;

    List<LessonStepData> steps = [];
    if (metadata['steps'] is List) {
      steps = (metadata['steps'] as List)
          .map((s) => LessonStepData.fromMap(Map<String, dynamic>.from(s)))
          .toList();
    } else if (stepCount > 0) {
      steps = List.generate(
        stepCount,
        (i) => LessonStepData(
          id: 'placeholder_$i',
          type: 'flashcard',
        ),
      );
    }

    return LessonPlan(
      id: metadata['id'] as String? ?? doc.id,
      title: metadata['title'] as String? ?? '',
      category: metadata['category'] as String? ?? '',
      categoryEmoji: metadata['categoryEmoji'] as String? ?? '📚',
      categoryLottieUrl: metadata['categoryLottieUrl'] as String?,
      categoryBackgroundImageUrl: metadata['categoryBackgroundImageUrl'] as String? ?? metadata['categoryBgUrl'] as String?,
      emoji: metadata['emoji'] as String? ?? '📝',
      lottieUrl: metadata['lottieUrl'] as String?,
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
    'categoryLottieUrl': plan.categoryLottieUrl,
    'categoryBackgroundImageUrl': plan.categoryBackgroundImageUrl,
    'emoji': plan.emoji,
    'lottieUrl': plan.lottieUrl,
    'creatorId': plan.creatorId,
    'createdAt': plan.createdAt?.toIso8601String(),
    'index': plan.index,
    'stepCount': plan.steps.length,
    'schemaVersion': _schemaVersion,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  Future<void> _writePlan(LessonPlan plan) async {
    final metadataRef = _plans.doc(plan.id);
    final stepsRef = metadataRef.collection('steps');
    final existingSteps = await stepsRef.get();
    final existingById = {for (final doc in existingSteps.docs) doc.id: doc};
    final retainedIds = plan.steps.map((step) => step.id).toSet();
    final staleSteps = existingSteps.docs
        .where((doc) => !retainedIds.contains(doc.id))
        .toList();

    final operations = <void Function(WriteBatch)>[];
    for (var position = 0; position < plan.steps.length; position++) {
      final step = plan.steps[position];
      final stepPosition = position;
      final data = {...step.toMap(), 'position': stepPosition};
      final existing = existingById[step.id]?.data();
      if (existing != null && _sameStepData(existing, data)) continue;
      operations.add((batch) {
        batch.set(stepsRef.doc(step.id), data);
      });
    }
    for (final staleStep in staleSteps) {
      operations.add((batch) => batch.delete(staleStep.reference));
    }

    await metadataRef.set(_metadataFor(plan), SetOptions(merge: true));

    for (var start = 0; start < operations.length; start += _batchLimit) {
      final batch = _db.batch();
      final end = (start + _batchLimit).clamp(0, operations.length).toInt();
      for (final operation in operations.sublist(start, end)) {
        operation(batch);
      }
      await batch.commit();
    }

  }

  bool _sameStepData(Map<String, dynamic> existing, Map<String, dynamic> next) {
    if (existing.length != next.length) return false;
    for (final entry in next.entries) {
      if (!_sameFirestoreValue(existing[entry.key], entry.value)) return false;
    }
    return true;
  }

  bool _sameFirestoreValue(Object? a, Object? b) {
    if (a is Timestamp && b is Timestamp) {
      return a == b;
    }
    if (a is Timestamp && b is DateTime) {
      return a.toDate() == b;
    }
    if (a is DateTime && b is Timestamp) {
      return a == b.toDate();
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_sameFirestoreValue(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in b.keys) {
        if (!a.containsKey(key) || !_sameFirestoreValue(a[key], b[key])) {
          return false;
        }
      }
      return true;
    }
    return a == b;
  }

  @override
  Future<void> save(LessonPlan plan, {int? nextIndex}) async {
    final docRef = _plans.doc(plan.id);
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
      final lastPlan = await _plans
          .orderBy('index', descending: true)
          .limit(1)
          .get();
      if (lastPlan.docs.isNotEmpty) {
        index =
            ((lastPlan.docs.first.data()['index'] as num?)?.toInt() ?? 0) + 1;
      } else if ((await _plans.limit(1).get()).docs.isNotEmpty) {
        index = 1;
      }
    }

    final normalizedPlan = LessonPlan(
      id: plan.id,
      title: plan.title,
      category: plan.category,
      categoryEmoji: plan.categoryEmoji,
      categoryLottieUrl: plan.categoryLottieUrl,
      categoryBackgroundImageUrl: plan.categoryBackgroundImageUrl,
      emoji: plan.emoji,
      lottieUrl: plan.lottieUrl,
      steps: plan.steps,
      creatorId: plan.creatorId,
      createdAt: createdAt,
      index: index,
    );

    await _writePlan(normalizedPlan);
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
  }

  @override
  Future<void> updateIndices(List<LessonPlan> plans) async {
    final operations = <void Function(WriteBatch)>[];
    for (var index = 0; index < plans.length; index++) {
      final plan = plans[index];
      final lessonIndex = index;
      operations.add(
        (batch) => batch.update(_plans.doc(plan.id), {'index': lessonIndex}),
      );
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

  @override
  Future<BackupResult> backupLessonPlans({
    void Function(double progress, String status)? onProgress,
  }) async {
    onProgress?.call(0.0, 'Fetching lesson plans data...');

    final sourcePlansRef = _db.collection('lesson_plans_v2');
    final targetPlansRef = _db.collection('backup_lesson_plans');

    final sourcePlansSnapshot = await sourcePlansRef.get();
    final targetPlansSnapshot = await targetPlansRef.get();

    final sourceDocs = sourcePlansSnapshot.docs;
    final targetDocs = targetPlansSnapshot.docs;

    final sourcePlanIds = sourceDocs.map((d) => d.id).toSet();
    final targetPlanMap = {for (final d in targetDocs) d.id: d};

    int updatedPlans = 0;
    int updatedSteps = 0;
    int deletedPlans = 0;
    int deletedSteps = 0;
    int skippedCount = 0;

    final totalPlans = sourceDocs.length;

    for (var i = 0; i < totalPlans; i++) {
      final sourcePlanDoc = sourceDocs[i];
      final planId = sourcePlanDoc.id;
      final sourcePlanData = sourcePlanDoc.data();
      final planTitle = sourcePlanData['title'] as String? ?? planId;

      final currentProgress =
          0.05 + (0.85 * ((i + 1) / (totalPlans == 0 ? 1 : totalPlans)));
      onProgress?.call(
        currentProgress,
        'Backing up lesson plan (${i + 1}/$totalPlans): $planTitle',
      );

      final targetPlanDoc = targetPlanMap[planId];
      final targetPlanData = targetPlanDoc?.data();

      final operations = <void Function(WriteBatch)>[];

      // Compare main document data
      if (!_sameFirestoreDataMap(sourcePlanData, targetPlanData)) {
        operations.add(
          (batch) => batch.set(targetPlansRef.doc(planId), sourcePlanData),
        );
        updatedPlans++;
      } else {
        skippedCount++;
      }

      // Check steps subcollection
      final sourceStepsRef = sourcePlanDoc.reference.collection('steps');
      final targetStepsRef = targetPlansRef.doc(planId).collection('steps');

      final sourceStepsSnapshot = await sourceStepsRef.get();
      final targetStepsSnapshot = await targetStepsRef.get();

      final targetStepMap = {
        for (final doc in targetStepsSnapshot.docs) doc.id: doc,
      };
      final sourceStepIds = sourceStepsSnapshot.docs.map((d) => d.id).toSet();

      // Check source steps vs target steps
      for (final sourceStepDoc in sourceStepsSnapshot.docs) {
        final stepId = sourceStepDoc.id;
        final sourceStepData = sourceStepDoc.data();
        final targetStepDoc = targetStepMap[stepId];
        final targetStepData = targetStepDoc?.data();

        if (!_sameFirestoreDataMap(sourceStepData, targetStepData)) {
          operations.add(
            (batch) => batch.set(targetStepsRef.doc(stepId), sourceStepData),
          );
          updatedSteps++;
        } else {
          skippedCount++;
        }
      }

      // Check deleted steps in target
      for (final targetStepDoc in targetStepsSnapshot.docs) {
        if (!sourceStepIds.contains(targetStepDoc.id)) {
          operations.add((batch) => batch.delete(targetStepDoc.reference));
          deletedSteps++;
        }
      }

      // Commit operations in batches
      for (var start = 0; start < operations.length; start += _batchLimit) {
        final batch = _db.batch();
        final end = (start + _batchLimit).clamp(0, operations.length).toInt();
        for (final op in operations.sublist(start, end)) {
          op(batch);
        }
        await batch.commit();
      }
    }

    // Prune target plans that no longer exist in source
    onProgress?.call(0.92, 'Checking and pruning deleted lesson plans...');
    for (final targetPlanDoc in targetDocs) {
      if (!sourcePlanIds.contains(targetPlanDoc.id)) {
        final targetStepsSnapshot =
            await targetPlanDoc.reference.collection('steps').get();
        final operations = <void Function(WriteBatch)>[];
        for (final stepDoc in targetStepsSnapshot.docs) {
          operations.add((batch) => batch.delete(stepDoc.reference));
        }
        operations.add((batch) => batch.delete(targetPlanDoc.reference));

        for (var start = 0; start < operations.length; start += _batchLimit) {
          final batch = _db.batch();
          final end = (start + _batchLimit).clamp(0, operations.length).toInt();
          for (final op in operations.sublist(start, end)) {
            op(batch);
          }
          await batch.commit();
        }

        deletedPlans++;
        deletedSteps += targetStepsSnapshot.docs.length;
      }
    }

    onProgress?.call(1.0, 'Backup completed');

    return BackupResult(
      totalSourcePlans: totalPlans,
      updatedPlans: updatedPlans,
      updatedSteps: updatedSteps,
      deletedPlans: deletedPlans,
      deletedSteps: deletedSteps,
      skippedCount: skippedCount,
    );
  }

  bool _sameFirestoreDataMap(
    Map<String, dynamic>? a,
    Map<String, dynamic>? b,
  ) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_sameFirestoreValue(a[key], b[key])) return false;
    }
    return true;
  }
}
