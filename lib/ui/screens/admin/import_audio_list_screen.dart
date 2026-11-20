import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/widgets/editor/category_picker.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ImportAudioItem {
  final LessonPlan plan;
  final LessonStepData step;
  final int index;
  final String text;
  final String typeName;
  final QuestionType questionType;

  ImportAudioItem({
    required this.plan,
    required this.step,
    required this.index,
    required this.text,
    required this.typeName,
    required this.questionType,
  });

  String get displayText => text;
  String get textToSpeak => text;
  String get typeDisplayName => typeName;
}

class ImportAudioListScreen extends StatefulWidget {
  const ImportAudioListScreen({super.key});

  @override
  State<ImportAudioListScreen> createState() => _ImportAudioListScreenState();
}

class _ImportAudioListScreenState extends State<ImportAudioListScreen> {
  String? _selectedCategory;
  String _selectedEmoji = '📚';
  bool _isLoadingItems = false;
  List<ImportAudioItem> _targetItems = [];
  int? _playingIndex;

  Future<void> _selectCategory() async {
    final result = await showCategoryPicker(context);
    if (result != null && result['name'] != null) {
      setState(() {
        _selectedCategory = result['name'];
        _selectedEmoji = result['emoji'] ?? '📚';
      });
      _loadCategoryItems(result['name']!);
    }
  }

  String _getStepText(LessonStepData step) {
    if (step.thai.trim().isNotEmpty) return step.thai.trim();
    if (step.question.trim().isNotEmpty) return step.question.trim();
    if (step.answer.trim().isNotEmpty) return step.answer.trim();
    if (step.english.trim().isNotEmpty) return step.english.trim();
    return '';
  }

  String _getTypeDisplayName(QuestionType type) {
    switch (type) {
      case QuestionType.flashcard:
        return 'flashcard';
      case QuestionType.vowelFill:
        return 'vowel fill';
      case QuestionType.infoNote:
        return 'info note';
      case QuestionType.fourChoice:
        return 'four choice';
      case QuestionType.completeSentence:
        return 'complete sentence';
      case QuestionType.listeningChoice:
        return 'listening choice';
      case QuestionType.sentenceOrder:
        return 'sentence order';
      case QuestionType.sentenceExample:
        return 'sentence example';
      case QuestionType.conversation:
        return 'conversation';
      case QuestionType.meaning:
        return 'meaning';
      case QuestionType.speaking:
        return 'speaking';
      case QuestionType.listening:
        return 'listening';
    }
  }

  Future<void> _loadCategoryItems(String category) async {
    setState(() {
      _isLoadingItems = true;
      _targetItems = [];
    });

    try {
      final allPlans = await DataService.instance.getAllLessonPlans();
      final categoryPlans =
          allPlans.where((p) => p.category == category).toList()
            ..sort((a, b) => a.index.compareTo(b.index));

      final List<ImportAudioItem> items = [];
      int globalIndex = 1;

      for (var plan in categoryPlans) {
        LessonPlan? fullPlan = plan;
        if (plan.steps.any((s) => s.id.startsWith('placeholder_'))) {
          fullPlan = await DataService.instance.getLessonPlanById(plan.id);
        }
        if (fullPlan != null) {
          for (var step in fullPlan.steps) {
            if (step.conversation != null && step.conversation!.isNotEmpty) {
              for (var msg in step.conversation!) {
                final msgText = msg.text.trim();
                if (msgText.isNotEmpty) {
                  items.add(
                    ImportAudioItem(
                      plan: fullPlan,
                      step: step,
                      index: globalIndex++,
                      text: msgText,
                      typeName: _getTypeDisplayName(step.questionType),
                      questionType: step.questionType,
                    ),
                  );
                }
              }
            } else {
              final text = _getStepText(step);
              if (text.isNotEmpty) {
                items.add(
                  ImportAudioItem(
                    plan: fullPlan,
                    step: step,
                    index: globalIndex++,
                    text: text,
                    typeName: _getTypeDisplayName(step.questionType),
                    questionType: step.questionType,
                  ),
                );
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _targetItems = items;
          _isLoadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingItems = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _playAudio(ImportAudioItem item) async {
    final text = item.textToSpeak;
    if (text.isEmpty) return;

    setState(() {
      _playingIndex = item.index;
    });

    await AudioService.instance.speakThai(text);

    if (mounted && _playingIndex == item.index) {
      setState(() {
        _playingIndex = null;
      });
    }
  }

  Future<void> _onSave() async {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    if (_targetItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No question items found in this category'),
        ),
      );
      return;
    }

    final safeCategory = _selectedCategory!
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final filename = '$safeCategory.xlsx';

    final confirm = await ThaiDialogs.showConfirmDialog(
      context,
      title: "Confirm Save",
      content:
          "Do you want to copy and save the category list as $filename to Downloads folder?",
      confirmLabel: "Yes",
      cancelLabel: "No",
    );
    if (!confirm) return;

    final buffer = StringBuffer();
    buffer.writeln('${_selectedCategory!}\t');
    for (var item in _targetItems) {
      buffer.writeln(
        '${item.index}.${item.displayText}\t${item.typeDisplayName}',
      );
    }

    final content = buffer.toString();

    await Clipboard.setData(ClipboardData(text: content));

    String savedPathMessage = '';
    try {
      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          await downloadDir.create(recursive: true);
        }
      } else {
        downloadDir = Directory.systemTemp;
      }

      final file = File('${downloadDir.path}/$filename');
      await file.writeAsString(content);
      savedPathMessage = ' and saved $filename to Downloads folder';
    } catch (e) {
      debugPrint("File save error: $e");
      savedPathMessage = ' (Failed to save file: $e)';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('List items copied successfully$savedPathMessage'),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.flashcard:
        return Colors.blue;
      case QuestionType.vowelFill:
        return Colors.orange;
      case QuestionType.infoNote:
        return Colors.purple;
      case QuestionType.fourChoice:
        return Colors.green;
      case QuestionType.completeSentence:
        return Colors.teal;
      case QuestionType.speaking:
        return Colors.red;
      case QuestionType.listening:
      case QuestionType.listeningChoice:
        return Colors.indigo;
      case QuestionType.conversation:
        return Colors.deepPurple;
      case QuestionType.sentenceExample:
        return Colors.amber.shade900;
      default:
        return Colors.deepOrange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const ThaiAppBar(
        title: "Import Audio List",
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.2),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _selectCategory,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _selectedCategory != null
                                ? _selectedEmoji
                                : '📚',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "CATEGORY",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedCategory ?? "Select Category",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _selectedCategory != null
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: _selectedCategory != null
                                      ? theme.textTheme.bodyLarge?.color
                                      : theme.hintColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down_circle_outlined,
                          color: primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _onSave,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text(
                    "Save",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_selectedCategory != null) ...[
                Text(
                  "Question items in category (${_targetItems.length})",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (_isLoadingItems)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_targetItems.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        "No question items in this category",
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _targetItems.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _targetItems[idx];
                      final isPlaying = _playingIndex == item.index;

                      return Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        color: theme.cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  "${item.index}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.displayText,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getTypeColor(
                                              item.questionType,
                                            ).withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.typeDisplayName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _getTypeColor(
                                                item.questionType,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.volume_up_rounded
                                      : Icons.volume_up_outlined,
                                  color: isPlaying
                                      ? primaryColor
                                      : theme.iconTheme.color?.withValues(
                                          alpha: 0.7,
                                        ),
                                ),
                                tooltip: "Listen",
                                onPressed: () => _playAudio(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
