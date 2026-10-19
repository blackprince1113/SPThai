import 'dart:math';
import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/data_service.dart';
import 'package:superthai/core/services/sound_service.dart';

class FourChoiceController extends ChangeNotifier {
  WordEntry word;
  final String category;
  List<String>? initialChoices;
  String? correctAnswer;
  int? correctIndex;

  List<WordEntry> choices = [];
  bool _answered = false;
  bool _answerCorrect = false;
  String? _selectedAnswer;
  bool _isLoading = true;
  int _generation = 0;
  bool _disposed = false;

  bool get answered => _answered;
  bool get answerCorrect => _answerCorrect;
  String? get selectedAnswer => _selectedAnswer;
  bool get isLoading => _isLoading;

  FourChoiceController({
    required this.word,
    required this.category,
    this.initialChoices,
    this.correctAnswer,
  }) {
    _syncCorrectIndex();
    _generateChoices();
  }

  void _syncCorrectIndex() {
    if (initialChoices != null && correctAnswer != null) {
      final answerIndex = initialChoices!.indexOf(correctAnswer!);
      if (answerIndex != -1) {
        correctIndex = answerIndex;
      }
    }
  }

  void updateData({
    required WordEntry newWord,
    required List<String>? newChoices,
    String? newAnswer,
  }) {
    _generation++;
    word = newWord;
    initialChoices = newChoices;
    correctAnswer = newAnswer;
    _syncCorrectIndex();
    _generateChoices();
  }

  void setCorrectIndex(int index, String text) {
    correctIndex = index;
    correctAnswer = text;
    notifyListeners();
  }

  Future<void> _generateChoices() async {
    final generation = ++_generation;
    _isLoading = true;
    if (initialChoices != null) {
      List<String> paddedChoices = List.from(initialChoices!);
      while (paddedChoices.length < 4) {
        paddedChoices.add("");
      }

      choices = paddedChoices.asMap().entries.map((entry) {
        final choiceIndex = entry.key;
        final choiceText = entry.value;
        return WordEntry(
          id: 'edit_choice_$choiceIndex',
          thai: choiceText,
          phonetic: '',
          english: choiceText,
          category: 'temp',
        );
      }).toList();

      _isLoading = false;
      if (!_disposed && generation == _generation) notifyListeners();
      return;
    }

    final random = Random();
    final allWords = await DataService.instance.getWordsByCategory(category);
    if (_disposed || generation != _generation) return;

    // Reservoir sampling selects up to three distractors without copying and
    // shuffling the full category list for every question.
    final distractors = <WordEntry>[];
    var eligibleCount = 0;
    for (final candidate in allWords) {
      if (candidate.thai == word.thai) continue;
      eligibleCount++;
      if (distractors.length < 3) {
        distractors.add(candidate);
      } else {
        final replaceIndex = random.nextInt(eligibleCount);
        if (replaceIndex < 3) distractors[replaceIndex] = candidate;
      }
    }
    choices = [word, ...distractors];
    choices.shuffle(random);
    _isLoading = false;
    notifyListeners();
  }

  bool isCorrect(WordEntry choice) {
    if (correctIndex != null && initialChoices != null) {
      final choiceIndex = choices.indexOf(choice);
      return choiceIndex == correctIndex;
    }

    return choice.thai.trim().toLowerCase() == word.thai.trim().toLowerCase() ||
        choice.english.trim().toLowerCase() ==
            word.english.trim().toLowerCase();
  }

  void selectChoice(WordEntry choice) {
    if (_answered) return;
    _answered = true;
    _answerCorrect = isCorrect(choice);
    _selectedAnswer = choice.english;

    if (_answerCorrect) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
