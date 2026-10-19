import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:superthai/core/services/speech_service.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/audio_service.dart';
import 'package:superthai/core/services/sound_service.dart';

class SpeakingController extends ChangeNotifier {
  final WordEntry word;
  final AudioService _audio = AudioService.instance;
  final _stt = SpeechService.instance.recognizer;

  bool _isSpeechAvailable = false;
  bool _isListening = false;
  String _recognizedText = "";
  bool? _answerCorrect;
  bool _answered = false;
  bool _disposed = false;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;
  bool? get answerCorrect => _answerCorrect;
  bool get answered => _answered;
  bool get isSpeechAvailable => _isSpeechAvailable;

  SpeakingController(this.word) {
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _stt.initialize();
      if (_disposed) return;
      _isSpeechAvailable = available;
      notifyListeners();
    } catch (_) {
      if (_disposed) return;
      _isSpeechAvailable = false;
      notifyListeners();
    }
  }

  Future<void> speakThaiNormal() async {
    await _audio.speakThai(word.thai, rate: 0.5);
  }

  Future<void> speakThaiSlow() async {
    await _audio.speakThai(word.thai, rate: 0.2);
  }

  void startListening() async {
    if (_disposed || !_isSpeechAvailable) return;

    _isListening = true;
    _recognizedText = "";
    _answered = false;
    _answerCorrect = null;
    notifyListeners();

    await _stt.listen(
      onResult: (result) {
        if (_disposed) return;
        _recognizedText = result.recognizedWords;
        if (result.finalResult) {
          _isListening = false;
          _checkAnswer();
        }
        notifyListeners();
      },
      listenOptions: SpeechListenOptions(localeId: "th-TH"),
    );
  }

  void stopListening() async {
    await _stt.stop();
    if (_disposed) return;
    _isListening = false;
    _checkAnswer();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _stt.stop();
    super.dispose();
  }

  void _checkAnswer() {
    if (_recognizedText.isEmpty) return;

    String target = word.thai
        .replaceAll(RegExp(r'[^\u0E00-\u0E7F]'), '')
        .trim();
    String recognized = _recognizedText
        .replaceAll(RegExp(r'[^\u0E00-\u0E7F]'), '')
        .trim();

    _answered = true;
    _answerCorrect =
        recognized == target ||
        recognized.contains(target) ||
        target.contains(recognized);

    if (_answerCorrect!) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }
  }
}
