import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/sound_service.dart';

class SentenceOrderController extends ChangeNotifier {
  WordEntry word;
  List<String> initialChoices;
  String? correctAnswer;

  List<String> availableTokens = [];
  List<String> selectedTokens = [];
  bool _answered = false;
  bool _answerCorrect = false;
  bool _isLoading = true;

  bool get answered => _answered;
  bool get answerCorrect => _answerCorrect;
  bool get isLoading => _isLoading;

  SentenceOrderController({
    required this.word,
    required this.initialChoices,
    this.correctAnswer,
  }) {
    _initialize();
  }

  void _initialize() {
    availableTokens = List.from(initialChoices);
    availableTokens.shuffle();
    selectedTokens = [];
    _answered = false;
    _answerCorrect = false;
    _isLoading = false;
    notifyListeners();
  }

  void updateData({
    required WordEntry newWord,
    required List<String> newChoices,
    String? newAnswer,
  }) {
    word = newWord;
    initialChoices = newChoices;
    correctAnswer = newAnswer;
    _initialize();
  }

  void selectToken(int index) {
    if (_answered) return;
    String token = availableTokens.removeAt(index);
    selectedTokens.add(token);
    notifyListeners();
  }

  void deselectToken(int index) {
    if (_answered) return;
    String token = selectedTokens.removeAt(index);
    availableTokens.add(token);
    notifyListeners();
  }

  void checkAnswer() {
    if (_answered) return;

    String currentSentence = selectedTokens.join('');
    String targetSentence = correctAnswer ?? word.thai;

    targetSentence = targetSentence.replaceAll(' ', '').toLowerCase();
    currentSentence = currentSentence.replaceAll(' ', '').toLowerCase();

    _answered = true;
    _answerCorrect = currentSentence == targetSentence;

    if (_answerCorrect) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  void reset() {
    _initialize();
  }
}
