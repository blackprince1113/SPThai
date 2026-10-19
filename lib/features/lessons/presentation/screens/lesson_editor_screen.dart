import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/auth_service.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/complete_sentence_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/conversation_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/flashcard_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/four_choice_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/info_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/listening_choice_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/listening_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/meaning_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/sentence_example_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/sentence_order_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/speaking_create_page.dart';
import 'package:superthai/features/lessons/presentation/question_types/create/vowel_fill_create_page.dart';
import 'package:superthai/features/lessons/presentation/widgets/editor/lesson_reorder_sheet.dart';
import 'package:superthai/features/lessons/presentation/widgets/editor/lesson_settings_sheet.dart';
import 'package:superthai/features/lessons/presentation/widgets/editor/question_type_picker_sheet.dart';
import 'package:superthai/features/lessons/presentation/screens/lesson_details_screen.dart';
import 'package:superthai/ui/screens/main_container.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';
import 'package:uuid/uuid.dart';

class CreateScreen extends StatefulWidget {
  final LessonPlan? existingPlan;
  const CreateScreen({super.key, this.existingPlan});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  String _lessonTitle = 'My New Lesson';
  String _lessonCategory = 'General';
  String _categoryEmoji = '🎯';
  String _lessonEmoji = '📚';
  String? _existingId;

