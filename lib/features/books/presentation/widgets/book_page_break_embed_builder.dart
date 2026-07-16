import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class BookPageBreakEmbedBuilder extends EmbedBuilder {
  const BookPageBreakEmbedBuilder({this.showLabel = true});

  final bool showLabel;

  @override
  String get key => 'bookPageBreak';

  @override
  String toPlainText(Embed node) => '\n';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    if (!showLabel) return const SizedBox(height: 8);
    final color = Theme.of(context).colorScheme.outlineVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        key: const ValueKey('book-page-break-marker'),
        children: [
          Expanded(child: Divider(color: color)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              AppStrings.of(context).pageBreak,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Divider(color: color)),
        ],
      ),
    );
  }
}
