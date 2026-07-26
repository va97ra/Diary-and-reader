import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:flutter/material.dart';

class LiteriaSettingsPage extends StatelessWidget {
  const LiteriaSettingsPage({
    required this.themePreference,
    required this.languageCode,
    required this.canBackup,
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.onBackup,
    required this.onRestore,
    required this.onOpenBookStorage,
    super.key,
  });

  final LiteriaThemePreference themePreference;
  final String languageCode;
  final bool canBackup;
  final ValueChanged<LiteriaThemePreference> onThemeChanged;
  final ValueChanged<String> onLanguageChanged;
  final Future<void> Function() onBackup;
  final Future<void> Function() onRestore;
  final VoidCallback onOpenBookStorage;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      backgroundColor: BookLeatherColors.backgroundDark,
      appBar: LiteriaLeatherAppBar(title: Text(strings.settings)),
      body: BookLeatherPanel(
        safeArea: const EdgeInsets.only(left: 1, right: 1, bottom: 1),
        child: Theme(
          data: bookLeatherModalTheme(context),
          child: ListView(
            key: const ValueKey('literia-settings-list'),
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 24),
            children: [
              _SettingsCard(
                title: strings.appearance,
                icon: Icons.palette_outlined,
                child: DropdownButtonFormField<LiteriaThemePreference>(
                  initialValue: themePreference,
                  isExpanded: true,
                  decoration: const InputDecoration(),
                  items: [
                    DropdownMenuItem(
                      value: LiteriaThemePreference.system,
                      child: Text(strings.systemTheme),
                    ),
                    DropdownMenuItem(
                      value: LiteriaThemePreference.light,
                      child: Text(strings.lightTheme),
                    ),
                    DropdownMenuItem(
                      value: LiteriaThemePreference.dark,
                      child: Text(strings.darkTheme),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) onThemeChanged(value);
                  },
                ),
              ),
              _SettingsCard(
                title: strings.language,
                icon: Icons.language,
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'ru', label: Text('Русский')),
                      ButtonSegment(value: 'en', label: Text('English')),
                    ],
                    selected: {languageCode},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) =>
                        onLanguageChanged(selection.first),
                  ),
                ),
              ),
              _SettingsCard(
                title: strings.data,
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    LiteriaCompactActionTile(
                      icon: Icons.download_outlined,
                      title: strings.backupProject,
                      enabled: canBackup,
                      onTap: () {
                        onBackup();
                      },
                    ),
                    const SizedBox(height: 6),
                    LiteriaCompactActionTile(
                      icon: Icons.upload_file_outlined,
                      title: strings.restoreProjectBackup,
                      onTap: () {
                        onRestore();
                      },
                    ),
                    const SizedBox(height: 6),
                    LiteriaCompactActionTile(
                      key: const ValueKey('open-book-storage'),
                      icon: Icons.storage_outlined,
                      title: strings.bookStorage,
                      subtitle: strings.bookStorageSubtitle,
                      onTap: onOpenBookStorage,
                    ),
                  ],
                ),
              ),
              _SettingsCard(
                title: strings.help,
                icon: Icons.help_outline,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${strings.quickStartBody}\n'
                      '${strings.supportedBookFormats}',
                      style: const TextStyle(
                        color: BookLeatherColors.mutedForeground,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              _SettingsCard(
                title: strings.about,
                icon: Icons.info_outline,
                child: const Text(
                  'Литерия 1.0.2',
                  style: TextStyle(color: BookLeatherColors.mutedForeground),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: const Color(0x52160B07),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: BookLeatherColors.stitch.withValues(alpha: 0.38),
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 19, color: BookLeatherColors.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: BookLeatherColors.foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    ),
  );
}
