import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/progress_service.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_editor_screen.dart';
import 'package:superthai/ui/screens/navigation/main_container.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/widgets/lesson/lesson_map_widgets.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class LessonSelectionScreen extends StatefulWidget {
  final String? selectedCategory;

  const LessonSelectionScreen({super.key, this.selectedCategory});

  @override
  State<LessonSelectionScreen> createState() => _LessonSelectionScreenState();
}

class _LessonMapScrollbar extends StatefulWidget {
  final ScrollController controller;
  final double contentExtent;
  final Widget child;

  const _LessonMapScrollbar({
    required this.controller,
    required this.contentExtent,
    required this.child,
  });

  @override
  State<_LessonMapScrollbar> createState() => _LessonMapScrollbarState();
}

class _LessonMapScrollbarState extends State<_LessonMapScrollbar> {
  static const double _trackPadding = 12;
  static const double _thumbHeight = 64;
  static const double _thumbWidth = 28;

  double? _dragStartY;
  double? _dragStartOffset;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) {
        if (notification.depth == 0 && mounted) setState(() {});
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackHeight = constraints.maxHeight - (_trackPadding * 2);
          final thumbTravel = trackHeight - _thumbHeight;
          final maxScroll = (widget.contentExtent - constraints.maxHeight)
              .clamp(0.0, double.infinity);

          return Stack(
            children: [
              Positioned.fill(child: widget.child),
              if (thumbTravel > 0)
                Positioned(
                  top: _trackPadding,
                  bottom: _trackPadding,
                  right: 14,
                  child: IgnorePointer(
                    child: Container(
                      width: 4,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              if (thumbTravel > 0)
                AnimatedBuilder(
                  animation: widget.controller,
                  child: const SizedBox.shrink(),
                  builder: (context, _) {
                    final controller = widget.controller;
                    if (!controller.hasClients ||
                        !controller.position.hasContentDimensions ||
                        maxScroll <= 0) {
                      return const SizedBox.shrink();
                    }

                    final position = controller.position;
                    final progress = (position.pixels / maxScroll).clamp(
                      0.0,
                      1.0,
                    );
                    final thumbTop = _trackPadding + (progress * thumbTravel);

                    return Positioned(
                      top: thumbTop,
                      right: 2,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragStart: (details) {
                          _dragStartY = details.globalPosition.dy;
                          _dragStartOffset = position.pixels;
                        },
                        onVerticalDragUpdate: (details) {
                          if (!controller.hasClients ||
                              _dragStartY == null ||
                              _dragStartOffset == null) {
                            return;
                          }

                          final dragDistance =
                              details.globalPosition.dy - _dragStartY!;
                          final newOffset =
                              (_dragStartOffset! +
                                      (dragDistance / thumbTravel * maxScroll))
                                  .clamp(0.0, position.maxScrollExtent);
                          controller.jumpTo(newOffset);
                        },
                        onVerticalDragEnd: (_) {
                          _dragStartY = null;
                          _dragStartOffset = null;
                        },
                        onVerticalDragCancel: () {
                          _dragStartY = null;
                          _dragStartOffset = null;
                        },
                        child: Container(
                          width: _thumbWidth,
                          height: _thumbHeight,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                3,
                                (_) => Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  width: 12,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LessonSelectionScreenState extends State<LessonSelectionScreen> {
  late Future<List<LessonPlan>> _plansFuture;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;
  List<LessonPlan>? _cachedPlans;
  String? _lastActiveCategory;
  List<LessonPlan>? _preparedPlansSource;
  String? _preparedSelectedCategory;
  Map<String, List<LessonPlan>> _categoryMap = {};
  List<String> _categoryList = const [];
  List<LessonPlan> _filteredPlans = const [];
  String? _activeCategory;

  void _preparePlans(List<LessonPlan> plans, String? selectedCategory) {
    if (identical(_preparedPlansSource, plans) &&
        _preparedSelectedCategory == selectedCategory) {
      return;
    }

    final categoryMap = <String, List<LessonPlan>>{};
    for (final plan in plans) {
      if (plan.category.isNotEmpty) {
        categoryMap.putIfAbsent(plan.category, () => <LessonPlan>[]).add(plan);
      }
    }
    final categoryList = categoryMap.keys.toList(growable: false);
    final activeCategory =
        selectedCategory ??
        (categoryList.isNotEmpty ? categoryList.first : null);

    _preparedPlansSource = plans;
    _preparedSelectedCategory = selectedCategory;
    _categoryMap = categoryMap;
    _categoryList = categoryList;
    _activeCategory = activeCategory;
    _filteredPlans = activeCategory == null || activeCategory == 'ALL'
        ? plans
        : categoryMap[activeCategory] ?? const <LessonPlan>[];
  }

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  @override
  void didUpdateWidget(LessonSelectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _hasScrolled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0.0);
        }
      });
      setState(() {});
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshCategories() {
    if (!mounted) return;
    setState(() {
      _plansFuture = dataService.getAllLessonPlans();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory =
        widget.selectedCategory ?? MainContainer.of(context)?.selectedCategory;

    return FutureBuilder<List<LessonPlan>>(
      future: _plansFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedPlans = snapshot.data;
        }

        final allPlans = snapshot.data ?? _cachedPlans;
        final plansToDisplay = allPlans ?? [];
        _preparePlans(plansToDisplay, selectedCategory);
        final activeCategory = _activeCategory;

        if (_lastActiveCategory != activeCategory) {
          _lastActiveCategory = activeCategory;
          _hasScrolled = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0.0);
            }
          });
        }

        String appBarTitle = "Lesson";
        if (activeCategory != null && activeCategory != 'ALL') {
          final firstPlan = _categoryMap[activeCategory]?.first;
          final emoji = firstPlan?.categoryEmoji.isNotEmpty == true
              ? firstPlan!.categoryEmoji
              : (firstPlan?.emoji.isNotEmpty == true ? firstPlan!.emoji : '📚');
          appBarTitle = "$emoji $activeCategory";
        } else if (activeCategory == 'ALL') {
          appBarTitle = "📚 All Lessons";
        }

        if (allPlans == null &&
            snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: ThaiAppBar(title: appBarTitle, centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError && allPlans == null) {
          return Scaffold(
            appBar: ThaiAppBar(title: appBarTitle, centerTitle: true),
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        return Scaffold(
          appBar: ThaiAppBar(
            title: appBarTitle,
            centerTitle: true,
            actions: [
              Consumer<ProgressService>(
                builder: (context, progress, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${progress.streakCount}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          body: Stack(
            children: [
              Consumer<ProgressService>(
                builder: (context, progress, _) {
                  return _LessonMap(
                    key: ValueKey(activeCategory ?? 'ALL'),
                    plans: _filteredPlans,
                    progress: progress,
                    onReturn: _refreshCategories,
                    scrollController: _scrollController,
                    hasScrolled: _hasScrolled,
                    onScrolled: (val) => _hasScrolled = val,
                    categoryList: _categoryList,
                    activeCategory: activeCategory,
                    onSelectCategory: (newCat) {
                      MainContainer.of(context)?.selectCategory(newCat);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LessonMap extends StatefulWidget {
  final List<LessonPlan> plans;
  final ProgressService progress;
  final VoidCallback onReturn;
  final ScrollController scrollController;
  final bool hasScrolled;
  final ValueChanged<bool> onScrolled;
  final List<String> categoryList;
  final String? activeCategory;
  final ValueChanged<String>? onSelectCategory;

  const _LessonMap({
    super.key,
    required this.plans,
    required this.progress,
    required this.onReturn,
    required this.scrollController,
    required this.hasScrolled,
    required this.onScrolled,
    required this.categoryList,
    required this.activeCategory,
    this.onSelectCategory,
  });

  @override
  State<_LessonMap> createState() => _LessonMapState();
}

class _LessonMapState extends State<_LessonMap> {
  DateTime? _lastCategorySwitchTime;
  double _accumulatedOverscroll = 0.0;

  static const List<String> _thaiConsonants = [
    'ก',
    'ข',
    'ค',
    'ง',
    'จ',
    'ฉ',
    'ช',
    'ซ',
    'ฌ',
    'ญ',
    'ฎ',
    'ฏ',
    'ฐ',
    'ฑ',
    'ฒ',
    'ณ',
    'ด',
    'ต',
    'ถ',
    'ท',
    'ธ',
    'น',
    'บ',
    'ป',
    'ผ',
    'ฝ',
    'พ',
    'ฟ',
    'ภ',
    'ม',
    'ย',
    'ร',
    'ล',
    'ว',
    'ศ',
    'ษ',
    'ส',
    'ห',
    'ฬ',
    'อ',
    'ฮ',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _restoreScrollPosition();
      }
    });
  }

  void _restoreScrollPosition() {
    if (widget.plans.isEmpty || widget.hasScrolled) return;

    if (widget.scrollController.hasClients) {
      final double maxScroll = widget.scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) {
        widget.scrollController.jumpTo(0.0);
        widget.progress.saveScrollOffset(0.0);
        widget.onScrolled(true);
        return;
      }
      final double savedOffset = widget.progress.lastScrollOffset;
      final double targetOffset = savedOffset.clamp(0.0, maxScroll);
      widget.scrollController.jumpTo(targetOffset);
      widget.onScrolled(true);
    }
  }

  void _showDeleteConfirmation(BuildContext context, LessonPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Lesson?"),
        content: Text("Are you sure you want to delete '${plan.title}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              progressService.resetProgress(plan.id);
              await dataService.deleteLessonPlan(plan.id);
              widget.onReturn();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, LessonPlan plan) {
    final bool isAdmin = authService.isAdmin;
    final screenContext = context;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(plan.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            ListTile(
              leading: const SizedBox(
                width: 40,
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.green,
                  size: 28,
                ),
              ),
              title: const Text(
                "Start Lesson",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  screenContext,
                  MaterialPageRoute(
                    builder: (_) => LessonScreen(
                      category: plan.category,
                      lessonId: plan.id,
                    ),
                  ),
                ).then((_) => widget.onReturn());
              },
            ),
            if (isAdmin) ...[
              ListTile(
                leading: const SizedBox(
                  width: 40,
                  child: Icon(
                    Icons.edit_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                title: const Text(
                  "Edit Lesson",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    screenContext,
                    MaterialPageRoute(
                      builder: (_) => CreateScreen(existingPlan: plan),
                    ),
                  ).then((_) => widget.onReturn());
                },
              ),
              ListTile(
                leading: const SizedBox(
                  width: 40,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                title: const Text(
                  "Delete Lesson",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmation(screenContext, plan);
                },
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollEndNotification) {
      widget.progress.saveScrollOffset(widget.scrollController.offset);
      _accumulatedOverscroll = 0.0;
    }

    final activeCat = widget.activeCategory;
    final catList = widget.categoryList;
    if (activeCat == null ||
        catList.isEmpty ||
        widget.onSelectCategory == null) {
      return false;
    }

    final currentIndex = catList.indexOf(activeCat);
    if (currentIndex == -1) return false;

    final now = DateTime.now();
    final bool canSwitch =
        _lastCategorySwitchTime == null ||
        now.difference(_lastCategorySwitchTime!).inMilliseconds > 800;

    if (!canSwitch) return false;

    double overscrollDelta = 0.0;
    if (notification is OverscrollNotification) {
      overscrollDelta = notification.overscroll;
    } else if (notification is ScrollUpdateNotification) {
      final scrollDelta = notification.scrollDelta ?? 0.0;
      final metrics = notification.metrics;
      if (metrics.pixels < metrics.minScrollExtent ||
          metrics.pixels > metrics.maxScrollExtent) {
        overscrollDelta = scrollDelta;
      }
    }

    if (overscrollDelta != 0.0) {
      _accumulatedOverscroll += overscrollDelta;

      if (_accumulatedOverscroll > 25.0 && currentIndex < catList.length - 1) {
        _lastCategorySwitchTime = now;
        _accumulatedOverscroll = 0.0;
        final nextCat = catList[currentIndex + 1];
        widget.onSelectCategory!(nextCat);
      } else if (_accumulatedOverscroll < -25.0 && currentIndex > 0) {
        _lastCategorySwitchTime = now;
        _accumulatedOverscroll = 0.0;
        final prevCat = catList[currentIndex - 1];
        widget.onSelectCategory!(prevCat);
      }
    }
    return false;
  }

  List<Offset> _connectorEdgePoints(
    double startX,
    double startY,
    double endX,
    double endY,
  ) {
    const iconHalfSize = 40.0;
    final direction = Offset(endX - startX, endY - startY);
    final inset = iconHalfSize / direction.distance;

    return [
      Offset(startX + direction.dx * inset, startY + direction.dy * inset),
      Offset(endX - direction.dx * inset, endY - direction.dy * inset),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<LessonPlan>> plansByCategory = {};
    for (var plan in widget.plans) {
      plansByCategory.putIfAbsent(plan.category, () => []).add(plan);
    }
    final categoryNames = plansByCategory.keys.toList();
    final categoryConsonantStarts = <int>[];
    var consonantOffset = 0;
    for (final categoryName in categoryNames) {
      categoryConsonantStarts.add(consonantOffset);
      consonantOffset += (plansByCategory[categoryName]!.length ~/ 2);
    }
    final theme = Theme.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: CustomScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: categoryNames.isEmpty
            ? [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ThaiEmptyState(
                      icon: Icons.folder_open_rounded,
                      title: "No lessons available yet!",
                      subtitle: "Please check back later for new content.",
                    ),
                  ),
                ),
              ]
            : [
                for (
                  var categoryIndex = 0;
                  categoryIndex < categoryNames.length;
                  categoryIndex++
                ) ...[
                  SliverPadding(
                    padding: EdgeInsets.only(
                      left: 36,
                      right: 36,
                      top: categoryIndex == 0 ? 28 : 12,
                    ),
                    sliver: SliverList.builder(
                      itemCount:
                          plansByCategory[categoryNames[categoryIndex]]!.length,
                      itemBuilder: (context, index) {
                        const alignments = [0.0, -0.5, 0.0, 0.5];
                        const rowHeight = 120.0;
                        final categoryPlans =
                            plansByCategory[categoryNames[categoryIndex]]!;
                        final plan = categoryPlans[index];
                        final align = alignments[index % alignments.length];
                        final previousAlign = index == 0
                            ? null
                            : alignments[(index - 1) % alignments.length];
                        final consonantIndex =
                            categoryConsonantStarts[categoryIndex] + index ~/ 2;
                        return Consumer<ProgressService>(
                          builder: (context, progress, _) => SizedBox(
                            height: rowHeight,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final width = constraints.maxWidth;
                                double xFor(double value) =>
                                    width / 2 + value * (width - 80) / 2;
                                final connectorPoints = previousAlign == null
                                    ? null
                                    : _connectorEdgePoints(
                                        xFor(previousAlign),
                                        -12,
                                        xFor(align),
                                        108,
                                      );
                                return Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    if (previousAlign != null)
                                      Positioned(
                                        top: -60,
                                        bottom: -60,
                                        left: 0,
                                        right: 0,
                                        child: IgnorePointer(
                                          child: RepaintBoundary(
                                            child: CustomPaint(
                                              painter: MapPathPainter(
                                                points: connectorPoints!,
                                                color: Colors.blueGrey
                                                    .withValues(alpha: 0.15),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (index.isOdd)
                                      Positioned.fill(
                                        child: IgnorePointer(
                                          child: Align(
                                            alignment: Alignment(
                                              align < 0 ? 0.8 : -0.8,
                                              0,
                                            ),
                                            child: Text(
                                              _thaiConsonants[consonantIndex %
                                                  _thaiConsonants.length],
                                              style: TextStyle(
                                                fontSize: 110,
                                                fontWeight: FontWeight.bold,
                                                color: theme
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color
                                                    ?.withValues(alpha: 0.08),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned.fill(
                                      child: MapNode(
                                        plan: plan,
                                        completed: progress.getCompleted(
                                          plan.id,
                                        ),
                                        total: plan.steps.length,
                                        alignment: align,
                                        onLongPress: () =>
                                            _showOptions(context, plan),
                                        onTap: () async {
                                          if (progress.canTryLesson(plan.id)) {
                                            progress.updateLastLesson(plan.id);
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => LessonScreen(
                                                  category: plan.category,
                                                  lessonId: plan.id,
                                                ),
                                              ),
                                            );
                                            widget.onReturn();
                                          } else {
                                            ThaiDialogs.showSignupPrompt(
                                              context,
                                              title: "Trial Limit Reached! 🚀",
                                              message:
                                                  "You've tried 3 lessons. Please create an account or login to continue learning and save your progress to the cloud!",
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: categoryIndex == categoryNames.length - 1
                          ? 144
                          : 24,
                    ),
                  ),
                ],
              ],
      ),
    );
  }
}
