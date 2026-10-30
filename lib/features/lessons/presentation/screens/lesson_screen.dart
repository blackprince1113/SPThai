import 'package:flutter/material.dart';
import 'package:superthai/core/viewmodels/lesson_view_model.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/listening_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/listening_choice_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/speaking_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/complete_sentence_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/meaning_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/four_choice_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/sentence_order_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/vowel_fill_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/flashcard_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/info_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/conversation_take_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/take/sentence_example_take_page.dart';
import 'package:superthai/ui/widgets/lesson_completion_widget.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:superthai/ui/theme/app_theme.dart';

class LessonScreen extends StatefulWidget {
  final String category;
  final String? lessonId;

  const LessonScreen({super.key, required this.category, this.lessonId});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final LessonViewModel _viewModel;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _viewModel = LessonViewModel(
      category: widget.category,
      lessonId: widget.lessonId,
    );
    _pageController = PageController(initialPage: _viewModel.currentIndex);
    _viewModel.addListener(_onViewModelUpdate);
  }

  void _onViewModelUpdate() {
    if (_viewModel.isLoading) return;

    if (_pageController.hasClients) {
      if (_pageController.page?.round() != _viewModel.currentIndex) {
        _pageController.animateToPage(
          _viewModel.currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdate);
    _viewModel.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _mapStepToPage(LessonStep step, bool isActive) {
    final int index = _viewModel.currentIndex;
    final int total = _viewModel.steps.length;

    switch (step.type) {
      case LessonType.flashcard:
        return FlashcardTakePage(
          word: step.word!,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.multipleChoice:
        return FourChoiceTakePage(
          word: step.word!,
          choices: step.rawData?.choices ?? [],
          correctAnswer: step.rawData?.answer ?? "",
          category: widget.category,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
        );
      case LessonType.listening:
        return ListeningTakePage(
          word: step.word!,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.listeningChoice:
        return ListeningChoiceTakePage(
          word: step.word!,
          choices: step.rawData?.choices ?? [],
          correctAnswer: step.rawData?.answer ?? "",
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.speaking:
        return SpeakingTakePage(
          word: step.word!,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.completeSentence:
        return CompleteSentenceTakePage(
          sentence: step.sentence!,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          plan: _viewModel.currentPlan,
          stepIndex: step.originalIndex,
        );
      case LessonType.meaning:
        return MeaningTakePage(
          sentence: step.sentence!,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
        );
      case LessonType.sentenceOrder:
        return SentenceOrderTakePage(
          word: step.word!,
          choices: step.rawData?.choices ?? [],
          correctAnswer: step.rawData?.answer ?? "",
          category: widget.category,
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
        );
      case LessonType.vowelFill:
        return VowelFillTakePage(
          word: step.word!,
          question: step.rawData?.question ?? "",
          answer: step.rawData?.answer ?? "",
          choices: step.rawData?.choices ?? [],
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.info:
        return InfoTakePage(
          title: step.rawData?.question ?? "",
          content: step.rawData?.answer ?? "",
          imageUrl: step.rawData?.imageUrl ?? "",
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
        );
      case LessonType.conversation:
        return ConversationTakePage(
          messages: step.rawData?.conversation ?? [],
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
      case LessonType.sentenceExample:
        return SentenceExampleTakePage(
          sentences: step.rawData?.conversation ?? [],
          showAppBar: false,
          currentIndex: index,
          totalSteps: total,
          isActive: isActive,
        );
    }
  }

  void _onPageChanged(int index) {
    _viewModel.jumpToStep(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        if (_viewModel.isLoading) {
          return Scaffold(body: _buildLoadingScreen());
        }
        if (_viewModel.isCompleted) {
          return Scaffold(body: _buildCompletionScreen());
        }
        if (_viewModel.steps.isEmpty) {
          return Scaffold(body: _buildLoadingScreen());
        }

        return Scaffold(
          body: NotificationListener<StepResultNotification>(
            onNotification: (StepResultNotification notification) {
              _viewModel.nextStep(notification.result);
              return true;
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: _viewModel.steps.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final step = _viewModel.steps[index];
                return _mapStepToPage(step, index == _viewModel.currentIndex);
              },
            ),
          ),
          bottomNavigationBar: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 10,
              top: 10,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Opacity(
                  opacity: _viewModel.currentIndex > 0 ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: _viewModel.currentIndex == 0,
                    child: _buildBottomNavButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: "PREV",
                      onPressed: () => _viewModel.previousStep(),
                    ),
                  ),
                ),

                _buildBottomNavButton(
                  icon: Icons.close_rounded,
                  label: "EXIT",
                  color: Colors.grey,
                  onPressed: () => Navigator.pop(context),
                ),

                Opacity(
                  opacity: _viewModel.currentIndex < _viewModel.steps.length - 1
                      ? 1.0
                      : 0.0,
                  child: IgnorePointer(
                    ignoring:
                        _viewModel.currentIndex >= _viewModel.steps.length - 1,
                    child: _buildBottomNavButton(
                      icon: Icons.arrow_forward_ios_rounded,
                      label: "NEXT",
                      onPressed: () => _viewModel.nextStep(false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    final themeColor = color ?? AppTheme.primaryColor;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: themeColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: themeColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionScreen() {
    return LessonCompletionWidget(
      viewModel: _viewModel,
      category: widget.category,
    );
  }

  Widget _buildLoadingScreen() {
    if (!_viewModel.isLoading && _viewModel.steps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "No content found for this lesson.",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Go Back"),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 30),
          Text(
            "Get Ready...",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _viewModel.isLoading
                ? "Loading content..."
                : "Question ${_viewModel.currentIndex + 1} / ${_viewModel.steps.length}",
            style: const TextStyle(
              fontSize: 18,
              color: AppTheme.lightTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
