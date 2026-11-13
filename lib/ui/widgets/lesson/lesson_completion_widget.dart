import 'package:flutter/material.dart';
import 'package:superthai/core/viewmodels/lesson_view_model.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class LessonCompletionWidget extends StatelessWidget {
  final LessonViewModel viewModel;
  final String category;

  const LessonCompletionWidget({
    super.key,
    required this.viewModel,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final total = viewModel.steps.length;
    final correct = viewModel.sessionCorrectCount;
    final failedCount = viewModel.failedSteps.length;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("🎉", style: TextStyle(fontSize: 80)),
            const SizedBox(height: 16),
            Text(
              "Great job!",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              "Lesson Complete",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            _buildStatsRow(context, total, correct, failedCount),
            const SizedBox(height: 48),
            if (failedCount > 0)
              ThaiButton(
                text: "Review $failedCount Mistakes",
                onPressed: () => viewModel.startReviewMistakes(),
                color: Colors.orange,
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text(
                "Back to Home",
                style: TextStyle(
                  fontSize: 18,
                  color: AppTheme.lightTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    BuildContext context,
    int total,
    int correct,
    int failed,
  ) {
    return ThaiCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(context, "Total", "$total", Colors.blue),
          _buildStatItem(context, "Correct", "$correct", Colors.green),
          _buildStatItem(context, "Failed", "$failed", Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.lightTextColor),
        ),
      ],
    );
  }
}
