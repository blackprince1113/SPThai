import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_screen.dart';

class _SearchResult {
  final LessonPlan plan;
  final String matchReason;

  _SearchResult({required this.plan, required this.matchReason});
}

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  List<_SearchResult> _filterPlans(List<LessonPlan> plans, String rawQuery) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return [];

    final List<_SearchResult> results = [];

    for (var plan in plans) {
      bool matched = false;
      String reason = '';

      if (plan.title.toLowerCase().contains(query)) {
        matched = true;
        reason = 'ชื่อบทเรียน';
      } else if (plan.category.toLowerCase().contains(query)) {
        matched = true;
        reason = 'หมวดหมู่: ${plan.category}';
      } else {
        for (var step in plan.steps) {
          if (step.english.toLowerCase().contains(query) ||
              step.thai.toLowerCase().contains(query) ||
              step.phonetic.toLowerCase().contains(query) ||
              step.question.toLowerCase().contains(query) ||
              step.answer.toLowerCase().contains(query)) {
            matched = true;
            final snippet = step.english.isNotEmpty
                ? step.english
                : (step.thai.isNotEmpty ? step.thai : step.question);
            reason = 'คำศัพท์/เนื้อหา: $snippet';
            break;
          }
          if (step.conversation != null) {
            for (var msg in step.conversation!) {
              if (msg.text.toLowerCase().contains(query) ||
                  msg.translation.toLowerCase().contains(query)) {
                matched = true;
                reason = 'การสนทนา: ${msg.text}';
                break;
              }
            }
            if (matched) break;
          }
        }
      }

      if (matched) {
        results.add(_SearchResult(plan: plan, matchReason: reason));
      }
    }

    return results;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainState = MainContainer.of(context);
    final currentIndex = mainState?.selectedIndex ?? 0;
    final selectedCategory = mainState?.selectedCategory;

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          // Quick Search Header
          _buildQuickSearchHeader(context),

          // Search Results or Categories List
          Expanded(
            child: FutureBuilder<List<LessonPlan>>(
              future: dataService.getAllLessonPlans(),
              builder: (context, snapshot) {
                final plans = snapshot.data ?? [];

                // Group plans by category
                final Map<String, List<LessonPlan>> categoryMap = {};
                for (var plan in plans) {
                  if (plan.category.isNotEmpty) {
                    categoryMap.putIfAbsent(plan.category, () => []).add(plan);
                  }
                }
                final categoryNames = categoryMap.keys.toList();

                if (plans.isEmpty &&
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }

                // --- WHEN SEARCHING ---
                if (_searchQuery.trim().isNotEmpty) {
                  final results = _filterPlans(plans, _searchQuery);
                  final matchingCatNames = categoryNames
                      .where((cat) => cat
                          .toLowerCase()
                          .contains(_searchQuery.trim().toLowerCase()))
                      .toList();

                  if (results.isEmpty && matchingCatNames.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 32),
                        Icon(
                          Icons.search_off_rounded,
                          size: 56,
                          color: theme.disabledColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'ไม่พบบทเรียนที่ตรงกับ "$_searchQuery"',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ลองค้นหาด้วยคำอื่น เช่น hotel, greeting, food หรือพิมพ์คีย์เวิร์ดสั้นๆ',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.disabledColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: OutlinedButton.icon(
                            onPressed: _clearSearch,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('ล้างการค้นหา'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 8,
                    ),
                    children: [
                      // Header: SEARCH RESULTS
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'SEARCH RESULTS',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '${results.length} บทเรียน',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Matching Categories shortcuts
                      if (matchingCatNames.isNotEmpty) ...[
                        ...matchingCatNames.map((catName) {
                          final catPlans = categoryMap[catName]!;
                          final firstPlan = catPlans.first;
                          final emoji = firstPlan.categoryEmoji.isNotEmpty
                              ? firstPlan.categoryEmoji
                              : (firstPlan.emoji.isNotEmpty
                                  ? firstPlan.emoji
                                  : '📚');
                          return _buildCategoryResultTile(
                            context,
                            categoryName: catName,
                            emoji: emoji,
                            lessonCount: catPlans.length,
                            mainState: mainState,
                          );
                        }),
                        const Divider(height: 16),
                      ],

                      // Matched Lessons shortcuts
                      ...results.map((res) {
                        return _buildSearchResultTile(
                          context,
                          result: res,
                          mainState: mainState,
                        );
                      }),
                    ],
                  );
                }

                // --- WHEN NOT SEARCHING (SHOW CATEGORIES) ---
                return ListView(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  children: [
                    // Section Header: CATEGORIES
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 16,
                                color: theme.disabledColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CATEGORIES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.disabledColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          if (categoryNames.isNotEmpty)
                            Text(
                              '${categoryNames.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.disabledColor,
                              ),
                            ),
                        ],
                      ),
                    ),

                    if (categoryNames.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: Text('ไม่มีหมวดหมู่')),
                      )
                    else
                      ...categoryNames.map((catName) {
                        final catPlans = categoryMap[catName]!;
                        final firstPlan = catPlans.first;
                        final emoji = firstPlan.categoryEmoji.isNotEmpty
                            ? firstPlan.categoryEmoji
                            : (firstPlan.emoji.isNotEmpty
                                ? firstPlan.emoji
                                : '📚');
                        final isSelected = currentIndex == 0 &&
                            (selectedCategory == catName ||
                                (selectedCategory == null &&
                                    catName == categoryNames.first));

                        return _buildCategoryItem(
                          context,
                          emoji: emoji,
                          title: catName,
                          count: catPlans.length,
                          isSelected: isSelected,
                          onTap: () {
                            Navigator.pop(context);
                            mainState?.selectCategory(catName);
                          },
                        );
                      }),
                  ],
                );
              },
            ),
          ),

          // Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final version = snapshot.data?.version ?? '1.2.8';
                  return Text(
                    'SuperThai v$version',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color
                          ?.withValues(alpha: 0.5),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickSearchHeader(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = AppTheme.primaryColor;
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(16, topPadding + 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF2C2C2C),
                  const Color(0xFF1E1E1E),
                ]
              : [
                  primaryColor,
                  primaryColor.withValues(alpha: 0.88),
                  AppTheme.secondaryColor,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Title
          Text(
            'ทางลัดค้นหาบทเรียน',
            style: TextStyle(
              color: isDark
                  ? (theme.textTheme.titleLarge?.color ?? Colors.white)
                  : Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),

          // Search Bar Container
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? theme.cardColor : Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: isDark
                  ? Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.15),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(
                  Icons.search_rounded,
                  color: primaryColor,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? (theme.textTheme.bodyLarge?.color ?? Colors.white)
                          : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'พิมพ์ Keywords (เช่น hotel, greeting)...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: isDark ? theme.hintColor : Colors.grey,
                      ),
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      isDense: true,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      size: 18,
                      color: isDark ? theme.hintColor : Colors.grey,
                    ),
                    onPressed: _clearSearch,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultTile(
    BuildContext context, {
    required _SearchResult result,
    required MainContainerState? mainState,
  }) {
    final theme = Theme.of(context);
    final primaryColor = AppTheme.primaryColor;
    final plan = result.plan;
    final emoji = plan.emoji.isNotEmpty
        ? plan.emoji
        : (plan.categoryEmoji.isNotEmpty ? plan.categoryEmoji : '📚');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          plan.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                plan.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                result.matchReason,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.disabledColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.play_arrow_rounded,
            color: primaryColor,
            size: 18,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          mainState?.selectCategory(plan.category);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LessonScreen(
                category: plan.category,
                lessonId: plan.id,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryResultTile(
    BuildContext context, {
    required String categoryName,
    required String emoji,
    required int lessonCount,
    required MainContainerState? mainState,
  }) {
    final primaryColor = AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          'หมวดหมู่: $categoryName',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: primaryColor,
          ),
        ),
        subtitle: Text(
          'เปิดแผนที่เรียนทั้ง $lessonCount บทเรียน',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Icon(
          Icons.map_rounded,
          color: primaryColor,
          size: 20,
        ),
        onTap: () {
          Navigator.pop(context);
          mainState?.selectCategory(categoryName);
        },
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context, {
    required String emoji,
    required String title,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = AppTheme.primaryColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : theme.dividerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
            color: isSelected
                ? primaryColor
                : theme.textTheme.bodyLarge?.color,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : theme.dividerColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? primaryColor : theme.disabledColor,
            ),
          ),
        ),
        selected: isSelected,
        selectedTileColor: primaryColor.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        onTap: onTap,
      ),
    );
  }
}
