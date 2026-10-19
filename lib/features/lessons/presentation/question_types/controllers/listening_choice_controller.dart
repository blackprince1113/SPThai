import 'dart:async';
import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/sound_service.dart';

class ListeningChoiceController extends ChangeNotifier {
  final WordEntry word;
  final List<String> initialChoices;
  final String? correctAnswer;
  final AudioService _audio = AudioService.instance;

  List<String> _choices = [];
  String? _selectedAnswer;
  bool _answered = false;
  bool _isLoading = true;
  Timer? _initialSpeakTimer;

  List<String> get choices => _choices;
  String? get selectedAnswer => _selectedAnswer;
  bool get answered => _answered;
  bool get isLoading => _isLoading;

  ListeningChoiceController({
    required this.word,
    required this.initialChoices,
    this.correctAnswer,
  });

  void init() {
    _setupChoices();
    _initialSpeakTimer = Timer(const Duration(milliseconds: 500), () {
      speakThaiNormal();
    });
  }

  void _setupChoices() {
    _isLoading = true;
    notifyListeners();

    _choices = List.from(initialChoices);

    final targetAnswer = correctAnswer ?? word.thai;
    if (!_choices.contains(targetAnswer)) {
      if (_choices.length < 4) {
        _choices.add(targetAnswer);
      } else {
        _choices[0] = targetAnswer;
      }
    }

    _choices.shuffle();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> speakThaiNormal() async {
    await _audio.speakThai(word.thai, rate: 0.4);
  }

  Future<void> speakThaiSlow() async {
    await _audio.speakThai(word.thai, rate: 0.2);
  }

  void selectChoice(String choice) {
    if (_answered) return;
    _selectedAnswer = choice;
    _answered = true;

    if (answerCorrect) {
      SoundService.instance.playCorrect();
      _audio.speakThai(word.thai);
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  bool isCorrect(String choice) {
    final target = (correctAnswer ?? word.thai).trim().toLowerCase();
    return choice.trim().toLowerCase() == target;
  }

  bool get answerCorrect {
    if (_selectedAnswer == null) return false;
    return isCorrect(_selectedAnswer!);
  }

  void updateData({
    required WordEntry newWord,
    required List<String> newChoices,
    String? newAnswer,
  }) {}

  @override
  void dispose() {
    _initialSpeakTimer?.cancel();
    super.dispose();
  }
}
