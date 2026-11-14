import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:superthai/core/enums/question_type.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/editor/category_picker.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class ImportOnlineImageItem {
  final LessonPlan plan;
  final LessonStepData step;
  final int index;

  ImportOnlineImageItem({
    required this.plan,
    required this.step,
    required this.index,
  });

  String get displayText {
    if (step.thai.trim().isNotEmpty) return step.thai.trim();
    if (step.question.trim().isNotEmpty) return step.question.trim();
    if (step.english.trim().isNotEmpty) return step.english.trim();
    return step.id;
  }

  String get typeDisplayName {
    switch (step.questionType) {
      case QuestionType.flashcard:
        return 'flashcard';
      case QuestionType.vowelFill:
        return 'vowel fill';
      case QuestionType.infoNote:
        return 'info note';
      default:
        return step.questionType.displayName.toLowerCase();
    }
  }
}

class ImportOnlineImageScreen extends StatefulWidget {
  const ImportOnlineImageScreen({super.key});

  @override
  State<ImportOnlineImageScreen> createState() =>
      _ImportOnlineImageScreenState();
}

class _ImportOnlineImageScreenState extends State<ImportOnlineImageScreen> {
  String? _selectedCategory;
  String _selectedEmoji = '📚';
  final TextEditingController _linkController = TextEditingController();

  bool _isLoadingItems = false;
  bool _isImporting = false;
  double _importProgress = 0.0;
  String _progressText = '';

