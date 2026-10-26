import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/features/lessons/presentation/question_types/controllers/listening_choice_controller.dart';

class ListeningChoiceTakePage extends StatefulWidget {
  final WordEntry word;
  final List<String> choices;
  final String correctAnswer;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const ListeningChoiceTakePage({
    super.key,
    required this.word,
    required this.choices,
    required this.correctAnswer,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<ListeningChoiceTakePage> createState() =>
      _ListeningChoiceTakePageState();
}

class _ListeningChoiceTakePageState extends State<ListeningChoiceTakePage> {
  late final ListeningChoiceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ListeningChoiceController(
      word: widget.word,
      initialChoices: widget.choices,
      correctAnswer: widget.correctAnswer,
    );
    if (widget.isActive) _controller.init();
  }

  @override
  void didUpdateWidget(ListeningChoiceTakePage oldWidget) {
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
        if (_controller.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

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
                  label: "LISTEN AND CHOOSE",
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
                ..._controller.choices.map(
                  (choice) => ThaiAnswerChoiceButton(
                    text: choice,
                    answered: _controller.answered,
                    selected: _controller.selectedAnswer == choice,
                    correct: _controller.isCorrect(choice),
                    onTap: () => _controller.selectChoice(choice),
                  ),
                ),
                const SizedBox(height: 16),
                if (_controller.answered) _buildFeedbackArea(),
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
      correct: _controller.answerCorrect,
      correctTitle: "GREAT JOB!",
      incorrectTitle: "NOT QUITE",
      answerLabel: "The correct meaning was:",
      answerText: widget.correctAnswer,
      onContinue: () =>
          StepResultNotification(_controller.answerCorrect).dispatch(context),
    );
  }
}
