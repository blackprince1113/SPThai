import 'dart:async';
import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/sound_service.dart';

class ListeningController extends ChangeNotifier {
  final WordEntry word;
  final AudioService _audio = AudioService.instance;
  final TextEditingController textController = TextEditingController();

  bool _answered = false;
  bool _isCorrect = false;
  Timer? _initialSpeakTimer;
  bool _disposed = false;

  bool get answered => _answered;
  bool get isCorrect => _isCorrect;

  ListeningController(this.word) {
    textController.addListener(_notify);
  }

  void init() {
    _initialSpeakTimer = Timer(const Duration(milliseconds: 500), () {
      speakThaiNormal();
    });
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> speakThaiNormal() async {
    await _audio.speakThai(word.thai, rate: 0.5);
  }

  Future<void> speakThaiSlow() async {
    await _audio.speakThai(word.thai, rate: 0.2);
  }

  void checkAnswer() {
    _answered = true;
    _isCorrect =
        textController.text.trim().toLowerCase() ==
        word.thai.trim().toLowerCase();

    if (_isCorrect) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _initialSpeakTimer?.cancel();
    textController.dispose();
    super.dispose();
  }
}
