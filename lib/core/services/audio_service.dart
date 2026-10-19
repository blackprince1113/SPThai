import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  AudioService._() {
    _configuration = _configure();
  }

  static final AudioService instance = AudioService._();

  final FlutterTts tts = FlutterTts();
  late final Future<void> _configuration;
  Future<void> _queue = Future<void>.value();

  Future<void> _configure() async {
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);
    await tts.setLanguage('th-TH');
    await tts.setSpeechRate(0.5);
  }

  Future<void> speakThai(String text, {double rate = 0.5}) {
    final operation = _queue.then((_) async {
      await _configuration;
      await tts.setLanguage('th-TH');
      await tts.setSpeechRate(rate);
      await tts.speak(text);
    });
    _queue = operation.catchError((_) {});
    return operation;
  }
}