  List<ImportOnlineImageItem> _targetItems = [];

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  bool _isTargetStep(LessonStepData step) {
    final type = step.questionType;
    return type == QuestionType.flashcard ||
        type == QuestionType.vowelFill ||
        type == QuestionType.infoNote;
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

      final List<ImportOnlineImageItem> items = [];
      int globalIndex = 1;

      for (var plan in categoryPlans) {
        LessonPlan? fullPlan = plan;
        if (plan.steps.any((s) => s.id.startsWith('placeholder_'))) {
          fullPlan = await DataService.instance.getLessonPlanById(plan.id);
        }
        if (fullPlan != null) {
          for (var step in fullPlan.steps) {
            if (_isTargetStep(step)) {
              items.add(
                ImportOnlineImageItem(
                  plan: fullPlan,
                  step: step,
                  index: globalIndex++,
                ),
              );
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

  String _generateImageUrl(String inputUrl, int index) {
    final trimmed = inputUrl.trim();
    if (trimmed.isEmpty) return '';

    final regex = RegExp(r'^(.* constellation/|.*/)\d+(\.[a-zA-Z0-9]+)$');
    final match = regex.firstMatch(trimmed);

    if (match != null) {
      final prefix = match.group(1)!;
      final ext = match.group(2)!;
      return '$prefix$index$ext';
    }

    final extRegex = RegExp(r'^(.* constellation/|.*/)[^/]+(\.[a-zA-Z0-9]+)$');
    final extMatch = extRegex.firstMatch(trimmed);
    if (extMatch != null) {
      final prefix = extMatch.group(1)!;
      final ext = extMatch.group(2)!;
      return '$prefix$index$ext';
    }

    if (trimmed.endsWith('/')) {
      return '$trimmed$index.png';
    }

    return '$trimmed/$index.png';
  }

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

  Future<void> _onCopyAndExport() async {
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
    final filename = '${safeCategory}.xlsx';

    final confirm = await ThaiDialogs.showConfirmDialog(
      context,
      title: "Confirm Export",
      content:
          "Do you want to copy and save the category list as $filename to Downloads folder?",
      confirmLabel: "Yes",
      cancelLabel: "No",
    );
    if (!confirm) return;

    final buffer = StringBuffer();
    buffer.writeln('${_selectedCategory!}\t');
    for (var item in _targetItems) {
      buffer.writeln('${item.index}.${item.displayText}\t${item.typeDisplayName}');
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

  void _onImportPressed() async {
    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category first')),
      );
      return;
    }

    if (_linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the link of the first image'),
        ),
      );
      return;
    }

    if (_targetItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No flashcard, vowel fill, or info note items found in this category'),
        ),
      );
      return;
    }

    final confirm = await ThaiDialogs.showConfirmDialog(
      context,
      title: "Confirm Import",
      content:
          "Do you want to update image url for ${_targetItems.length} items in category \"$_selectedCategory\"?",
      warningText: "This action cannot be undone.",
      confirmLabel: "Yes",
      cancelLabel: "No",
    );

    if (confirm) {
      _performImport();
    }
  }

  Future<void> _performImport() async {
    setState(() {
      _isImporting = true;
      _importProgress = 0.0;
      _progressText = 'Preparing import...';
    });

    try {
      final inputUrl = _linkController.text.trim();
      final allPlans = await DataService.instance.getAllLessonPlans();
      final categoryPlans =
          allPlans.where((p) => p.category == _selectedCategory).toList()
            ..sort((a, b) => a.index.compareTo(b.index));

      int globalIndex = 1;
      int updatedCount = 0;
      final totalPlans = categoryPlans.length;

      for (int i = 0; i < totalPlans; i++) {
        final plan = categoryPlans[i];
        if (mounted) {
          setState(() {
            _importProgress = (i + 1) / totalPlans;
            _progressText =
                'Updating lesson (${i + 1}/$totalPlans): ${plan.title}';
          });
        }

        LessonPlan? fullPlan = plan;
        if (plan.steps.any((s) => s.id.startsWith('placeholder_'))) {
          fullPlan = await DataService.instance.getLessonPlanById(plan.id);
        }

        if (fullPlan != null) {
          bool planChanged = false;
          final updatedSteps = <LessonStepData>[];

          for (var step in fullPlan.steps) {
            if (_isTargetStep(step)) {
              final newUrl = _generateImageUrl(inputUrl, globalIndex++);
              step.imageUrl = newUrl;
              planChanged = true;
              updatedCount++;
            }
            updatedSteps.add(step);
          }

          if (planChanged) {
            final updatedPlan = LessonPlan(
              id: fullPlan.id,
              title: fullPlan.title,
              category: fullPlan.category,
              categoryEmoji: fullPlan.categoryEmoji,
              emoji: fullPlan.emoji,
              steps: updatedSteps,
              creatorId: fullPlan.creatorId,
              createdAt: fullPlan.createdAt,
              index: fullPlan.index,
            );

            await DataService.instance.addLessonPlan(updatedPlan);
          }
        }
      }

      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Images imported successfully! Updated $updatedCount items.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        if (_selectedCategory != null) {
          _loadCategoryItems(_selectedCategory!);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ThaiAppBar(
        title: "Import Online Image",
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_rounded),
            tooltip: "Copy / Download",
            onPressed: _onCopyAndExport,
          ),
        ],
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

              const Text(
                "Enter the link of the first image here",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _linkController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText:
                      "https://pub-3c76a1a9f8a645da8174a56509c4f508.r2.dev/level1-module1-first%20thai%20words/1.png",
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.link_rounded,
                    color: primaryColor,
                  ),
                  suffixIcon: _linkController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _linkController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.2),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: primaryColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (_isImporting) ...[
                Card(
                  elevation: 0,
                  color: primaryColor.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _progressText,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: _importProgress,
                          backgroundColor: primaryColor.withValues(alpha: 0.2),
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isImporting ? null : _onImportPressed,
                  icon: const Icon(Icons.cloud_upload_rounded),
                  label: const Text(
                    "Import",
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Question items to be updated (${_targetItems.length})",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "flashcard, vowel fill, info note",
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.hintColor,
                      ),
                    ),
                  ],
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
                        "No flashcard, vowel fill, or info note items in this category",
                        style: TextStyle(color: theme.hintColor),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _targetItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _targetItems[idx];
                      final inputUrl = _linkController.text.trim();
                      final generatedUrl = inputUrl.isNotEmpty
                          ? _generateImageUrl(inputUrl, item.index)
                          : item.step.imageUrl;

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
                                            color: _getTypeColor(item.step.questionType)
                                                .withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.typeDisplayName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _getTypeColor(item.step.questionType),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (generatedUrl.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        generatedUrl,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: inputUrl.isNotEmpty
                                              ? Colors.green.shade700
                                              : theme.hintColor,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
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

  Color _getTypeColor(QuestionType type) {
    switch (type) {
      case QuestionType.flashcard:
        return Colors.blue;
      case QuestionType.vowelFill:
        return Colors.orange;
      case QuestionType.infoNote:
        return Colors.purple;
      default:
        return Colors.teal;
    }
  }
}
