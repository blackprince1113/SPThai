import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/services/progress_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/core/utils/error_handler.dart';

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

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    dataService.addListener(_handleDataChanged);
  }

  @override
  void dispose() {
    dataService.removeListener(_handleDataChanged);
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
        });
        _refreshWords();
      }
    } catch (e) {
      debugPrint("Error loading initial data: $e");
    }
  }

  Future<void> _handleDataChanged() async {
    try {
      final favoriteWords = await dataService.getFavoriteWords();
      if (!mounted) return;

      setState(() {
        _favoriteWords = favoriteWords;
        _favoriteIds = favoriteWords.map((word) => word.stableId).toSet();
      });
      _refreshWords();
    } catch (e) {
      debugPrint("Error refreshing favorite IDs: $e");
    }
  }

  void _refreshWords() {
    if (!mounted) return;

    setState(() {
      if (_searchQuery.isNotEmpty) {
        final List<WordEntry> filteredWords = [];
        final Set<String> seenWords = {};
        final progress = progressService;
        final query = _searchQuery.toLowerCase();

        for (var lessonPlan in _allPlans) {
          if (progress.getCompleted(lessonPlan.id) > 0 ||
              lessonPlan.category == 'Favorites') {
            for (var step in lessonPlan.steps) {
              final word = _extractWordFromStep(step);
              if (word == null) continue;

              if (seenWords.contains(word.stableId)) continue;

              if (word.thai.toLowerCase().contains(query) ||
                  word.english.toLowerCase().contains(query) ||
                  word.phonetic.toLowerCase().contains(query) ||
                  lessonPlan.category.toLowerCase().contains(query)) {
                filteredWords.add(word);
                seenWords.add(word.stableId);
              }
            }
          }
        }
        _wordsFuture = Future.value(filteredWords);
      } else if (_selectedCategory == 'Favorites') {
        _wordsFuture = Future.value(_favoriteWords);
      } else {
        final List<WordEntry> categoryWords = [];
        final Set<String> seenWords = {};

        final categoryPlans = _allPlans.where(
          (lessonPlan) => lessonPlan.category == _selectedCategory,
        );
        for (var lessonPlan in categoryPlans) {
          for (var step in lessonPlan.steps) {
            final word = _extractWordFromStep(step);
            if (word != null) {
              final wordId = word.stableId;
              if (!seenWords.contains(wordId)) {
                categoryWords.add(word);
                seenWords.add(wordId);
              }
            }
          }
        }
        _wordsFuture = Future.value(categoryWords);
      }
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
    final categories = _allPlans.map((p) => p.category).toSet().toList();
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
                setState(() => _searchQuery = val);
                _refreshWords();
              },
              onClear: () {
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
                    final categoryPlans = _allPlans.where(
                      (lessonPlan) => lessonPlan.category == categoryName,
                    );
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
