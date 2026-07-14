import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/core/theme/app_theme.dart';
import 'package:dnevnik/features/diary/application/diary_controller.dart';
import 'package:dnevnik/features/diary/presentation/diary_home_page.dart';
import 'package:flutter/material.dart';

class BookEntryPoint extends StatefulWidget {
  const BookEntryPoint({required this.controller, super.key});

  final DiaryController controller;

  @override
  State<BookEntryPoint> createState() => _BookEntryPointState();
}

class _BookEntryPointState extends State<BookEntryPoint> {
  bool _isOpen = false;
  bool _isOpening = false;

  Future<void> _open() async {
    if (_isOpening) return;
    setState(() => _isOpening = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _isOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isOpen) return DiaryHomePage(controller: widget.controller);
    final strings = AppStrings.of(context);
    return Scaffold(
      body: Center(
        child: AnimatedScale(
          scale: _isOpening ? 1.25 : 1,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
          child: AnimatedOpacity(
            opacity: _isOpening ? 0 : 1,
            duration: const Duration(milliseconds: 700),
            child: Container(
              width: 390,
              height: 580,
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.fromLTRB(52, 44, 28, 44),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(18),
                ),
                border: Border.all(color: AppTheme.accent, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 40,
                    offset: Offset(20, 22),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        strings.appTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.accent,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        strings.quote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.accent.withValues(alpha: 0.75),
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  Transform.rotate(
                    angle: 0.78,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.accent, width: 2),
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _open,
                    icon: const Icon(Icons.menu_book_rounded),
                    label: Text(strings.openBook),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
