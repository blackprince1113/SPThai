import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ManageLessonsScreen extends StatefulWidget {
  const ManageLessonsScreen({super.key});

  @override
  State<ManageLessonsScreen> createState() => _ManageLessonsScreenState();
}

class _ManageLessonsScreenState extends State<ManageLessonsScreen> {
  List<LessonPlan> _allPlans = [];
  bool _isLoading = true;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPlans() async {
    try {
      final plans = await dataService.getAllLessonPlans(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _allPlans = plans;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load lessons. Please retry.')),
      );
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _isLoading = true);
    try {
      await dataService.updateLessonIndices(_allPlans);
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order saved successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save lesson order. Please retry.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final Map<String, List<LessonPlan>> groups = {};
    final List<String> categoryOrder = [];

    for (var plan in _allPlans) {
      if (!groups.containsKey(plan.category)) {
        groups[plan.category] = [];
        categoryOrder.add(plan.category);
      }
      groups[plan.category]!.add(plan);
    }

    final filteredCategoryOrder = categoryOrder
        .where((cat) => cat.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: ThaiAppBar(
        title: "Manage Order",
        showProfile: false,
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _saveOrder,
              child: Text(
                "Save",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ThaiSearchBar(
              controller: _searchController,
              hintText: "Search categories...",
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              onClear: () {
                setState(() {
                  _searchController.clear();
                  _searchQuery = "";
                });
              },
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.only(bottom: 100),
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: child,
                );
              },
              onReorderItem: (oldIndex, newIndex) {
                if (_searchQuery.isNotEmpty) return;
                setState(() {
                  final category = categoryOrder.removeAt(oldIndex);
                  categoryOrder.insert(newIndex, category);

                  final List<LessonPlan> newList = [];
                  for (var cat in categoryOrder) {
                    newList.addAll(groups[cat]!);
                  }
                  _allPlans = newList;
                });
              },
              children: [
                for (int i = 0; i < filteredCategoryOrder.length; i++)
                  _CategoryTile(
                    key: ValueKey(filteredCategoryOrder[i]),
                    category: filteredCategoryOrder[i],
                    lessons: groups[filteredCategoryOrder[i]]!,
                    showDragHandle: _searchQuery.isEmpty,
                    onLessonsReordered: (reorderedLessons) {
                      setState(() {
                        groups[filteredCategoryOrder[i]] = reorderedLessons;
                        final List<LessonPlan> newList = [];
                        for (var cat in categoryOrder) {
                          newList.addAll(groups[cat]!);
                        }
                        _allPlans = newList;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final List<LessonPlan> lessons;
  final Function(List<LessonPlan>) onLessonsReordered;
  final bool showDragHandle;

  const _CategoryTile({
    super.key,
    required this.category,
    required this.lessons,
    required this.onLessonsReordered,
    this.showDragHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: ValueKey(category),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: showDragHandle
              ? const Icon(
                  Icons.drag_indicator_rounded,
                  color: AppTheme.editModeColor,
                )
              : null,
          children: [
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lessons.length,
              proxyDecorator: (child, index, animation) {
                return Material(
                  elevation: 0,
                  color: Colors.transparent,
                  child: child,
                );
              },
              onReorderItem: (oldIndex, newIndex) {
                final list = List<LessonPlan>.from(lessons);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                onLessonsReordered(list);
              },
              itemBuilder: (context, index) {
                final lesson = lessons[index];
                return ListTile(
                  key: ValueKey(lesson.id),
                  leading: Text(
                    lesson.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                  title: Text(lesson.title),
                  trailing: const Icon(
                    Icons.reorder_rounded,
                    size: 20,
                    color: AppTheme.editModeColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
