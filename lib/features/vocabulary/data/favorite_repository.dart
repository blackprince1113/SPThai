import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/auth_service.dart';

class FavoriteRepository {
  FavoriteRepository._();

  static final FavoriteRepository instance = FavoriteRepository._();

  static const _usersCollection = 'users';
  static const _favoritesCollection = 'favorites';
  static const _localFavoritesKey = 'local_favorites';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Map<String, Set<String>> _favoriteIdsByUser = {};
  final Map<String, Future<Set<String>>> _favoriteIdsLoads = {};
  SharedPreferences? _prefs;

  Future<Set<String>> _loadFavoriteIds(String userId) {
    final cached = _favoriteIdsByUser[userId];
    if (cached != null) return Future.value(cached);
    return _favoriteIdsLoads.putIfAbsent(userId, () async {
      try {
        final snapshot = await _db
            .collection(_usersCollection)
            .doc(userId)
            .collection(_favoritesCollection)
            .get();
        final ids = snapshot.docs.map((doc) => doc.id).toSet();
        _favoriteIdsByUser[userId] = ids;
        return ids;
      } finally {
        _favoriteIdsLoads.remove(userId);
      }
    });
  }

  Future<bool> isFavorite(String wordId) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      final favorites = await _readLocalFavorites();
      return favorites.any(
        (word) => word.stableId == wordId || word.thai == wordId,
      );
    }
    return (await _loadFavoriteIds(user.uid)).contains(wordId);
  }

  Future<void> toggleFavorite(WordEntry word) async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      await _toggleLocalFavorite(word);
      return;
    }

    final ids = await _loadFavoriteIds(user.uid);
    final wordId = word.stableId;
    final ref = _db
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_favoritesCollection)
        .doc(wordId);
    if (ids.contains(wordId)) {
      await ref.delete();
      ids.remove(wordId);
    } else {
      await ref.set({
        ...word.toMap(),
        'id': wordId,
        'addedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      ids.add(wordId);
    }
  }

  Future<List<WordEntry>> getFavoriteWords() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return _readLocalFavorites();

    final snapshot = await _db
        .collection(_usersCollection)
        .doc(user.uid)
        .collection(_favoritesCollection)
        .orderBy('addedAt', descending: true)
        .get();
    _favoriteIdsByUser[user.uid] = snapshot.docs.map((doc) => doc.id).toSet();
    return snapshot.docs
        .map((doc) => WordEntry.fromMap(doc.data()))
        .where((word) => word.thai.isNotEmpty && word.english.isNotEmpty)
        .toList();
  }

  Future<void> migrateLocalFavorites(String userId) async {
    final localWords = await _readLocalFavorites();
    if (localWords.isEmpty) return;

    for (var start = 0; start < localWords.length; start += 450) {
      final batch = _db.batch();
      final end = (start + 450).clamp(0, localWords.length).toInt();
      for (final word in localWords.sublist(start, end)) {
        final ref = _db
            .collection(_usersCollection)
            .doc(userId)
            .collection(_favoritesCollection)
            .doc(word.stableId);
        batch.set(ref, {
          ...word.toMap(),
          'id': word.stableId,
          'addedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
    }

    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_localFavoritesKey);
    _favoriteIdsByUser.remove(userId);
  }

  Future<List<WordEntry>> _readLocalFavorites() async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = _prefs!.getStringList(_localFavoritesKey) ?? const [];
    return encoded
        .map((value) => WordEntry.fromMap(jsonDecode(value)))
        .toList();
  }

  Future<void> _toggleLocalFavorite(WordEntry word) async {
    _prefs ??= await SharedPreferences.getInstance();
    final encoded = _prefs!.getStringList(_localFavoritesKey) ?? [];
    final favorites = encoded
        .map((value) => WordEntry.fromMap(jsonDecode(value)))
        .toList();
    final index = favorites.indexWhere(
      (favorite) =>
          favorite.stableId == word.stableId ||
          (favorite.thai == word.thai && favorite.english == word.english),
    );
    if (index >= 0) {
      favorites.removeAt(index);
    } else {
      favorites.add(word);
    }
    await _prefs!.setStringList(
      _localFavoritesKey,
      favorites.map((favorite) => jsonEncode(favorite.toMap())).toList(),
    );
  }
}
