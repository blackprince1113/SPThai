import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Map<String, List<WordEntry>> _wordsByCategoryCache = {};

  static const String newsCollection = 'discover';
  DataService._internal();

  Future<List<LessonPlan>> getAllLessonPlans({
    bool forceRefresh = false,
  }) async {
    if (_cachedPlans != null && !forceRefresh) {
      return _cachedPlans!;
    }
    if (_plansLoadFuture != null && !forceRefresh) {
      return _plansLoadFuture!;
    }

    final load = _loadLessonPlans();
    _plansLoadFuture = load;
    final revision = _plansRevision;
    try {
      final plans = await load;
      if (revision == _plansRevision && identical(_plansLoadFuture, load)) {
        _cachedPlans = plans;
      }
      return plans;
    } finally {
      if (identical(_plansLoadFuture, load)) {
        _plansLoadFuture = null;
      }
    }
  }

  Future<List<LessonPlan>> _loadLessonPlans() async {
    return _lessonRepository.getAll();
  }

  Future<LessonPlan?> getLessonPlanById(String lessonId) async {
    final cachedPlans = _cachedPlans;
    if (cachedPlans != null) {
      if (!cachedPlans.any((plan) => plan.id == lessonId)) return null;
      // Catalog data may be legacy-shaped. Fetching a specific lesson goes
      // through the repository so it can migrate that lesson on demand.
      return _lessonRepository.getById(lessonId);
    }

    final inFlightLoad = _plansLoadFuture;
    if (inFlightLoad != null) {
      final plans = await inFlightLoad;
      if (!plans.any((plan) => plan.id == lessonId)) return null;
      return _lessonRepository.getById(lessonId);
    }

    return _lessonRepository.getById(lessonId);
  }

  Future<void> updateLessonIndices(List<LessonPlan> plans) async {
    await _lessonRepository.updateIndices(plans);
    _invalidatePlansCache();
    notifyListeners();
  }

  Future<List<WordEntry>> getWordsByCategory(
    String category, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _wordsByCategoryCache.containsKey(category)) {
      return _wordsByCategoryCache[category]!;
    }
    final revision = _plansRevision;
    final plans = await getAllLessonPlans(forceRefresh: forceRefresh);
    if (revision != _plansRevision) {
      return getWordsByCategory(category);
    }
    final List<WordEntry> words = [];
    final Set<String> seenIds = {};

    for (var plan in plans.where((p) => p.category == category)) {
      for (var step in plan.steps) {
        final word = step.toWordEntry();
        if (word.thai.isNotEmpty && !seenIds.contains(word.stableId)) {
          words.add(word);
          seenIds.add(word.stableId);
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
    _wordsByCategoryCache.clear();
  }

  Future<LessonPlan?> getLessonPlanByCategory(String category) async {
    return _lessonRepository.getByCategory(category);
  }

  Future<void> toggleFavorite(WordEntry word) async {
    await FavoriteRepository.instance.toggleFavorite(word);
    notifyListeners();
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
  }

  Future<void> deleteDiscoverItem(String id) async {
    await _db.collection(newsCollection).doc(id).delete();
  }

  Future<List<DiscoverItem>> getAllDiscoverItems() async {
    final snapshot = await _db.collection(newsCollection).get();
    final items = snapshot.docs
        .map((doc) => DiscoverItem.fromMap(doc.data()))
        .toList();

    items.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.date.compareTo(a.date);
    });

    return items;
  }
}

final dataService = DataService.instance;
