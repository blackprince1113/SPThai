import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/meaning_controller.dart';

class MeaningTakePage extends StatefulWidget {
  final ExampleSentence sentence;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;

  const MeaningTakePage({
    super.key,
    required this.sentence,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
  });

  @override
  State<MeaningTakePage> createState() => _MeaningTakePageState();
}

class _MeaningTakePageState extends State<MeaningTakePage> {
  late final MeaningController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MeaningController(widget.sentence);
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
                  label: "TYPE THE CORRECT MEANING",
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  padding: const EdgeInsets.only(bottom: 24),
                ),
                Text(
                  widget.sentence.sentence,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.getResponsiveFontSize(
                      widget.sentence.sentence,
                      28,
                    ),
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                        AppTheme.textColor,
                    height: 1.5,
                  ),
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
                      hintText: "Type here...",
                      hintStyle: TextStyle(
                        color: AppTheme.editModeColor.withValues(alpha: 0.5),
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
                if (!_controller.checked)
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
          appBar: widget.showAppBar ? const ThaiAppBar(title: "Meaning") : null,
          body: body,
        );
      },
    );
  }

  Widget _buildFeedbackArea() {
    return ThaiFeedbackCard(
      correct: _controller.isCorrect,
      correctTitle: "CORRECT!",
      incorrectTitle: "INCORRECT",
      answerLabel: "The correct answer was:",
      answerText: widget.sentence.gapAnswer,
      incorrectIcon: Icons.error_outline_rounded,
      onContinue: () =>
          StepResultNotification(_controller.isCorrect).dispatch(context),
    );
  }
}
