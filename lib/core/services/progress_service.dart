import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'data_service.dart';
import 'package:superthai/features/progress/data/progress_repository.dart';

class ProgressService extends ChangeNotifier {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  static ProgressService get instance => _instance;

  SharedPreferences? _prefs;
  final Set<String> _triedLessonIds = {};
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, Set<int>> _completedStepIndices = {};
  final Map<String, Set<String>> _completedStepIds = {};
  final Map<String, String> _lastStepIds = {};
  final Set<String> _pendingProgressDeletes = {};
  final Set<String> _dirtyProgressLessonIds = {};
  String? _lastLessonId;
  double _lastScrollOffset = 0.0;
  int _streakCount = 0;
  DateTime? _lastActivityDate;
  Future<void>? _progressWriteFuture;
  bool _progressWriteRequested = false;
  bool _userMetadataDirty = false;
  late final ProgressRepository _progressRepository = ProgressRepository(_db);

  static const String _triedLessonsKey = 'tried_lessons';
  static const String _localProgressKey = 'local_progress';
  static const String usersCollection = 'users';

  int get streakCount => _streakCount;
  String? get lastLessonId => _lastLessonId;
  double get lastScrollOffset => _lastScrollOffset;
  bool get isTrialLimitReached => _triedLessonIds.length >= 3;
  int get triedLessonsCount => _triedLessonIds.length;

  ProgressService._internal() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadLocalProgress();

