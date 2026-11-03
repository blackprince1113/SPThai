import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._internal() {
    _player.setVolume(0.15);
  }
  static final SoundService _instance = SoundService._internal();
  static SoundService get instance => _instance;

  final AudioPlayer _player = AudioPlayer();

  Future<void> playCorrect() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/correct.mp3'));
    } catch (e) {
      debugPrint("Error playing correct sound: $e");
    }
  }

  Future<void> playWrong() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/wrong.mp3'));
    } catch (e) {
      debugPrint("Error playing wrong sound: $e");
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint("Error stopping sound: $e");
    }
  }

  void dispose() {
    _player.dispose();
  }
}
