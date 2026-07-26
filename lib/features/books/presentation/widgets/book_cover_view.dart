import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/books/domain/book_project.dart';
import 'package:flutter/material.dart';

class BookCoverView extends StatelessWidget {
  const BookCoverView({
    required this.project,
    required this.width,
    required this.height,
    this.borderRadius = 8,
    super.key,
  });

  final BookProject project;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final cover = project.coverAsset;
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return RepaintBoundary(
      child: SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logicalWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : 320.0;
            final logicalHeight = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 480.0;
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: cover == null
                  ? ColoredBox(
                      color: AppTheme.accent.withValues(alpha: 0.16),
                      child: const Icon(
                        Icons.auto_stories_outlined,
                        color: AppTheme.accent,
                      ),
                    )
                  : Image.memory(
                      cover.bytes,
                      key: ValueKey('book-cover-${project.id}-${cover.id}'),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
                      cacheWidth: (logicalWidth * pixelRatio).round().clamp(
                        1,
                        2048,
                      ),
                      cacheHeight: (logicalHeight * pixelRatio).round().clamp(
                        1,
                        3072,
                      ),
                      errorBuilder: (_, _, _) => ColoredBox(
                        color: AppTheme.accent.withValues(alpha: 0.16),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppTheme.accent,
                        ),
                      ),
                    ),
            );
          },
        ),
      ),
    );
  }
}