    AuthService.instance.userChanges.listen(_handleUserChange);
  }

  Future<void> _handleUserChange(User? user) async {
    if (user != null) {
      await _loadProgressFromFirestore();
    } else if (AuthService.instance.currentUser == null) {
      _completedStepIndices.clear();
      _completedStepIds.clear();
      _lastStepIds.clear();
      _dirtyProgressLessonIds.clear();
      _pendingProgressDeletes.clear();
      _loadLocalProgress();
      notifyListeners();
    }
  }

  void _loadLocalProgress() {
    if (_prefs == null) return;

    final tried = _prefs!.getStringList(_triedLessonsKey);
    if (tried != null) {
      _triedLessonIds.clear();
      _triedLessonIds.addAll(tried);
    }

    _streakCount = _prefs!.getInt('streak_count') ?? 0;
    _lastLessonId = _prefs!.getString('last_lesson_id');
    _lastScrollOffset = _prefs!.getDouble('last_scroll_offset') ?? 0.0;
    final lastDateStr = _prefs!.getString('last_activity_date');
    if (lastDateStr != null) {
      _lastActivityDate = DateTime.parse(lastDateStr);
      _checkStreakExpiry();
    }

    if (AuthService.instance.currentUser == null) {
      final localProg = _prefs!.getString(_localProgressKey);
      if (localProg != null) {
        try {
          fromMap(jsonDecode(localProg));
        } catch (e) {
          debugPrint("Error decoding local progress: $e");
        }
      }
    }
  }

  bool canTryLesson(String lessonId) {
    if (AuthService.instance.currentUser != null) return true;
    if (_triedLessonIds.contains(lessonId)) return true;
    return _triedLessonIds.length < 3;
  }

  void markStepAsCompleted(String lessonId, int stepIndex, {String? stepId}) {
    _lastLessonId = lessonId;
    final indices = _completedStepIndices.putIfAbsent(lessonId, () => {});
    final addedIndex = indices.add(stepIndex);
    var addedStepId = false;
    if (stepId != null && stepId.isNotEmpty) {
      addedStepId = _completedStepIds
          .putIfAbsent(lessonId, () => {})
          .add(stepId);
      _lastStepIds[lessonId] = stepId;
    }
    if (addedIndex || addedStepId) {
      _dirtyProgressLessonIds.add(lessonId);
      if (addedIndex) {
        _updateStreak();
        _userMetadataDirty = true;
      }

      if (AuthService.instance.currentUser != null) {
        _saveProgressToFirestore();
      } else {
        _triedLessonIds.add(lessonId);
        _saveLocalProgress();
      }
      notifyListeners();
    }
  }

  void _updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_lastActivityDate == null) {
      _streakCount = 1;
    } else {
      final lastDate = DateTime(
        _lastActivityDate!.year,
        _lastActivityDate!.month,
        _lastActivityDate!.day,
      );
      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        _streakCount++;
      } else if (difference > 1) {
        _streakCount = 1;
      }
    }
    _lastActivityDate = today;
  }

  void _checkStreakExpiry() {
    if (_lastActivityDate == null) return;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastActivityDate!.year,
      _lastActivityDate!.month,
      _lastActivityDate!.day,
    );
    final difference = today.difference(lastDate).inDays;

    if (difference > 1) {
      _streakCount = 0;
      Future.microtask(() => notifyListeners());
    }
  }

  Future<void> _saveLocalProgress() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_triedLessonsKey, _triedLessonIds.toList());
    await _prefs!.setString(_localProgressKey, jsonEncode(toMap()));
    await _prefs!.setDouble('last_scroll_offset', _lastScrollOffset);
    if (_lastLessonId != null) {
      await _prefs!.setString('last_lesson_id', _lastLessonId!);
    }
    if (_lastActivityDate != null) {
      await _prefs!.setString(
        'last_activity_date',
        _lastActivityDate!.toIso8601String(),
      );
      await _prefs!.setInt('streak_count', _streakCount);
    }
  }

  int getCompleted(String lessonId) {
    final stepIds = _completedStepIds[lessonId];
    if (stepIds != null && stepIds.isNotEmpty) return stepIds.length;
    return _completedStepIndices[lessonId]?.length ?? 0;
  }

  Future<int> getTotalSteps(String lessonId) async {
    final plans = await DataService.instance.getAllLessonPlans();
    final plan = plans.where((p) => p.id == lessonId).firstOrNull;
    return plan?.steps.length ?? 0;
  }

  void resetProgress(String lessonId) {
    if (_lastLessonId == lessonId) {
      _lastLessonId = null;
      _userMetadataDirty = true;
    }
    if (_completedStepIndices.containsKey(lessonId)) {
      _completedStepIndices.remove(lessonId);
      _completedStepIds.remove(lessonId);
      _lastStepIds.remove(lessonId);
      if (AuthService.instance.currentUser != null) {
        _pendingProgressDeletes.add(lessonId);
        _dirtyProgressLessonIds.remove(lessonId);
        _saveProgressToFirestore();
      } else {
        _saveLocalProgress();
      }
      notifyListeners();
    }
  }

  Future<void> _saveProgressToFirestore() async {
    _progressWriteRequested = true;
    final activeWrite = _progressWriteFuture;
    if (activeWrite != null) return activeWrite;

    final drain = _drainProgressWrites();
    _progressWriteFuture = drain;
    try {
      await drain;
    } finally {
      if (identical(_progressWriteFuture, drain)) {
        _progressWriteFuture = null;
      }
    }
  }

  Future<void> _drainProgressWrites() async {
    while (_progressWriteRequested) {
      _progressWriteRequested = false;
      final user = AuthService.instance.currentUser;
      if (user == null) return;
      final stepIdSnapshot = _completedStepIds.map(
        (lessonId, ids) => MapEntry(lessonId, List<String>.of(ids)),
      );
      final lastStepIdSnapshot = Map<String, String>.from(_lastStepIds);
      final lessonIdSnapshot = _lastLessonId;
      final streakSnapshot = _streakCount;
      final activityDateSnapshot = _lastActivityDate;
      final dirtyLessonIds = Set<String>.from(_dirtyProgressLessonIds);
      final deletedLessonIds = Set<String>.from(_pendingProgressDeletes);
      final writeMetadata = _userMetadataDirty;
      _dirtyProgressLessonIds.clear();
      _pendingProgressDeletes.clear();
      _userMetadataDirty = false;

      try {
        final lessonsToSave = <String, Map<String, dynamic>>{};
        for (final lessonId in dirtyLessonIds) {
          if (deletedLessonIds.contains(lessonId)) continue;
          lessonsToSave[lessonId] = {
            'completedStepIds': (stepIdSnapshot[lessonId] ?? const <String>[])
                .toSet()
                .toList(),
            'lastStepId': lastStepIdSnapshot[lessonId],
            'updatedAt': FieldValue.serverTimestamp(),
            'schemaVersion': 3,
          };
        }
        await _progressRepository.saveLessons(
          user.uid,
          lessonsToSave,
          deleteLessonIds: deletedLessonIds,
        );
      } catch (e) {
        _dirtyProgressLessonIds.addAll(dirtyLessonIds);
        _pendingProgressDeletes.addAll(deletedLessonIds);
        debugPrint("Error saving per-lesson progress: $e");
      }

      if (!writeMetadata) continue;
      try {
        final userRef = _db.collection(usersCollection).doc(user.uid);
        await userRef.set({
          'lastLessonId': lessonIdSnapshot,
          'lastScrollOffset': _lastScrollOffset,
          'streakCount': streakSnapshot,
          'lastActivityDate': activityDateSnapshot != null
              ? Timestamp.fromDate(activityDateSnapshot)
              : null,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        _userMetadataDirty = true;
        debugPrint("Error saving user progress metadata: $e");
      }
    }
  }

  Future<void> _loadProgressFromFirestore() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    try {
      final results = await Future.wait<Object>([
        _db.collection(usersCollection).doc(user.uid).get(),
        _progressRepository.getAll(user.uid).catchError((Object e) {
          debugPrint("Could not read per-lesson progress: $e");
          return <String, Map<String, dynamic>>{};
        }),
      ]);
      final doc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final storedProgress =
          results[1] as Map<String, Map<String, dynamic>>;

      final mergedStepIds = <String, Set<String>>{};
      final mergedLastStepIds = <String, String>{};

      for (final entry in storedProgress.entries) {
        final lessonId = entry.key;
        final stored = entry.value;
        final storedStepIds = _parseStrings(stored['completedStepIds']);
        final lastStepId = stored['lastStepId'] as String?;

        mergedStepIds[lessonId] = storedStepIds;
        if (lastStepId != null) {
          mergedLastStepIds[lessonId] = lastStepId;
        }
      }

      _completedStepIds
        ..clear()
        ..addAll(mergedStepIds);
      _lastStepIds
        ..clear()
        ..addAll(mergedLastStepIds);

      if (doc.exists) {
        final data = doc.data()!;
        _lastLessonId = data['lastLessonId'];
        _lastScrollOffset =
            (data['lastScrollOffset'] as num?)?.toDouble() ?? 0.0;
        _streakCount = data['streakCount'] ?? 0;
        if (data['lastActivityDate'] != null) {
          _lastActivityDate = (data['lastActivityDate'] as Timestamp).toDate();
          _checkStreakExpiry();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading progress: $e");
    }
  }

  Set<String> _parseStrings(Object? value) {
    if (value is! Iterable) return {};
    return value.whereType<String>().toSet();
  }

  Map<String, dynamic> toMap() {
    return _completedStepIndices.map(
      (key, value) => MapEntry(key, value.toList()),
    );
  }

  void fromMap(Map<String, dynamic> map) {
    map.forEach((key, value) {
      _completedStepIndices[key] = (value as List).map((e) => e as int).toSet();
    });
    notifyListeners();
  }

  void saveScrollOffset(double offset) {
    if ((_lastScrollOffset - offset).abs() < 2.0) return;
    _lastScrollOffset = offset;
    _userMetadataDirty = true;
    _prefs?.setDouble('last_scroll_offset', offset);
    if (AuthService.instance.currentUser != null) {
      _saveProgressToFirestore();
    }
  }

  void updateLastLesson(String lessonId) {
    _lastLessonId = lessonId;
    if (AuthService.instance.currentUser != null) {
      _userMetadataDirty = true;
      _saveProgressToFirestore();
    } else {
      _saveLocalProgress();
    }
    notifyListeners();
  }
}

final progressService = ProgressService.instance;