  List<LessonStepData> _lessonSteps = [
    LessonStepData(
      type: QuestionType.flashcard.typeKey,
      thai: '',
      phonetic: '',
      english: '',
    ),
  ];
  int _activeStepIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _activeStepIndex);
    _populateExistingPlanData();
  }

  void _populateExistingPlanData() {
    if (widget.existingPlan != null) {
      _existingId = widget.existingPlan!.id;
      _lessonTitle = widget.existingPlan!.title;
      _lessonCategory = widget.existingPlan!.category;
      _categoryEmoji = widget.existingPlan!.categoryEmoji;
      _lessonEmoji = widget.existingPlan!.emoji;
      _lessonSteps = List.from(widget.existingPlan!.steps);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.existingPlan != oldWidget.existingPlan) {
      setState(() {
        if (widget.existingPlan != null) {
          _populateExistingPlanData();
        } else {
          _existingId = null;
          _lessonTitle = 'My New Lesson';
          _lessonCategory = 'General';
          _categoryEmoji = '🎯';
          _lessonEmoji = '📚';
          _lessonSteps = [
            LessonStepData(
              type: QuestionType.flashcard.typeKey,
              thai: '',
              phonetic: '',
              english: '',
            ),
          ];
        }
        _activeStepIndex = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }
  }

  void _addStep() {
    setState(() {
      _lessonSteps.add(
        LessonStepData(
          type: _lessonSteps.last.type,
          thai: '',
          phonetic: '',
          english: '',
        ),
      );
      _activeStepIndex = _lessonSteps.length - 1;
      _pageController.animateToPage(
        _activeStepIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _removeStep(int index) {
    if (_lessonSteps.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("A lesson must have at least one step!")),
      );
      return;
    }
    setState(() {
      _lessonSteps.removeAt(index);
      if (_activeStepIndex >= _lessonSteps.length) {
        _activeStepIndex = _lessonSteps.length - 1;
      }
      _pageController.jumpToPage(_activeStepIndex);
    });
  }

  void _duplicateStep(int index) {
    setState(() {
      final lessonStep = _lessonSteps[index];
      _lessonSteps.insert(
        index + 1,
        LessonStepData(
          type: lessonStep.type,
          thai: lessonStep.thai,
          phonetic: lessonStep.phonetic,
          english: lessonStep.english,
          question: lessonStep.question,
          answer: lessonStep.answer,
          choices: List.from(lessonStep.choices),
        ),
      );
      _activeStepIndex = index + 1;
      _pageController.animateToPage(
        _activeStepIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _showLessonSettings() {
    LessonSettingsSheet.show(
      context,
      title: _lessonTitle,
      category: _lessonCategory,
      categoryEmoji: _categoryEmoji,
      lessonEmoji: _lessonEmoji,
      onSave:
          ({
            required title,
            required category,
            required categoryEmoji,
            required lessonEmoji,
          }) {
            setState(() {
              _lessonTitle = title;
              _lessonCategory = category;
              _categoryEmoji = categoryEmoji;
              _lessonEmoji = lessonEmoji;
            });
          },
    );
  }

  void _showReorderSheet() {
    LessonReorderSheet.show(
      context,
      steps: _lessonSteps,
      activeStepIndex: _activeStepIndex,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final item = _lessonSteps.removeAt(oldIndex);
          _lessonSteps.insert(newIndex, item);

          if (_activeStepIndex == oldIndex) {
            _activeStepIndex = newIndex;
          } else if (oldIndex < _activeStepIndex &&
              newIndex >= _activeStepIndex) {
            _activeStepIndex -= 1;
          } else if (oldIndex > _activeStepIndex &&
              newIndex <= _activeStepIndex) {
            _activeStepIndex += 1;
          }
          _pageController.jumpToPage(_activeStepIndex);
        });
      },
    );
  }

  void _showTestTypePicker() {
    final currentType = _lessonSteps[_activeStepIndex].questionType;
    QuestionTypePickerSheet.show(
      context,
      currentType: currentType,
      onSelectType: (selectedType) {
        setState(() {
          final step = _lessonSteps[_activeStepIndex];
          step.questionType = selectedType;

          if ((selectedType == QuestionType.fourChoice ||
                  selectedType == QuestionType.listeningChoice) &&
              step.choices.length < 4) {
            step.choices.addAll(
              List.generate(4 - step.choices.length, (_) => ''),
            );
          }
        });
      },
    );
  }

  void _saveLesson() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) {
      ThaiDialogs.showSignupPrompt(context);
      return;
    }

    final plan = LessonPlan(
      id: _existingId ?? const Uuid().v4(),
      title: _lessonTitle,
      category: _lessonCategory,
      categoryEmoji: _categoryEmoji.isEmpty ? '🎯' : _categoryEmoji,
      emoji: _lessonEmoji.isEmpty ? '📚' : _lessonEmoji,
      steps: _lessonSteps,
      creatorId: user.uid,
      index: widget.existingPlan?.index ?? 0,
      createdAt: widget.existingPlan?.createdAt,
    );

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LessonDetailsScreen(lessonPlan: plan),
      ),
    );

    if (result == true && mounted) {
      MainContainer.of(context)?.switchToLesson();
    }
  }

  Widget _buildTestPreviewForIndex(int index) {
    final selectedStep = _lessonSteps[index];
    final dummyWord = selectedStep.toWordEntry();
    final dummySentence = selectedStep.toExampleSentence();

    switch (selectedStep.questionType) {
      case QuestionType.flashcard:
        return FlashcardCreatePage(
          word: dummyWord,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.fourChoice:
        return FourChoiceCreatePage(
          word: dummyWord,
          choices: selectedStep.choices,
          correctAnswer: selectedStep.answer,
          category: 'Preview',
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.completeSentence:
        return CompleteSentenceCreatePage(
          sentence: dummySentence,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.meaning:
        return MeaningCreatePage(
          sentence: dummySentence,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.speaking:
        return SpeakingCreatePage(
          word: dummyWord,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.listening:
        return ListeningCreatePage(
          word: dummyWord,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.listeningChoice:
        return ListeningChoiceCreatePage(
          word: dummyWord,
          choices: selectedStep.choices,
          correctAnswer: selectedStep.answer,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.sentenceOrder:
        return SentenceOrderCreatePage(
          word: dummyWord,
          choices: selectedStep.choices,
          correctAnswer: selectedStep.answer,
          category: 'Preview',
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.vowelFill:
        return VowelFillCreatePage(
          word: dummyWord,
          question: selectedStep.question,
          answer: selectedStep.answer,
          choices: selectedStep.choices,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.infoNote:
        return InfoCreatePage(
          title: selectedStep.question,
          content: selectedStep.answer,
          imageUrl: selectedStep.imageUrl,
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.conversation:
        return ConversationCreatePage(
          initialMessages: selectedStep.conversation ?? [],
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
      case QuestionType.sentenceExample:
        return SentenceExampleCreatePage(
          initialSentences: selectedStep.conversation ?? [],
          showAppBar: false,
          onEdit: (field, value) => _updateStepForIndex(index, field, value),
        );
    }
  }

  void _updateStepForIndex(int index, String field, dynamic value) {
    final lessonStep = _lessonSteps[index];
    if (field.startsWith('choice_')) {
      final choiceIndex = int.parse(field.split('_')[1]);
      final oldChoiceText = lessonStep.choices.length > choiceIndex
          ? lessonStep.choices[choiceIndex]
          : "";

      if (lessonStep.choices.length <= choiceIndex) {
        lessonStep.choices.addAll(
          List.generate(choiceIndex - lessonStep.choices.length + 1, (_) => ''),
        );
      }
      lessonStep.choices[choiceIndex] = value;

      if (lessonStep.answer == oldChoiceText && oldChoiceText.isNotEmpty) {
        lessonStep.answer = value;
      }
    } else {
      switch (field) {
        case 'thai':
          lessonStep.thai = value;
          break;
        case 'phonetic':
          lessonStep.phonetic = value;
          break;
        case 'english':
          lessonStep.english = value;
          break;
        case 'question':
          lessonStep.question = value;
          break;
        case 'answer':
          lessonStep.answer = value;
          break;
        case 'imageUrl':
          lessonStep.imageUrl = value;
          break;
        case 'choices':
          lessonStep.choices = List<String>.from(value);
          break;
        case 'conversation':
          lessonStep.conversation = List<ChatMessage>.from(value);
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeStep = _lessonSteps[_activeStepIndex];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ThaiAppBar(
        showProfile: false,
        centerTitle: true,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showTestTypePicker,
                child: Container(
                  height: 40,
                  width: 50,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        activeStep.questionType.icon,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        titleWidget: GestureDetector(
          onTap: _showLessonSettings,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Create",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _lessonTitle,
                style: TextStyle(fontSize: 12, color: theme.disabledColor),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4, left: 4),
            child: ElevatedButton(
              onPressed: _saveLesson,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(60, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "Next",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _activeStepIndex = index;
                });
              },
              itemCount: _lessonSteps.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: _buildTestPreviewForIndex(index),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.editModeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: AppTheme.editModeColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${_activeStepIndex + 1}/${_lessonSteps.length}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.editModeColor,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: AppTheme.editModeColor,
                          ),
                          onPressed: _showReorderSheet,
                          tooltip: 'Reorder Steps',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _lessonSteps.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final isSelected = index == _activeStepIndex;
                          final step = _lessonSteps[index];
                          return InkWell(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 44,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : theme.dividerColor.withValues(
                                          alpha: 0.1,
                                        ),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    step.questionType.icon,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.iconTheme.color?.withValues(
                                            alpha: 0.6,
                                          ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${index + 1}",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : theme.textTheme.bodyMedium?.color
                                                ?.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(Icons.more_vert_rounded),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) {
                      if (value == 'duplicate') {
                        _duplicateStep(_activeStepIndex);
                      } else if (value == 'delete') {
                        _removeStep(_activeStepIndex);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy_rounded, size: 20),
                            SizedBox(width: 12),
                            Text('Duplicate Step'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              size: 20,
                              color: Colors.red,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Delete Step',
                              style: TextStyle(color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _addStep,
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
