import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';

/// The reading settings: how the book looks, its text and margins, the
/// gestures, and reading aloud. Every choice is named rather than a number,
/// and applies to the book at once.
class BookReaderSettingsSheet extends StatefulWidget {
  const BookReaderSettingsSheet({
    required this.settings,
    required this.onChanged,
    super.key,
  });

  final BookReaderSettings settings;
  final ValueChanged<BookReaderSettings> onChanged;

  @override
  State<BookReaderSettingsSheet> createState() =>
      _BookReaderSettingsSheetState();
}

class _BookReaderSettingsSheetState extends State<BookReaderSettingsSheet> {
  static const _minFontSize = 12.0;
  static const _maxFontSize = 32.0;
  static const _lineHeights = <double>[1.2, 1.4, 1.6, 1.8, 2.0, 2.2];

  /// Text wider than a phone screen, so the choice only shows on wide ones.
  static const _widthChoicesFrom = 600.0;

  late BookReaderSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _change(BookReaderSettings settings) {
    if (settings == _settings) return;
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final mediaQuery = MediaQuery.of(context);
    final hideSpread =
        mediaQuery.orientation == Orientation.portrait &&
        mediaQuery.size.shortestSide < 600;
    final showWidth = mediaQuery.size.width >= _widthChoicesFrom;
    String pixels(double value) => '${value.round()} px';
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BookLeatherModalHeader(
              title: strings.readingSettings,
              subtitle: strings.readerSettingsHint,
              onClose: () => Navigator.maybePop(context),
              closeKey: const ValueKey('reader-settings-close'),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
            BookSettingsCard(
              title: strings.readerLook,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BookCompactChoice<BookReaderViewMode>(
                    key: const ValueKey('reader-view-mode'),
                    label: strings.readerViewMode,
                    value: _settings.viewMode,
                    options: [
                      (
                        BookReaderViewMode.continuous,
                        Icons.view_stream_outlined,
                        strings.continuousReading,
                      ),
                      (
                        BookReaderViewMode.singlePage,
                        Icons.crop_portrait_outlined,
                        strings.singlePageReading,
                      ),
                      if (!hideSpread)
                        (
                          BookReaderViewMode.spread,
                          Icons.menu_book_outlined,
                          strings.spreadReading,
                        ),
                    ],
                    onChanged: (value) =>
                        _change(_settings.copyWith(viewMode: value)),
                  ),
                  if (!hideSpread)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        strings.spreadPhoneHint,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 12),
                  BookCompactChoice<BookReaderTheme>(
                    key: const ValueKey('reader-theme'),
                    label: strings.readerTheme,
                    value: _settings.theme,
                    options: [
                      (
                        BookReaderTheme.light,
                        Icons.light_mode_outlined,
                        strings.lightTheme,
                      ),
                      (
                        BookReaderTheme.sepia,
                        Icons.coffee_outlined,
                        strings.sepiaTheme,
                      ),
                      (
                        BookReaderTheme.dark,
                        Icons.dark_mode_outlined,
                        strings.darkTheme,
                      ),
                    ],
                    onChanged: (value) =>
                        _change(_settings.copyWith(theme: value)),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.readerText,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: BookCompactDropdown<String>(
                          key: const ValueKey('reader-font-family'),
                          label: strings.readerFont,
                          value: _settings.fontFamily,
                          items: {
                            for (final family in bookReaderFontFamilies)
                              family: family,
                          },
                          itemStyle: (family) => TextStyle(fontFamily: family),
                          onChanged: (family) =>
                              _change(_settings.copyWith(fontFamily: family)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 128,
                        child: BookSettingStepper(
                          key: const ValueKey('reader-font-size'),
                          label: strings.readerFontSize,
                          value: '${_settings.fontSize.round()}',
                          decreaseTooltip: strings.smallerText,
                          increaseTooltip: strings.largerText,
                          onDecrease: _settings.fontSize > _minFontSize
                              ? () => _change(
                                  _settings.copyWith(
                                    fontSize: _settings.fontSize.round() - 1,
                                  ),
                                )
                              : null,
                          onIncrease: _settings.fontSize < _maxFontSize
                              ? () => _change(
                                  _settings.copyWith(
                                    fontSize: _settings.fontSize.round() + 1,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BookSettingsRow(
                    children: [
                      BookCompactDropdown<double>(
                        key: const ValueKey('reader-font-weight'),
                        label: strings.fontWeight,
                        value: _settings.fontWeight,
                        items: bookNamedChoices(
                          {
                            300: strings.weightLight,
                            400: strings.weightRegular,
                            500: strings.weightMedium,
                            600: strings.weightSemiBold,
                            700: strings.weightBold,
                          },
                          _settings.fontWeight,
                          (value) => '${value.round()}',
                        ),
                        onChanged: (value) =>
                            _change(_settings.copyWith(fontWeight: value)),
                      ),
                      BookCompactDropdown<double>(
                        key: const ValueKey('reader-line-height'),
                        label: strings.lineSpacing,
                        value: _settings.lineHeight,
                        items: bookNumberChoices(
                          _lineHeights,
                          _settings.lineHeight,
                          (value) => value.toStringAsFixed(1),
                        ),
                        onChanged: (value) =>
                            _change(_settings.copyWith(lineHeight: value)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  BookSettingSwitch(
                    title: strings.justifyText,
                    value: _settings.justifyText,
                    onChanged: (value) =>
                        _change(_settings.copyWith(justifyText: value)),
                  ),
                  BookSettingSwitch(
                    title: strings.hyphenateWords,
                    value: _settings.hyphenateWords,
                    onChanged: (value) =>
                        _change(_settings.copyWith(hyphenateWords: value)),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.margins,
              child: BookSettingsRow(
                children: [
                  if (showWidth)
                    BookCompactDropdown<double>(
                      key: const ValueKey('reader-text-width'),
                      label: strings.textWidth,
                      value: _settings.contentWidth,
                      items: bookNamedChoices(
                        {
                          560: strings.widthNarrow,
                          720: strings.widthMedium,
                          880: strings.widthWide,
                          1000: strings.widthFull,
                        },
                        _settings.contentWidth,
                        pixels,
                      ),
                      onChanged: (value) =>
                          _change(_settings.copyWith(contentWidth: value)),
                    ),
                  BookCompactDropdown<double>(
                    key: const ValueKey('reader-side-margins'),
                    label: strings.horizontalMargins,
                    value: _settings.horizontalPadding,
                    items: bookNamedChoices(
                      {
                        16: strings.narrow,
                        32: strings.normal,
                        56: strings.wide,
                        80: strings.extraWide,
                      },
                      _settings.horizontalPadding,
                      pixels,
                    ),
                    onChanged: (value) =>
                        _change(_settings.copyWith(horizontalPadding: value)),
                  ),
                  BookCompactDropdown<double>(
                    key: const ValueKey('reader-vertical-margins'),
                    label: strings.verticalMargins,
                    value: _settings.verticalPadding,
                    items: bookNamedChoices(
                      {
                        12: strings.narrow,
                        24: strings.normal,
                        40: strings.wide,
                        64: strings.extraWide,
                      },
                      _settings.verticalPadding,
                      pixels,
                    ),
                    onChanged: (value) =>
                        _change(_settings.copyWith(verticalPadding: value)),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.readerControls,
              child: Column(
                children: [
                  BookSettingSwitch(
                    title: strings.centerTapControls,
                    value: _settings.centerTapControls,
                    onChanged: (value) =>
                        _change(_settings.copyWith(centerTapControls: value)),
                  ),
                  BookSettingSwitch(
                    title: strings.swipeChapterNavigation,
                    value: _settings.swipeChapterNavigation,
                    onChanged: (value) => _change(
                      _settings.copyWith(swipeChapterNavigation: value),
                    ),
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.textToSpeech,
              child: BookSettingsRow(
                children: [
                  BookCompactDropdown<double>(
                    key: const ValueKey('reader-speech-rate'),
                    label: strings.speechRate,
                    value: _settings.speechRate,
                    items: bookNamedChoices(
                      {
                        0.35: strings.speechSlow,
                        0.5: strings.speechNormal,
                        0.6: strings.speechFast,
                        0.75: strings.speechFastest,
                      },
                      _settings.speechRate,
                      (value) => value.toStringAsFixed(2),
                    ),
                    onChanged: (value) =>
                        _change(_settings.copyWith(speechRate: value)),
                  ),
                  BookCompactDropdown<double>(
                    key: const ValueKey('reader-speech-pitch'),
                    label: strings.speechPitch,
                    value: _settings.speechPitch,
                    items: bookNamedChoices(
                      {
                        0.8: strings.pitchLow,
                        1: strings.pitchNormal,
                        1.2: strings.pitchHigh,
                      },
                      _settings.speechPitch,
                      (value) => value.toStringAsFixed(1),
                    ),
                    onChanged: (value) =>
                        _change(_settings.copyWith(speechPitch: value)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              key: const ValueKey('reader-settings-reset'),
              onPressed: () => _change(const BookReaderSettings()),
              icon: const Icon(Icons.restart_alt),
              label: Text(strings.resetSettings),
            ),
          ],
        ),
      ),
    );
  }
}
