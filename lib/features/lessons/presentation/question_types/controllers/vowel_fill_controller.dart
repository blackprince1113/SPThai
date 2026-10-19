import 'dart:async';
import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/sound_service.dart';

class VowelFillController extends ChangeNotifier {
  WordEntry word;
  final AudioService _audio = AudioService.instance;

  String? _selectedAnswer;
  bool _answered = false;
  bool _isCorrect = false;
  Timer? _initialSpeakTimer;

  String? get selectedAnswer => _selectedAnswer;
  bool get answered => _answered;
  bool get isCorrect => _isCorrect;

  VowelFillController(this.word);

  void init() {
    _initialSpeakTimer = Timer(const Duration(milliseconds: 500), () {
      speakThaiNormal();
    });
  }

  void updateWord(WordEntry newWord) {
    word = newWord;
  }

  Future<void> speakThaiNormal() async {
    if (word.thai.isEmpty) return;
    await _audio.speakThai(word.thai, rate: 0.5);
  }

  Future<void> speakThaiSlow() async {
    if (word.thai.isEmpty) return;
    await _audio.speakThai(word.thai, rate: 0.2);
  }

  void selectChoice(String choice, String correctAnswer) {
    if (_answered) return;
    _selectedAnswer = choice;
    _answered = true;
    _isCorrect =
        choice.trim().toLowerCase() == correctAnswer.trim().toLowerCase();

    if (_isCorrect) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  void reset() {
    _selectedAnswer = null;
    _answered = false;
    _isCorrect = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _initialSpeakTimer?.cancel();
    super.dispose();
  }
}
