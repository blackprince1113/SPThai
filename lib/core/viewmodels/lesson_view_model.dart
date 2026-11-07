import 'package:flutter/material.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/progress_service.dart';

enum LessonType {
  flashcard,
  multipleChoice,
  listening,
  speaking,
  completeSentence,
  meaning,
  sentenceOrder,
  vowelFill,
  listeningChoice,
  info,
  conversation,
  sentenceExample,
}

class LessonStep {
  final WordEntry? word;
  final ExampleSentence? sentence;
  final LessonType type;
  final LessonStepData? rawData;
  final int originalIndex;

  LessonStep({
    this.word,
    this.sentence,
    required this.type,
    this.rawData,
    this.originalIndex = 0,
  });
}

class LessonViewModel extends ChangeNotifier {
  final String? lessonId;
  final String category;

  LessonPlan? _currentPlan;
  String? _resolvedId;
  List<LessonStep> _steps = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  int _sessionCorrectCount = 0;
  final List<LessonStep> _failedSteps = [];

  List<LessonStep> get steps => _steps;
  int get currentIndex => _currentIndex;
  bool get isCompleted =>
      !_isLoading && _steps.isNotEmpty && _currentIndex >= _steps.length;
  bool get isLoading => _isLoading;
  int get sessionCorrectCount => _sessionCorrectCount;
  List<LessonStep> get failedSteps => _failedSteps;

  LessonPlan? get currentPlan => _currentPlan;

  LessonViewModel({this.lessonId, required this.category}) {
    _generateSteps();
  }

  Future<void> _generateSteps() async {
    try {
      LessonPlan? plan;
      if (lessonId != null) {
        plan = await DataService.instance.getLessonPlanById(lessonId!);
      }

      plan ??= await DataService.instance.getLessonPlanByCategory(category);

      if (plan != null) {
        _currentPlan = plan;
        _resolvedId = plan.id;
        for (int i = 0; i < plan.steps.length; i++) {
          final stepData = plan.steps[i];
          if (stepData.thai.isNotEmpty ||
              stepData.english.isNotEmpty ||
              stepData.question.isNotEmpty ||
              stepData.answer.isNotEmpty ||
              (stepData.conversation != null &&
                  stepData.conversation!.isNotEmpty)) {
            _steps.add(
              LessonStep(
                word: stepData.toWordEntry(),
                type: _mapType(stepData.type),
                sentence: stepData.toExampleSentence(),
                rawData: stepData,
                originalIndex: i,
              ),
            );
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to load lesson: $error\n$stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  LessonType _mapType(String type) {
    final qType = QuestionType.tryFromString(type);
    switch (qType) {
      case QuestionType.flashcard:
        return LessonType.flashcard;
      case QuestionType.fourChoice:
        return LessonType.multipleChoice;
      case QuestionType.listening:
        return LessonType.listening;
      case QuestionType.speaking:
        return LessonType.speaking;
      case QuestionType.completeSentence:
        return LessonType.completeSentence;
      case QuestionType.meaning:
        return LessonType.meaning;
      case QuestionType.sentenceOrder:
        return LessonType.sentenceOrder;
      case QuestionType.vowelFill:
        return LessonType.vowelFill;
      case QuestionType.listeningChoice:
        return LessonType.listeningChoice;
      case QuestionType.infoNote:
        return LessonType.info;
      case QuestionType.conversation:
        return LessonType.conversation;
      case QuestionType.sentenceExample:
        return LessonType.sentenceExample;
      case null:
        return LessonType.flashcard;
    }
  }

  void nextStep(bool wasCorrect) {
    if (_currentIndex < _steps.length) {
      final currentStep = _steps[_currentIndex];

      if (wasCorrect) {
        _sessionCorrectCount++;
        final idToSave = lessonId ?? _resolvedId;
        if (idToSave != null) {
          ProgressService.instance.markStepAsCompleted(
            idToSave,
            currentStep.originalIndex,
            stepId: currentStep.rawData?.id,
          );
        }
      } else {
        _failedSteps.add(currentStep);
      }

      _currentIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentIndex > 0) {
      _currentIndex--;
      notifyListeners();
    }
  }

  void jumpToStep(int index) {
    if (index >= 0 && index < _steps.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void startReviewMistakes() {
    if (_failedSteps.isEmpty) return;

    _steps = List.from(_failedSteps);
    _failedSteps.clear();
    _currentIndex = 0;
    _sessionCorrectCount = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    _steps.clear();
    _failedSteps.clear();
    _currentPlan = null;
    DataService.instance.unloadLesson(lessonId ?? _resolvedId);
    super.dispose();
  }
}
