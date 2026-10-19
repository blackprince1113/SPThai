import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class LessonReorderSheet extends StatefulWidget {
  final List<LessonStepData> steps;
  final int activeStepIndex;
  final Function(int oldIndex, int newIndex) onReorder;

  const LessonReorderSheet({
    super.key,
    required this.steps,
    required this.activeStepIndex,
    required this.onReorder,
  });

  static Future<void> show(
    BuildContext context, {
    required List<LessonStepData> steps,
    required int activeStepIndex,
    required Function(int oldIndex, int newIndex) onReorder,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonReorderSheet(
        steps: steps,
        activeStepIndex: activeStepIndex,
        onReorder: onReorder,
      ),
    );
  }

  @override
  State<LessonReorderSheet> createState() => _LessonReorderSheetState();
}

class _LessonReorderSheetState extends State<LessonReorderSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              "Reorder Steps",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              proxyDecorator: (child, index, animation) {
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, child) => Material(
                    elevation: 0,
                    color: Colors.transparent,
                    child: child,
                  ),
                  child: child,
                );
              },
              itemCount: widget.steps.length,
              onReorderItem: (oldIndex, newIndex) {
                widget.onReorder(oldIndex, newIndex);
                setState(() {});
              },
              itemBuilder: (context, index) {
                final step = widget.steps[index];
                final theme = Theme.of(context);
                return Container(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      step.questionType.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      step.thai.isNotEmpty
                          ? step.thai
                          : (step.question.isNotEmpty
                                ? step.question
                                : "No content yet"),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.drag_handle_rounded),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
