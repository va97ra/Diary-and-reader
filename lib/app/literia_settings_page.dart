import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
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
    required this.onShowOnboarding,
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
  final VoidCallback onShowOnboarding;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SettingsCard(
            title: strings.appearance,
            icon: Icons.palette_outlined,
            child: DropdownButtonFormField<LiteriaThemePreference>(
              initialValue: themePreference,
              isExpanded: true,
              decoration: const InputDecoration(border: OutlineInputBorder()),
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
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'ru', label: Text('Русский')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {languageCode},
              onSelectionChanged: (selection) =>
                  onLanguageChanged(selection.first),
            ),
          ),
          _SettingsCard(
            title: strings.data,
            icon: Icons.inventory_2_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: canBackup ? onBackup : null,
                  icon: const Icon(Icons.download_outlined),
                  label: Text(strings.backupProject),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRestore,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(strings.restoreProjectBackup),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  key: const ValueKey('open-book-storage'),
                  onPressed: onOpenBookStorage,
                  icon: const Icon(Icons.storage_outlined),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(strings.bookStorage),
                      Text(
                        strings.bookStorageSubtitle,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
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
                  '${strings.writeSubtitle}\n${strings.readSubtitle}\n${strings.supportedBookFormats}',
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: onShowOnboarding,
                  icon: const Icon(Icons.school_outlined),
                  label: Text(strings.onboarding),
                ),
              ],
            ),
          ),
          _SettingsCard(
            title: strings.about,
            icon: Icons.info_outline,
            child: const Text('Литерия 1.0.2'),
          ),
        ],
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
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
