import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/ui/theme/app_theme.dart';
import 'package:superthai/ui/widgets/shared_widgets.dart';

class FlashcardTakePage extends StatefulWidget {
  final WordEntry word;
  final bool showAppBar;
  final int currentIndex;
  final int totalSteps;
  final bool isActive;

  const FlashcardTakePage({
    super.key,
    required this.word,
    this.showAppBar = true,
    this.currentIndex = 0,
    this.totalSteps = 1,
    this.isActive = false,
  });

  @override
  State<FlashcardTakePage> createState() => _FlashcardTakePageState();
}

class _FlashcardTakePageState extends State<FlashcardTakePage> {
  final AudioService _audio = AudioService.instance;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
    if (widget.isActive) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) speakThaiNormal();
      });
    }
  }

  @override
  void didUpdateWidget(FlashcardTakePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.word.id != oldWidget.word.id) {
      _checkFavoriteStatus();
    }
    if (widget.isActive && !oldWidget.isActive) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) speakThaiNormal();
      });
    }
  }

  Future<void> _checkFavoriteStatus() async {
    final wordId = widget.word.stableId;
    final status = await DataService.instance.isFavorite(wordId);
    if (mounted && widget.word.stableId == wordId) {
      setState(() {
        _isFavorite = status;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final previousValue = _isFavorite;
    setState(() {
      _isFavorite = !_isFavorite;
    });
    try {
      await DataService.instance.toggleFavorite(widget.word);
    } catch (_) {
      if (mounted) setState(() => _isFavorite = previousValue);
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isFavorite ? "Added to favorites" : "Removed from favorites",
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> speakThaiNormal() async {
    await _audio.speakThai(widget.word.thai);
  }

  Future<void> speakThaiSlow() async {
    await _audio.speakThai(widget.word.thai, rate: 0.2);
  }

  @override
  Widget build(BuildContext context) {
    Widget content = SingleChildScrollView(
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
              headerWidget: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    "NEW VOCABULARY",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Positioned(
                    right: 12,
                    child: GestureDetector(
                      onTap: _toggleFavorite,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _isFavorite
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          color: _isFavorite
                              ? Colors.red
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              illustrationSource: widget.word.imageUrl,
              illustrationHeight: 180,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                children: [
                  Text(
                    widget.word.thai,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        widget.word.thai,
                        38,
                      ),
                      fontWeight: FontWeight.bold,
                      color:
                          Theme.of(context).textTheme.headlineLarge?.color ??
                          AppTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.word.phonetic,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        widget.word.phonetic,
                        20,
                      ),
                      color: AppTheme.primaryColor.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  const ThaiSectionLabel(label: "MEANING"),
                  const SizedBox(height: 8),
                  Text(
                    widget.word.english,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: AppTheme.getResponsiveFontSize(
                        widget.word.english,
                        28,
                      ),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ThaiSoundButtonsRow(
                    onNormal: speakThaiNormal,
                    onSlow: speakThaiSlow,
                    spacing: 48,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                onPressed: () {
                  StepResultNotification(true).dispatch(context);
                },
                child: const Text(
                  "I'VE GOT IT!",
                  style: TextStyle(fontSize: 18, letterSpacing: 1.2),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      content = SafeArea(child: content);
    }

    return Scaffold(
      appBar: widget.showAppBar ? const ThaiAppBar(title: "Flashcard") : null,
      body: content,
    );
  }
}
