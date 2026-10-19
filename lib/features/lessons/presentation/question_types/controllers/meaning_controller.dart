import 'package:flutter/material.dart';
import 'package:superthai/core/models/models.dart';
import 'package:superthai/core/services/sound_service.dart';

class MeaningController extends ChangeNotifier {
  final ExampleSentence sentence;
  final TextEditingController textController = TextEditingController();

  bool _checked = false;
  bool _isCorrect = false;

  bool get checked => _checked;
  bool get isCorrect => _isCorrect;

  MeaningController(this.sentence) {
    textController.addListener(_notify);
  }

  void _notify() => notifyListeners();

  void checkAnswer() {
    _checked = true;
    _isCorrect =
        textController.text.trim().toLowerCase() ==
        sentence.gapAnswer.toLowerCase();

    if (_isCorrect) {
      SoundService.instance.playCorrect();
    } else {
      SoundService.instance.playWrong();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
