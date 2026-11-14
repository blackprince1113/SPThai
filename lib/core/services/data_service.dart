import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superthai/features/vocabulary/data/favorite_repository.dart';
import 'package:superthai/features/lessons/data/firestore_lesson_repository.dart';
import 'package:superthai/features/lessons/data/lesson_repository.dart';
import '../models/models.dart';

class DataService extends ChangeNotifier {
  static final DataService _instance = DataService._internal();
  static DataService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late final LessonRepository _lessonRepository = FirestoreLessonRepository(
    _db,
  );

  List<LessonPlan>? _cachedPlans;
  Future<List<LessonPlan>>? _plansLoadFuture;
  int _plansRevision = 0;
  DateTime? _lastBackgroundSyncAt;
  final Map<String, List<WordEntry>> _wordsByCategoryCache = {};
  final ValueNotifier<FavoriteChange?> favoriteChanges =
      ValueNotifier<FavoriteChange?>(null);
  List<QueryDocumentSnapshot<Map<String, dynamic>>>? _discoverFallbackDocs;
  bool _discoverCompositeIndexUnavailable = false;

  static const String newsCollection = 'discover';
  static const String _lessonCacheKey = 'cached_lesson_plans_v2';
  static const Duration _backgroundSyncInterval = Duration(minutes: 5);
  static const int _categoryLessonLoadConcurrency = 4;

  DataService._internal() {
    _initLocalCache();
  }

  Future<void> _initLocalCache() async {
    final plans = await _loadFromLocalCache();
    if (plans != null && plans.isNotEmpty && _cachedPlans == null) {
      _cachedPlans = plans;
      notifyListeners();
    }
  }

