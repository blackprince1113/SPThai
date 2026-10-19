import 'package:flutter/material.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class QuestionTypePickerSheet extends StatelessWidget {
  final QuestionType currentType;
  final ValueChanged<QuestionType> onSelectType;

  const QuestionTypePickerSheet({
    super.key,
    required this.currentType,
    required this.onSelectType,
  });

  static Future<void> show(
    BuildContext context, {
    required QuestionType currentType,
    required ValueChanged<QuestionType> onSelectType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => QuestionTypePickerSheet(
        currentType: currentType,
        onSelectType: onSelectType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final questionTypes = QuestionType.values;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      padding: const EdgeInsets.only(top: 12, left: 20, right: 20, bottom: 40),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: theme.dividerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Change Question Type',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.separated(
              itemCount: questionTypes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final qType = questionTypes[index];
                final isCurrent = currentType == qType;

                return InkWell(
                  onTap: () {
                    onSelectType(qType);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppTheme.primaryColor.withValues(alpha: 0.1)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: isCurrent
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppTheme.primaryColor
                                : theme.dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            qType.icon,
                            color: isCurrent
                                ? Colors.white
                                : theme.iconTheme.color?.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                qType.displayName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isCurrent
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                ),
                              ),
                              Text(
                                qType.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCurrent)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
