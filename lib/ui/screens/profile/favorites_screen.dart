import 'dart:async';
import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/progress_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/core/utils/error_handler.dart';

class _IndexedWord {
  final WordEntry word;
  final String category;
  late final String _searchText =
      '${word.thai} ${word.english} ${word.phonetic} $category'.toLowerCase();

  _IndexedWord(this.word, this.category);

  bool matches(String query) => _searchText.contains(query);
}

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Future<List<WordEntry>>? _wordsFuture;
  final AudioService _audio = AudioService.instance;
  String _selectedCategory = 'Favorites';
  List<LessonPlan> _allPlans = [];
  List<WordEntry> _favoriteWords = [];
  Set<String> _favoriteIds = {};
  Map<String, List<_IndexedWord>> _wordsByCategory = {};
  Map<String, List<LessonPlan>> _plansByCategory = {};

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    dataService.addListener(_handleDataChanged);
  }

  @override
  void dispose() {
    dataService.removeListener(_handleDataChanged);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        dataService.getAllLessonPlans(),
        dataService.getFavoriteWords(),
      ]);

      if (mounted) {
        setState(() {
          _allPlans = results[0] as List<LessonPlan>;
          _favoriteWords = results[1] as List<WordEntry>;
          _favoriteIds = _favoriteWords.map((word) => word.stableId).toSet();
          _rebuildSearchIndex();
        });
        _refreshWords();
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    }
  }

  Future<void> _handleDataChanged() async {
    try {
      final results = await Future.wait([
        dataService.getAllLessonPlans(),
        dataService.getFavoriteWords(),
      ]);
      if (!mounted) return;

      setState(() {
        _allPlans = results[0] as List<LessonPlan>;
        _plansByCategory = _groupPlansByCategory(_allPlans);
        _favoriteWords = results[1] as List<WordEntry>;
        _favoriteIds = _favoriteWords.map((word) => word.stableId).toSet();
        _rebuildSearchIndex();
      });
      _refreshWords();
    } catch (e) {
      debugPrint("Error refreshing favorite IDs: $e");
    }
  }

  void _refreshWords() {
    if (!mounted) return;

    List<WordEntry> words;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      words = _wordsByCategory.values
          .expand((entries) => entries)
          .where((entry) => entry.matches(query))
          .map((entry) => entry.word)
          .toList(growable: false);
    } else if (_selectedCategory == 'Favorites') {
      words = _favoriteWords;
    } else {
      words = (_wordsByCategory[_selectedCategory] ?? const <_IndexedWord>[])
          .where((entry) => entry.category == _selectedCategory)
          .map((entry) => entry.word)
          .toList(growable: false);
    }
    _wordsFuture = Future.value(words);
  }

  void _rebuildSearchIndex() {
    final progress = progressService;
    final grouped = _groupPlansByCategory(_allPlans);
    _plansByCategory = grouped;
    _wordsByCategory = {};
    for (final entry in grouped.entries) {
      final seenWords = <String>{};
      final indexedWords = <_IndexedWord>[];
      for (final plan in entry.value) {
        if (progress.getCompleted(plan.id) <= 0) continue;
        for (final step in plan.steps) {
          final word = _extractWordFromStep(step);
          if (word == null || !seenWords.add(word.stableId)) continue;
          indexedWords.add(_IndexedWord(word, entry.key));
        }
      }
      _wordsByCategory[entry.key] = indexedWords;
    }
  }

  Map<String, List<LessonPlan>> _groupPlansByCategory(List<LessonPlan> plans) {
    final grouped = <String, List<LessonPlan>>{};
    for (final plan in plans) {
      grouped.putIfAbsent(plan.category, () => []).add(plan);
    }
    return grouped;
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() => _searchQuery = value);
      _refreshWords();
    });
  }

  WordEntry? _extractWordFromStep(LessonStepData step) {
    if (step.thai.isNotEmpty && step.english.isNotEmpty) {
      return step.toWordEntry();
    }

    if (step.type.toLowerCase().contains('fill') ||
        step.type.toLowerCase().contains('blank')) {
      if (step.question.isNotEmpty && step.answer.isNotEmpty) {
        return WordEntry(
          id: 'temp',
          thai: step.answer,
          phonetic: '',
          english: step.question,
          category: 'extracted',
        );
      }
    }

    if (step.thai.isNotEmpty) {
      return WordEntry(
        id: 'temp',
        thai: step.thai,
        phonetic: step.phonetic,
        english: step.english.isNotEmpty
            ? step.english
            : (step.answer.isNotEmpty ? step.answer : 'Vocabulary'),
        category: 'extracted',
      );
    }

    return null;
  }

  Future<void> _speak(String text) async {
    await _audio.speakThai(text);
  }

  Future<void> _toggleFavorite(WordEntry word) async {
    final wordId = word.stableId;
    setState(() {
      if (_favoriteIds.contains(wordId)) {
        _favoriteIds.remove(wordId);
      } else {
        _favoriteIds.add(wordId);
      }
    });
    await dataService.toggleFavorite(word);
    if (_selectedCategory == 'Favorites') {
      _refreshWords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = _plansByCategory.keys.toList();
    final progress = Provider.of<ProgressService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ThaiAppBar(title: "Vocabulary"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: ThaiSearchBar(
              controller: _searchController,
              hintText: "Search words or categories...",
              onChanged: (val) {
                _queueSearch(val);
              },
              onClear: () {
                _searchDebounce?.cancel();
                _searchController.clear();
                setState(() => _searchQuery = "");
                _refreshWords();
              },
            ),
          ),
          if (_searchQuery.isEmpty)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Favorites', true),
                  ...categories.map((categoryName) {
                    final categoryPlans =
                        _plansByCategory[categoryName] ?? const <LessonPlan>[];
                    final isUnlocked = categoryPlans.any(
                      (lessonPlan) => progress.getCompleted(lessonPlan.id) > 0,
                    );
                    return _buildCategoryChip(categoryName, isUnlocked);
                  }),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<WordEntry>>(
              future: _wordsFuture,
              builder: (context, snapshot) {
                if (_wordsFuture == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(ErrorHandler.getMessage(snapshot.error)),
                  );
                }

                final words = snapshot.data ?? [];

                if (words.isEmpty) {
                  return ThaiEmptyState(
                    icon: _selectedCategory == 'Favorites'
                        ? Icons.favorite_border
                        : Icons.menu_book_rounded,
                    title: _selectedCategory == 'Favorites'
                        ? "No favorites yet"
                        : "No words in this category",
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final word = words[index];
                    return _buildWordCard(word);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category, bool isUnlocked) {
    final theme = Theme.of(context);
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          category,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isUnlocked
                      ? theme.textTheme.bodyLarge?.color
                      : theme.disabledColor),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onSelected: isUnlocked
            ? (selected) {
                setState(() {
                  _selectedCategory = category;
                  _refreshWords();
                });
              }
            : null,
        backgroundColor: theme.cardColor,
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.1),
          ),
        ),
        avatar: !isUnlocked
            ? Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: theme.disabledColor,
              )
            : null,
      ),
    );
  }

  Widget _buildWordCard(WordEntry word) {
    final theme = Theme.of(context);
    final isFav = _favoriteIds.contains(word.stableId);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.light ? 0.04 : 0.2,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  word.thai,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleLarge?.color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.phonetic,
                  style: TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: theme.disabledColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  word.english,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.textTheme.bodyMedium?.color?.withValues(
                      alpha: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              onPressed: () => _toggleFavorite(word),
              icon: Icon(
                isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isFav ? Colors.amber : theme.disabledColor,
                size: 24,
              ),
            ),
          ),
          Positioned(
            bottom: 10,
            right: 12,
            child: GestureDetector(
              onTap: () => _speak(word.thai),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
