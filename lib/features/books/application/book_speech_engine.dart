import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class BookSpeechEngine {
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
  });

  void setCompletionHandler(void Function() handler);

  Future<void> speak(String text);

  Future<void> stop();
}

class FlutterBookSpeechEngine implements BookSpeechEngine {
  FlutterBookSpeechEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
  }) async {
    await _tts.setLanguage(languageCode == 'en' ? 'en-US' : 'ru-RU');
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _tts.setQueueMode(0);
      await _tts.setAudioAttributesForNavigation();
    }
    await _tts.awaitSpeakCompletion(false);
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _tts.setCompletionHandler(handler);
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
  }
}
