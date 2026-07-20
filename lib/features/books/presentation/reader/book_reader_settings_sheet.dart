import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:flutter/material.dart';

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
  late BookReaderSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
  }

  void _change(BookReaderSettings settings) {
    setState(() => _settings = settings);
    widget.onChanged(settings);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.readingSettings,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(strings.readerViewMode),
            const SizedBox(height: 8),
            _ReaderChoiceWrap<BookReaderViewMode>(
              value: _settings.viewMode,
              choices: [
                (BookReaderViewMode.continuous, strings.continuousReading),
                (BookReaderViewMode.singlePage, strings.singlePageReading),
                (BookReaderViewMode.spread, strings.spreadReading),
              ],
              onChanged: (value) =>
                  _change(_settings.copyWith(viewMode: value)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                strings.spreadPhoneHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: 22),
            Text(strings.readerTheme),
            const SizedBox(height: 8),
            _ReaderChoiceWrap<BookReaderTheme>(
              value: _settings.theme,
              choices: [
                (BookReaderTheme.light, strings.lightTheme),
                (BookReaderTheme.sepia, strings.sepiaTheme),
                (BookReaderTheme.dark, strings.darkTheme),
              ],
              onChanged: (value) => _change(_settings.copyWith(theme: value)),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              initialValue: _settings.fontFamily,
              decoration: InputDecoration(labelText: strings.readerFont),
              items: [
                for (final family in bookReaderFontFamilies)
                  DropdownMenuItem(
                    value: family,
                    child: Text(family, style: TextStyle(fontFamily: family)),
                  ),
              ],
              onChanged: (family) {
                if (family != null) {
                  _change(_settings.copyWith(fontFamily: family));
                }
              },
            ),
            const SizedBox(height: 18),
            _ReaderSlider(
              label: strings.readerFontSize,
              value: _settings.fontSize,
              min: 12,
              max: 32,
              divisions: 20,
              displayValue: '${_settings.fontSize.round()}',
              onChanged: (value) =>
                  _change(_settings.copyWith(fontSize: value)),
            ),
            _ReaderSlider(
              label: strings.lineSpacing,
              value: _settings.lineHeight,
              min: 1.2,
              max: 2.2,
              divisions: 10,
              displayValue: _settings.lineHeight.toStringAsFixed(1),
              onChanged: (value) =>
                  _change(_settings.copyWith(lineHeight: value)),
            ),
            _ReaderSlider(
              label: strings.textWidth,
              value: _settings.contentWidth,
              min: 480,
              max: 1000,
              divisions: 13,
              displayValue: '${_settings.contentWidth.round()} px',
              onChanged: (value) =>
                  _change(_settings.copyWith(contentWidth: value)),
            ),
            _ReaderSlider(
              label: strings.horizontalMargins,
              value: _settings.horizontalPadding,
              min: 16,
              max: 96,
              divisions: 10,
              displayValue: '${_settings.horizontalPadding.round()} px',
              onChanged: (value) =>
                  _change(_settings.copyWith(horizontalPadding: value)),
            ),
            _ReaderSlider(
              label: strings.verticalMargins,
              value: _settings.verticalPadding,
              min: 12,
              max: 80,
              divisions: 17,
              displayValue: '${_settings.verticalPadding.round()} px',
              onChanged: (value) =>
                  _change(_settings.copyWith(verticalPadding: value)),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _change(const BookReaderSettings()),
                icon: const Icon(Icons.restart_alt),
                label: Text(strings.resetSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderChoiceWrap<T> extends StatelessWidget {
  const _ReaderChoiceWrap({
    required this.value,
    required this.choices,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> choices;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final choice in choices)
        ChoiceChip(
          label: Text(choice.$2),
          selected: choice.$1 == value,
          onSelected: (_) => onChanged(choice.$1),
        ),
    ],
  );
}

class _ReaderSlider extends StatelessWidget {
  const _ReaderSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: Text(label)),
          Text(displayValue, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
      Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: displayValue,
        onChanged: onChanged,
      ),
    ],
  );
}
