import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class LessonReorderSheet extends StatefulWidget {
  final List<LessonStepData> steps;
  final int activeStepIndex;
  final Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<int> onSelectStep;

  const LessonReorderSheet({
    super.key,
    required this.steps,
    required this.activeStepIndex,
    required this.onReorder,
    required this.onSelectStep,
  });

  static Future<void> show(
    BuildContext context, {
    required List<LessonStepData> steps,
    required int activeStepIndex,
    required Function(int oldIndex, int newIndex) onReorder,
    required ValueChanged<int> onSelectStep,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LessonReorderSheet(
        steps: steps,
        activeStepIndex: activeStepIndex,
        onReorder: onReorder,
        onSelectStep: onSelectStep,
      ),
    );
  }

  @override
  State<LessonReorderSheet> createState() => _LessonReorderSheetState();
}

class _LessonReorderSheetState extends State<LessonReorderSheet> {
  late int _activeStepIndex;

  @override
  void initState() {
    super.initState();
    _activeStepIndex = widget.activeStepIndex;
  }

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
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              children: [
                Text(
                  "Reorder or Select Step",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 6),
                Text(
                  "Tap a step to select it. Drag the handle to reorder.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
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
                setState(() {
                  if (_activeStepIndex == oldIndex) {
                    _activeStepIndex = newIndex;
                  } else if (oldIndex < _activeStepIndex &&
                      newIndex >= _activeStepIndex) {
                    _activeStepIndex--;
                  } else if (oldIndex > _activeStepIndex &&
                      newIndex <= _activeStepIndex) {
                    _activeStepIndex++;
                  }
                });
              },
              itemBuilder: (context, index) {
                final step = widget.steps[index];
                final theme = Theme.of(context);
                final isActive = index == _activeStepIndex;
                return Container(
                  key: ValueKey(step.id),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isActive
                          ? AppTheme.primaryColor
                          : theme.dividerColor.withValues(alpha: 0.12),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    onTap: () {
                      widget.onSelectStep(index);
                      Navigator.of(context).pop();
                    },
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
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.drag_handle_rounded),
                      ),
                    ),
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
