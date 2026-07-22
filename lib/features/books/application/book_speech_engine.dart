import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract interface class BookSpeechEngine {
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  });

  void setCompletionHandler(void Function() handler);

  Future<void> speak(String text);

  Future<void> stop();
}

class FlutterBookSpeechEngine implements BookSpeechEngine {
  FlutterBookSpeechEngine({FlutterTts? tts})
    : _delegate = tts != null || !_supportsSystemMediaSession
          ? _DirectBookSpeechEngine(tts: tts)
          : _AudioServiceBookSpeechEngine();

  static bool get _supportsSystemMediaSession =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  final BookSpeechEngine _delegate;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  }) => _delegate.configure(
    languageCode: languageCode,
    rate: rate,
    pitch: pitch,
    bookTitle: bookTitle,
    chapterTitle: chapterTitle,
  );

  @override
  void setCompletionHandler(void Function() handler) =>
      _delegate.setCompletionHandler(handler);

  @override
  Future<void> speak(String text) => _delegate.speak(text);

  @override
  Future<void> stop() => _delegate.stop();
}

class _DirectBookSpeechEngine implements BookSpeechEngine {
  _DirectBookSpeechEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
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

class _AudioServiceBookSpeechEngine implements BookSpeechEngine {
  static Future<_BookTtsAudioHandler>? _handlerFuture;
  void Function()? _completionHandler;

  Future<_BookTtsAudioHandler> get _handler async {
    final handler = await (_handlerFuture ??= _createHandler());
    handler.completionHandler = _completionHandler;
    return handler;
  }

  static Future<_BookTtsAudioHandler> _createHandler() async {
    final handler = await AudioService.init(
      builder: _BookTtsAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.va97ra.literia.reading',
        androidNotificationChannelName: 'Чтение вслух',
        androidStopForegroundOnPause: false,
      ),
    );
    return handler;
  }

  @override
  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  }) async {
    final handler = await _handler;
    await handler.configure(
      languageCode: languageCode,
      rate: rate,
      pitch: pitch,
      bookTitle: bookTitle,
      chapterTitle: chapterTitle,
    );
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _completionHandler = handler;
    final future = _handlerFuture;
    if (future != null) {
      unawaited(future.then((value) => value.completionHandler = handler));
    }
  }

  @override
  Future<void> speak(String text) async => (await _handler).speakText(text);

  @override
  Future<void> stop() async => (await _handler).stop();
}

class _BookTtsAudioHandler extends BaseAudioHandler {
  _BookTtsAudioHandler() : _tts = FlutterTts() {
    _tts.setCompletionHandler(() {
      _broadcast(playing: false, state: AudioProcessingState.completed);
      completionHandler?.call();
    });
    _tts.setCancelHandler(
      () => _broadcast(playing: false, state: AudioProcessingState.ready),
    );
    _tts.setErrorHandler(
      (_) => _broadcast(playing: false, state: AudioProcessingState.error),
    );
  }

  final FlutterTts _tts;
  void Function()? completionHandler;
  String _currentText = '';

  Future<void> configure({
    required String languageCode,
    required double rate,
    required double pitch,
    required String bookTitle,
    required String chapterTitle,
  }) async {
    mediaItem.add(
      MediaItem(
        id: 'literia-tts',
        title: chapterTitle,
        album: bookTitle,
        artist: 'Литерия',
      ),
    );
    await _tts.setLanguage(languageCode == 'en' ? 'en-US' : 'ru-RU');
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _tts.setQueueMode(0);
      await _tts.setAudioAttributesForNavigation();
    }
    await _tts.awaitSpeakCompletion(false);
    _broadcast(playing: false, state: AudioProcessingState.ready);
  }

  Future<void> speakText(String text) async {
    _currentText = text;
    if (_currentText.isEmpty) return;
    _broadcast(playing: true, state: AudioProcessingState.ready);
    await _tts.speak(_currentText);
  }

  @override
  Future<void> play() async {
    if (_currentText.isEmpty) return;
    await speakText(_currentText);
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
    _broadcast(playing: false, state: AudioProcessingState.ready);
  }

  @override
  Future<void> stop() async {
    _currentText = '';
    await _tts.stop();
    _broadcast(playing: false, state: AudioProcessingState.idle);
    await super.stop();
  }

  void _broadcast({
    required bool playing,
    required AudioProcessingState state,
  }) {
    final controls = playing
        ? const [MediaControl.pause]
        : const [MediaControl.play];
    playbackState.add(
      PlaybackState(
        controls: controls,
        androidCompactActionIndices: const [0],
        processingState: state,
        playing: playing,
      ),
    );
  }
}
