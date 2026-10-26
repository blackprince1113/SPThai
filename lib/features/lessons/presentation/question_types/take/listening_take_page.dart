import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/listening_controller.dart';

class ListeningTakePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const ListeningTakePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<ListeningTakePage> createState() => _ListeningTakePageState();
}

class _ListeningTakePageState extends State<ListeningTakePage> {
  late final ListeningController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ListeningController(widget.word);
    if (widget.isActive) _controller.init();
  }

  @override
  void didUpdateWidget(ListeningTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.init();
    }
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
                const SizedBox(height: 24),
                ThaiLessonProgress(
                  currentIndex: widget.currentIndex,
                  totalSteps: widget.totalSteps,
                ),
                const SizedBox(height: 36),
                ThaiSectionLabel(
                  label: "LISTEN AND TYPE",
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  padding: const EdgeInsets.only(bottom: 24),
                ),
                ThaiSoundButtonsRow(
                  onNormal: _controller.speakThaiNormal,
                  onSlow: _controller.speakThaiSlow,
                  spacing: 48,
                ),
                const SizedBox(height: 40),
                ThaiInputContainer(
                  child: TextField(
                    controller: _controller.textController,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: "What did you hear?",
                      hintStyle: TextStyle(
                        color: theme.disabledColor,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_controller.answered)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _controller.textController.text.isEmpty
                            ? Colors.grey.shade300
                            : AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        elevation: 0,
                      ),
                      onPressed: _controller.textController.text.isEmpty
                          ? null
                          : _controller.checkAnswer,
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

  Widget _buildFeedbackArea() {
    return ThaiFeedbackCard(
      correct: _controller.isCorrect,
      correctTitle: "BRILLIANT!",
      incorrectTitle: "NOT QUITE",
      answerLabel: "The correct Thai word was:",
      answerText: widget.word.thai,
      correctIcon: Icons.stars_rounded,
      incorrectIcon: Icons.sentiment_very_dissatisfied_rounded,
      onContinue: () =>
          StepResultNotification(_controller.isCorrect).dispatch(context),
    );
  }
}
