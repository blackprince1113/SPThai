import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/progress_service.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_screen.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/widgets/lesson_map_widgets.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/features/lessons/presentation/screens/manage_lessons_screen.dart';

class LessonSelectionScreen extends StatefulWidget {
  const LessonSelectionScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshCategories({bool force = false}) {
    if (!mounted) return;
    setState(() {
      _plansFuture = dataService.getAllLessonPlans(forceRefresh: force);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ThaiAppBar(
        title: "Lesson",
        actions: [
          Consumer<AuthService>(
            builder: (context, auth, _) {
              if (!auth.isAdmin) return const SizedBox.shrink();
              return IconButton(
                icon: Icon(Icons.sort_rounded, color: AppTheme.primaryColor),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageLessonsScreen(),
                  ),
                ).then((_) => _refreshCategories()),
              );
            },
          ),
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
      body: FutureBuilder<List<LessonPlan>>(
        future: _plansFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            _cachedPlans = snapshot.data;
          }

          final allPlans = snapshot.data ?? _cachedPlans;

          if (allPlans == null &&
              snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && allPlans == null) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final plansToDisplay = allPlans ?? [];

          return RefreshIndicator(
            onRefresh: () async => _refreshCategories(force: true),
            child: plansToDisplay.isEmpty
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: _buildEmptyState(),
                    ),
                  )
                : Consumer<ProgressService>(
                    builder: (context, progress, _) {
                      return _LessonMap(
                        plans: plansToDisplay,
                        progress: progress,
                        onReturn: _refreshCategories,
                        scrollController: _scrollController,
                        hasScrolled: _hasScrolled,
                        onScrolled: (val) => _hasScrolled = val,
                      );
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const ThaiEmptyState(
      icon: Icons.folder_open_rounded,
      title: "No lessons available yet!",
      subtitle: "Please check back later for new content.",
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

  const _LessonMap({
    required this.plans,
    required this.progress,
    required this.onReturn,
    required this.scrollController,
    required this.hasScrolled,
    required this.onScrolled,
  });

  @override
  State<_LessonMap> createState() => _LessonMapState();
}

class _LessonMapState extends State<_LessonMap> {
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
        _scrollToCurrentLesson();
      }
    });
  }

  void _scrollToCurrentLesson() {
    if (widget.plans.isEmpty || widget.hasScrolled) return;

    final targetLessonId = widget.progress.lastLessonId;
    int targetIndex = -1;

    if (targetLessonId != null) {
      targetIndex = widget.plans.indexWhere((p) => p.id == targetLessonId);
    }

    if (targetIndex == -1) {
      for (int i = 0; i < widget.plans.length; i++) {
        final plan = widget.plans[i];
        final completed = widget.progress.getCompleted(plan.id);
        if (completed < plan.steps.length) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex == -1) {
      targetIndex = widget.plans.length - 1;
    }

    final resolvedLessonId = widget.plans[targetIndex].id;
    final Map<String, List<LessonPlan>> plansByCategory = {};
    for (var plan in widget.plans) {
      plansByCategory.putIfAbsent(plan.category, () => []).add(plan);
    }
    final categoryNames = plansByCategory.keys.toList();
    double offset = 0;
    bool found = false;

    const double headerAndGapHeight = 168.0;
    const double rowHeight = 120.0;
    const double categoryBottomSpacing = 24.0;
    const double listTopPadding = 20.0;

    for (var catName in categoryNames) {
      final catPlans = plansByCategory[catName]!;
      int lessonIndexInCat = catPlans.indexWhere(
        (p) => p.id == resolvedLessonId,
      );

      if (lessonIndexInCat != -1) {
        offset +=
            listTopPadding +
            headerAndGapHeight +
            (lessonIndexInCat * rowHeight);
        final screenHeight = MediaQuery.of(context).size.height;
        offset -= (screenHeight / 2) - (rowHeight / 2);
        found = true;
        break;
      } else {
        offset +=
            headerAndGapHeight +
            (catPlans.length * rowHeight) +
            categoryBottomSpacing;
      }
    }

    if (found && widget.scrollController.hasClients) {
      widget.scrollController.animateTo(
        offset.clamp(0.0, widget.scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeInOutCubic,
      );
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
                  MainContainer.of(screenContext)?.switchToCreate(plan);
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

  @override
  Widget build(BuildContext context) {
    final Map<String, List<LessonPlan>> plansByCategory = {};
    for (var plan in widget.plans) {
      plansByCategory.putIfAbsent(plan.category, () => []).add(plan);
    }
    final categoryNames = plansByCategory.keys.toList();
    final contentExtent =
        140.0 +
        categoryNames.fold<double>(
          0,
          (extent, categoryName) =>
              extent + 192.0 + (plansByCategory[categoryName]!.length * 120.0),
        );
    final categoryConsonantStarts = <int>[];
    var consonantOffset = 0;
    for (final categoryName in categoryNames) {
      categoryConsonantStarts.add(consonantOffset);
      consonantOffset += (plansByCategory[categoryName]!.length ~/ 2);
    }
    final theme = Theme.of(context);
    return _LessonMapScrollbar(
      controller: widget.scrollController,
      contentExtent: contentExtent,
      child: RepaintBoundary(
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 120,
            left: 36,
            right: 36,
          ),
          itemCount: categoryNames.length,
          itemExtentBuilder: (categoryIndex, dimensions) {
            const categoryHeaderHeight = 138.0;
            const categoryHeaderGap = 30.0;
            const categoryBottomGap = 24.0;
            const lessonRowHeight = 120.0;
            final lessonCount =
                plansByCategory[categoryNames[categoryIndex]]!.length;
            return categoryHeaderHeight +
                categoryHeaderGap +
                (lessonCount * lessonRowHeight) +
                categoryBottomGap;
          },
          itemBuilder: (context, categoryIndex) {
            final categoryName = categoryNames[categoryIndex];
            final categoryPlans = plansByCategory[categoryName]!;

            return Consumer<ProgressService>(
              builder: (context, progress, _) {
                int completedStepCount = 0;
                int totalStepCount = 0;
                for (var lessonPlan in categoryPlans) {
                  completedStepCount += progress.getCompleted(lessonPlan.id);
                  totalStepCount += lessonPlan.steps.length;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final double width = constraints.maxWidth;
                    const List<double> alignments = [0.0, -0.5, 0.0, 0.5];
                    const double nodeWidth = 80.0;
                    const double rowHeight = 120.0;
                    final List<Offset> points = [];

                    for (int i = 0; i < categoryPlans.length; i++) {
                      final align = alignments[i % alignments.length];
                      final double x =
                          (width / 2) + (align * (width - nodeWidth) / 2);
                      final double y = (i * rowHeight) + (rowHeight / 2);
                      points.add(Offset(x, y));
                    }

                    return Column(
                      children: [
                        SizedBox(
                          height: 138,
                          child: UnitHeaderCard(
                            title: categoryName,
                            emoji: categoryPlans.isNotEmpty
                                ? categoryPlans.first.categoryEmoji
                                : '??',
                            completed: completedStepCount,
                            total: totalStepCount,
                          ),
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          height: categoryPlans.length * 120.0,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ...List.generate(categoryPlans.length, (index) {
                                if (index % 2 == 0) {
                                  return const SizedBox.shrink();
                                }

                                final consonantIndex =
                                    categoryConsonantStarts[categoryIndex] +
                                    (index ~/ 2);

                                final char =
                                    _thaiConsonants[consonantIndex %
                                        _thaiConsonants.length];
                                final nodeAlign =
                                    alignments[index % alignments.length];
                                final charAlign = nodeAlign < 0 ? 0.8 : -0.8;

                                return Positioned(
                                  top: (index * rowHeight) - 20,
                                  left: 0,
                                  right: 0,
                                  child: IgnorePointer(
                                    child: Align(
                                      alignment: Alignment(charAlign, 0),
                                      child: Text(
                                        char,
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
                                );
                              }),
                              SizedBox(
                                width: width,
                                child: RepaintBoundary(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      size: Size(
                                        width,
                                        categoryPlans.length * rowHeight,
                                      ),
                                      painter: MapPathPainter(
                                        points: points,
                                        color: Colors.blueGrey.withValues(
                                          alpha: 0.15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: width,
                                child: Column(
                                  children: List.generate(categoryPlans.length, (
                                    index,
                                  ) {
                                    final plan = categoryPlans[index];
                                    final completed = progress.getCompleted(
                                      plan.id,
                                    );
                                    final total = plan.steps.length;
                                    final align =
                                        alignments[index % alignments.length];

                                    return SizedBox(
                                      height: rowHeight,
                                      width: width,
                                      child: MapNode(
                                        plan: plan,
                                        completed: completed,
                                        total: total,
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
                                    );
                                  }),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
