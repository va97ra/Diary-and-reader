import 'package:dnevnik/app/literia_version.dart';
import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/literia_app_preferences.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_adaptive_control_shell.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
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
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 24),
            children: [
              BookSettingsCard(
                title: strings.appearance,
                icon: Icons.palette_outlined,
                child: BookSettingsRow(
                  children: [
                    BookCompactDropdown<LiteriaThemePreference>(
                      key: const ValueKey('app-theme'),
                      label: strings.appTheme,
                      value: themePreference,
                      items: {
                        LiteriaThemePreference.system: strings.systemTheme,
                        LiteriaThemePreference.light: strings.lightTheme,
                        LiteriaThemePreference.dark: strings.darkTheme,
                      },
                      onChanged: onThemeChanged,
                    ),
                    BookCompactDropdown<String>(
                      key: const ValueKey('app-language'),
                      label: strings.language,
                      value: languageCode,
                      items: const {'ru': 'Русский', 'en': 'English'},
                      onChanged: onLanguageChanged,
                    ),
                  ],
                ),
              ),
              BookSettingsCard(
                title: strings.data,
                icon: Icons.inventory_2_outlined,
                child: Column(
                  children: [
                    LiteriaCompactActionTile(
                      icon: Icons.download_outlined,
                      title: strings.backupProject,
                      subtitle: strings.backupProjectHint,
                      enabled: canBackup,
                      onTap: () {
                        onBackup();
                      },
                    ),
                    const SizedBox(height: 6),
                    LiteriaCompactActionTile(
                      icon: Icons.upload_file_outlined,
                      title: strings.restoreProjectBackup,
                      subtitle: strings.restoreProjectBackupHint,
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
              BookSettingsCard(
                title: strings.help,
                icon: Icons.help_outline,
                child: Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  // The guide stays folded until asked for, so the settings
                  // themselves fit on the screen.
                  child: ExpansionTile(
                    key: const ValueKey('app-help'),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 4),
                    dense: true,
                    textColor: BookLeatherColors.foreground,
                    collapsedTextColor: BookLeatherColors.foreground,
                    iconColor: BookLeatherColors.accent,
                    collapsedIconColor: BookLeatherColors.accent,
                    title: Text(strings.showGuide),
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
              ),
              BookSettingsCard(
                title: strings.about,
                icon: Icons.info_outline,
                child: Text(
                  '${strings.studioTitle} $literiaVersion',
                  key: const ValueKey('app-version'),
                  style: const TextStyle(
                    color: BookLeatherColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
