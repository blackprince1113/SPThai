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
      // Light metadata query: ONLY reads main lesson documents (1 fast request!),
      // without fetching subcollections for every single lesson in the database.
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

    // Fallback: if subcollection 'steps' is empty, check if steps are array in metadata
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
      emoji: metadata['emoji'] as String? ?? '📝',
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
      // Dummy step list of length stepCount so plan.steps.length returns correct step count
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

  Future<void> _writePlan(LessonPlan plan) async {
    final metadataRef = _plans.doc(plan.id);
    final stepsRef = metadataRef.collection('steps');
    final existingSteps = await stepsRef.get();
    final retainedIds = plan.steps.map((step) => step.id).toSet();
    final staleSteps = existingSteps.docs
        .where((doc) => !retainedIds.contains(doc.id))
        .toList();

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
      emoji: plan.emoji,
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
}