  Future<List<LessonPlan>?> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_lessonCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded
            .map((item) => LessonPlan.fromMap(Map<String, dynamic>.from(item)))
            .toList();
      }
    } catch (e) {
      debugPrint("Error reading local lesson cache: $e");
    }
    return null;
  }

  Future<void> _savePlansToLocalCache(List<LessonPlan> plans) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(plans.map((p) => p.toMap()).toList());
      await prefs.setString(_lessonCacheKey, jsonStr);
    } catch (e) {
      debugPrint("Error writing local lesson cache: $e");
    }
  }

  Future<List<LessonPlan>> getAllLessonPlans() async {
    if (_cachedPlans != null) {
      _syncPlansInBackground();
      return _cachedPlans!;
    }

    final diskPlans = await _loadFromLocalCache();
    if (diskPlans != null && diskPlans.isNotEmpty) {
      _cachedPlans = diskPlans;
      _syncPlansInBackground();
      return diskPlans;
    }

    if (_plansLoadFuture != null) {
      return _plansLoadFuture!;
    }

    final load = _loadLessonPlans();
    _plansLoadFuture = load;
    final revision = _plansRevision;
    try {
      final plans = await load;
      if (revision == _plansRevision && identical(_plansLoadFuture, load)) {
        _cachedPlans = plans;
        if (plans.isNotEmpty) {
          _savePlansToLocalCache(plans);
        }
      }
      return plans;
    } finally {
      if (identical(_plansLoadFuture, load)) {
        _plansLoadFuture = null;
      }
    }
  }

  void _syncPlansInBackground() {
    if (_plansLoadFuture != null) return;
    final now = DateTime.now();
    final lastSync = _lastBackgroundSyncAt;
    if (lastSync != null &&
        now.difference(lastSync) < _backgroundSyncInterval) {
      return;
    }
    _lastBackgroundSyncAt = now;
    final revision = _plansRevision;
    final load = _loadLessonPlans();
    _plansLoadFuture = load;
    load
        .then((plans) {
          if (revision == _plansRevision && plans.isNotEmpty) {
            _cachedPlans = plans;
            _savePlansToLocalCache(plans);
            notifyListeners();
          }
        })
        .catchError((e) {
          debugPrint("Background sync error: $e");
        })
        .whenComplete(() {
          if (identical(_plansLoadFuture, load)) {
            _plansLoadFuture = null;
          }
        });
  }

  Future<List<LessonPlan>> _loadLessonPlans() async {
    return _lessonRepository.getAll();
  }

  Future<LessonPlan?> getLessonPlanById(String lessonId) async {
    final cachedPlans = _cachedPlans;
    if (cachedPlans != null) {
      try {
        final plan = cachedPlans.firstWhere((p) => p.id == lessonId);
        if (plan.steps.isNotEmpty &&
            !plan.steps.any((s) => s.id.startsWith('placeholder_'))) {
          return plan;
        }
      } catch (_) {}
    }

    final fullPlan = await _lessonRepository.getById(lessonId);
    if (fullPlan != null && _cachedPlans != null) {
      final index = _cachedPlans!.indexWhere((p) => p.id == lessonId);
      if (index != -1) {
        _cachedPlans![index] = fullPlan;
      }
    }
    return fullPlan;
  }

  void unloadLesson(String? lessonId) {
    if (lessonId == null || _cachedPlans == null) return;
    final index = _cachedPlans!.indexWhere((p) => p.id == lessonId);
    if (index != -1) {
      final plan = _cachedPlans![index];
      _cachedPlans![index] = LessonPlan(
        id: plan.id,
        title: plan.title,
        category: plan.category,
        categoryEmoji: plan.categoryEmoji,
        emoji: plan.emoji,
        steps: List.generate(
          plan.steps.length,
          (i) => LessonStepData(id: 'placeholder_$i', type: 'flashcard'),
        ),
        creatorId: plan.creatorId,
        createdAt: plan.createdAt,
        index: plan.index,
      );
    }
    _wordsByCategoryCache.clear();
  }

  Future<void> updateLessonIndices(List<LessonPlan> plans) async {
    await _lessonRepository.updateIndices(plans);
    _invalidatePlansCache();
    notifyListeners();
  }

  Future<List<WordEntry>> getWordsByCategory(String category) async {
    if (_wordsByCategoryCache.containsKey(category)) {
      return _wordsByCategoryCache[category]!;
    }
    final revision = _plansRevision;
    final plans = await getAllLessonPlans();
    if (revision != _plansRevision) {
      return getWordsByCategory(category);
    }
    final List<WordEntry> words = [];
    final Set<String> seenIds = {};

    final categoryPlans = plans.where((p) => p.category == category).toList();
    final resolvedPlans = <LessonPlan?>[];
    for (
      var start = 0;
      start < categoryPlans.length;
      start += _categoryLessonLoadConcurrency
    ) {
      final end = (start + _categoryLessonLoadConcurrency)
          .clamp(0, categoryPlans.length)
          .toInt();
      final batch = categoryPlans.sublist(start, end);
      resolvedPlans.addAll(
        await Future.wait(
          batch.map((plan) {
            if (!plan.steps.any((step) => step.id.startsWith('placeholder_'))) {
              return Future<LessonPlan?>.value(plan);
            }
            return getLessonPlanById(plan.id);
          }),
        ),
      );
    }

    for (final fullPlan in resolvedPlans) {
      if (fullPlan != null) {
        for (var step in fullPlan.steps) {
          final word = step.toWordEntry();
          if (word.thai.isNotEmpty && !seenIds.contains(word.stableId)) {
            words.add(word);
            seenIds.add(word.stableId);
          }
        }
      }
    }
    final cachedWords = List<WordEntry>.unmodifiable(words);
    _wordsByCategoryCache[category] = cachedWords;
    return cachedWords;
  }

  Future<void> addLessonPlan(LessonPlan plan) async {
    final cachedPlans = _cachedPlans;
    final nextIndex =
        plan.index == 0 && cachedPlans != null && cachedPlans.isNotEmpty
        ? cachedPlans
                  .map((existingPlan) => existingPlan.index)
                  .reduce((a, b) => a > b ? a : b) +
              1
        : null;
    await _lessonRepository.save(plan, nextIndex: nextIndex);
    _invalidatePlansCache();
    notifyListeners();
  }

  Future<void> deleteLessonPlan(String planId) async {
    await _lessonRepository.delete(planId);
    _invalidatePlansCache();
    notifyListeners();
  }

  void _invalidatePlansCache() {
    _plansRevision++;
    _cachedPlans = null;
    _plansLoadFuture = null;
    _lastBackgroundSyncAt = null;
    _wordsByCategoryCache.clear();
  }

  Future<LessonPlan?> getLessonPlanByCategory(String category) async {
    return _lessonRepository.getByCategory(category);
  }

  Future<void> toggleFavorite(WordEntry word) async {
    final wasFavorite = await FavoriteRepository.instance.isFavorite(
      word.stableId,
    );
    await FavoriteRepository.instance.toggleFavorite(word);
    favoriteChanges.value = FavoriteChange(
      word: word,
      isFavorite: !wasFavorite,
    );
  }

  Future<bool> isFavorite(String wordId) async {
    return FavoriteRepository.instance.isFavorite(wordId);
  }

  Future<List<WordEntry>> getFavoriteWords() async {
    return FavoriteRepository.instance.getFavoriteWords();
  }

  Future<void> migrateFavorites(String userId) async {
    await FavoriteRepository.instance.migrateLocalFavorites(userId);
  }

  Future<void> addDiscoverItem(DiscoverItem item) async {
    await _db
        .collection(newsCollection)
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
    _discoverFallbackDocs = null;
  }

  Future<void> deleteDiscoverItem(String id) async {
    await _db.collection(newsCollection).doc(id).delete();
    _discoverFallbackDocs = null;
  }

  Future<DiscoverPage> getDiscoverPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    if (_discoverCompositeIndexUnavailable) {
      return _getDiscoverPageFromFallback(startAfter: startAfter, limit: limit);
    }

    Query<Map<String, dynamic>> query = _db
        .collection(newsCollection)
        .orderBy('isPinned', descending: true)
        .orderBy('date', descending: true)
        .limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    try {
      final snapshot = await query.get();
      return DiscoverPage(
        items: snapshot.docs
            .map((doc) => DiscoverItem.fromMap(doc.data()))
            .toList(growable: false),
        lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
        hasMore: snapshot.docs.length == limit,
      );
    } on FirebaseException catch (error) {
      if (error.code != 'failed-precondition') rethrow;
      _discoverCompositeIndexUnavailable = true;
      return _getDiscoverPageFromFallback(startAfter: startAfter, limit: limit);
    }
  }

  Future<DiscoverPage> _getDiscoverPageFromFallback({
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required int limit,
  }) async {
    var docs = _discoverFallbackDocs;
    if (docs == null || startAfter == null) {
      final snapshot = await _db.collection(newsCollection).get();
      docs = snapshot.docs.toList()
        ..sort((a, b) {
          final aPinned = a.data()['isPinned'] == true;
          final bPinned = b.data()['isPinned'] == true;
          if (aPinned != bPinned) return aPinned ? -1 : 1;
          return _discoverDate(
            b.data()['date'],
          ).compareTo(_discoverDate(a.data()['date']));
        });
      _discoverFallbackDocs = docs;
    }

    final cursorIndex = startAfter == null
        ? -1
        : docs.indexWhere((doc) => doc.id == startAfter.id);
    final start = cursorIndex + 1;
    final end = (start + limit).clamp(0, docs.length).toInt();
    final pageDocs = docs.sublist(start, end);
    return DiscoverPage(
      items: pageDocs
          .map((doc) => DiscoverItem.fromMap(doc.data()))
          .toList(growable: false),
      lastDocument: pageDocs.isEmpty ? startAfter : pageDocs.last,
      hasMore: end < docs.length,
    );
  }

  DateTime _discoverDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime(1970);
    return DateTime(1970);
  }
}

class FavoriteChange {
  const FavoriteChange({required this.word, required this.isFavorite});

  final WordEntry word;
  final bool isFavorite;
}

class DiscoverPage {
  final List<DiscoverItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const DiscoverPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });
}

final dataService = DataService.instance;
