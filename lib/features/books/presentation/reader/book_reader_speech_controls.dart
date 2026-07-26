import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';

class BookReaderSpeechControls extends StatelessWidget {
  const BookReaderSpeechControls({
    required this.isChoosingStart,
    required this.isPaused,
    required this.rate,
    required this.onCancelChoosing,
    required this.onPauseOrResume,
    required this.onStop,
    required this.onSlower,
    required this.onFaster,
    required this.onSettings,
    required this.backgroundColor,
    required this.foregroundColor,
    super.key,
  });

  final bool isChoosingStart;
  final bool isPaused;
  final double rate;
  final VoidCallback onCancelChoosing;
  final VoidCallback onPauseOrResume;
  final VoidCallback onStop;
  final VoidCallback? onSlower;
  final VoidCallback? onFaster;
  final VoidCallback onSettings;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Material(
      key: const ValueKey('reader-speech-controls'),
      elevation: 5,
      color: backgroundColor,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: IconTheme(
        data: IconThemeData(color: foregroundColor),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: foregroundColor),
          child: isChoosingStart
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app_outlined),
                      const SizedBox(width: 10),
                      Flexible(child: Text(strings.chooseSpeechStart)),
                      IconButton(
                        key: const ValueKey('reader-speech-cancel-target'),
                        tooltip: strings.cancelSpeechStart,
                        onPressed: onCancelChoosing,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const ValueKey('reader-speech-pause-resume'),
                        tooltip: isPaused
                            ? strings.resumeReadingAloud
                            : strings.pauseReadingAloud,
                        onPressed: onPauseOrResume,
                        icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                      ),
                      IconButton(
                        key: const ValueKey('reader-speech-stop'),
                        tooltip: strings.stopReadingAloud,
                        onPressed: onStop,
                        icon: const Icon(Icons.stop),
                      ),
                      IconButton(
                        tooltip: strings.slowerSpeech,
                        onPressed: onSlower,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('${rate.toStringAsFixed(2)}×'),
                      IconButton(
                        tooltip: strings.fasterSpeech,
                        onPressed: onFaster,
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: strings.voiceSettings,
                        onPressed: onSettings,
                        icon: Icon(
                          Icons.tune,
                          semanticLabel: strings.voiceSettings,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
