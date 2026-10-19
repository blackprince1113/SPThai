import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/sentence_order_controller.dart';

class SentenceOrderTakePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final String category;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;

  const SentenceOrderTakePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    required this.category,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
  });

  @override
  State<SentenceOrderTakePage> createState() => _SentenceOrderTakePageState();
}

class _SentenceOrderTakePageState extends State<SentenceOrderTakePage> {
  late final SentenceOrderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SentenceOrderController(
      word: widget.word,
      initialChoices: widget.choices,
      correctAnswer: widget.correctAnswer,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        Widget body = SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                ThaiLessonProgress(
                  currentIndex: widget.currentIndex,
                  totalSteps: widget.totalSteps,
                ),
                const SizedBox(height: 32),
                ThaiQuestionCard(
                  header: "ARRANGE THE SENTENCE",
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    widget.word.english,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        widget.word.english,
                        24,
                      ),
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                ThaiInputContainer(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    children: _controller.selectedTokens
                        .asMap()
                        .entries
                        .map((e) => _buildSelectedToken(e.value, e.key))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 40),
                Wrap(
                  spacing: 12,
                  runSpacing: 16,
                  alignment: WrapAlignment.center,
                  children: _controller.availableTokens
                      .map((token) => _buildAvailableToken(token))
                      .toList(),
                ),
                const SizedBox(height: 40),
                if (!_controller.answered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _controller.selectedTokens.isEmpty
                            ? Colors.grey.shade300
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                      ),
                      onPressed: _controller.selectedTokens.isEmpty
                          ? null
                          : () => _controller.checkAnswer(),
                      child: const Text(
                        "CHECK ANSWER",
                        style: TextStyle(letterSpacing: 1.2),
                      ),
                    ),
                  )
                else
                  _buildFeedbackArea(),
              ],
            ),
          ),
        );

        if (!widget.showAppBar) {
          body = SafeArea(child: body);
        }

        return Scaffold(
          appBar: widget.showAppBar ? const ThaiAppBar(title: "Quiz") : null,
          body: body,
        );
      },
    );
  }

  Widget _buildSelectedToken(String text, int index) {
    return GestureDetector(
      onTap: () => _controller.deselectToken(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableToken(String text) {
    final index = _controller.availableTokens.indexOf(text);
    return GestureDetector(
      onTap: () => _controller.selectToken(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildFeedbackArea() {
    return ThaiFeedbackCard(
      correct: _controller.answerCorrect,
      correctTitle: "BRILLIANT!",
      incorrectTitle: "NOT QUITE",
      answerLabel: "The correct order was:",
      answerText: widget.correctAnswer,
      onContinue: () =>
          StepResultNotification(_controller.answerCorrect).dispatch(context),
    );
  }
}
