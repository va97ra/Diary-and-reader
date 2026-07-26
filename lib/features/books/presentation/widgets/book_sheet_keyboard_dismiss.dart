import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Gives every modal book panel the same desktop escape-key behavior.
class BookSheetKeyboardDismiss extends StatelessWidget {
  const BookSheetKeyboardDismiss({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => CallbackShortcuts(
    bindings: {
      const SingleActivator(LogicalKeyboardKey.escape): () {
        Navigator.maybePop(context);
      },
    },
    child: Focus(autofocus: true, child: child),
  );
}
