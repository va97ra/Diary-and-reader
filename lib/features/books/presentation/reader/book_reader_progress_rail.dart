import 'package:flutter/material.dart';

class BookReaderProgressRail extends StatelessWidget {
  const BookReaderProgressRail({
    required this.value,
    required this.trackColor,
    required this.progressColor,
    required this.semanticLabel,
    super.key,
  });

  final double value;
  final Color trackColor;
  final Color progressColor;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final normalizedValue = value.clamp(0, 1).toDouble();
    return IgnorePointer(
      child: Semantics(
        container: true,
        label: semanticLabel,
        value: '${(normalizedValue * 100).round()}%',
        child: SizedBox(
          key: const ValueKey('reader-progress-rail'),
          width: 3,
          child: LayoutBuilder(
            builder: (context, constraints) => ColoredBox(
              color: trackColor,
              child: Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  key: const ValueKey('reader-progress-fill'),
                  width: 3,
                  height: constraints.maxHeight * normalizedValue,
                  child: ColoredBox(color: progressColor),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
