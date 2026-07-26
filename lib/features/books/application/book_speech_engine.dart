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

  void setErrorHandler(void Function(String message) handler);

  Future<void> speak(String text);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();
}

abstract interface class BookSpeechProgressEngine {
  void setProgressHandler(void Function(int start, int end) handler);
}

class FlutterBookSpeechEngine
    implements BookSpeechEngine, BookSpeechProgressEngine {
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
  void setProgressHandler(void Function(int start, int end) handler) {
    final delegate = _delegate;
    if (delegate is BookSpeechProgressEngine) {
      (delegate as BookSpeechProgressEngine).setProgressHandler(handler);
    }
  }

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
  void setErrorHandler(void Function(String message) handler) =>
      _delegate.setErrorHandler(handler);

  @override
  Future<void> speak(String text) => _delegate.speak(text);

  @override
  Future<void> pause() => _delegate.pause();

  @override
  Future<void> resume() => _delegate.resume();

  @override
  Future<void> stop() => _delegate.stop();
}

class _DirectBookSpeechEngine
    implements BookSpeechEngine, BookSpeechProgressEngine {
  _DirectBookSpeechEngine({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  String _currentText = '';

  @override
  void setProgressHandler(void Function(int start, int end) handler) {
    _tts.setProgressHandler((spokenText, start, end, _) {
      final base = spokenText == _currentText
          ? 0
          : _currentText.indexOf(spokenText).clamp(0, _currentText.length);
      handler(base + start, base + end);
    });
  }

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
  void setErrorHandler(void Function(String message) handler) {
    _tts.setErrorHandler((message) => handler(message.toString()));
  }

  @override
  Future<void> speak(String text) async {
    _currentText = text;
    await _tts.speak(text);
  }

  @override
  Future<void> pause() async {
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    if (_currentText.isNotEmpty) await _tts.speak(_currentText);
  }

  @override
  Future<void> stop() async {
    _currentText = '';
    await _tts.stop();
  }
}

class _AudioServiceBookSpeechEngine
    implements BookSpeechEngine, BookSpeechProgressEngine {
  static Future<_BookTtsAudioHandler>? _handlerFuture;
  void Function()? _completionHandler;
  void Function(String message)? _errorHandler;
  void Function(int start, int end)? _progressHandler;

  Future<_BookTtsAudioHandler> get _handler async {
    final handler = await (_handlerFuture ??= _createHandler());
    handler.completionHandler = _completionHandler;
    handler.errorHandler = _errorHandler;
    handler.progressHandler = _progressHandler;
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
  void setErrorHandler(void Function(String message) handler) {
    _errorHandler = handler;
    final future = _handlerFuture;
    if (future != null) {
      unawaited(future.then((value) => value.errorHandler = handler));
    }
  }

  @override
  void setProgressHandler(void Function(int start, int end) handler) {
    _progressHandler = handler;
    final future = _handlerFuture;
    if (future != null) {
      unawaited(future.then((value) => value.progressHandler = handler));
    }
  }

  @override
  Future<void> speak(String text) async => (await _handler).speakText(text);

  @override
  Future<void> pause() async => (await _handler).pause();

  @override
  Future<void> resume() async => (await _handler).play();

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
    _tts.setErrorHandler((message) {
      _broadcast(playing: false, state: AudioProcessingState.error);
      errorHandler?.call(message);
    });
    _tts.setProgressHandler((spokenText, start, end, _) {
      final base = spokenText == _currentText
          ? 0
          : _currentText.indexOf(spokenText).clamp(0, _currentText.length);
      progressHandler?.call(base + start, base + end);
    });
  }

  final FlutterTts _tts;
  void Function()? completionHandler;
  void Function(String message)? errorHandler;
  void Function(int start, int end)? progressHandler;
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
