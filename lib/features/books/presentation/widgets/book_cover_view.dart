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
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: width,
        height: height,
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
                key: const ValueKey('book-cover-image'),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: AppTheme.accent.withValues(alpha: 0.16),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppTheme.accent,
                  ),
                ),
              ),
      ),
    );
  }
}
