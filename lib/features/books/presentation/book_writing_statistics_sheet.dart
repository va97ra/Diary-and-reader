import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/manuscript_project_statistics.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_leather_modal.dart';
import 'package:dnevnik/features/books/presentation/widgets/book_settings_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// How much has been written, the details of the book, and the goals, which
/// are kept as soon as they are typed.
class BookWritingStatisticsSheet extends StatefulWidget {
  const BookWritingStatisticsSheet({required this.controller, super.key});

  final AuthorWorkspaceController controller;

  @override
  State<BookWritingStatisticsSheet> createState() =>
      _BookWritingStatisticsSheetState();
}

class _BookWritingStatisticsSheetState
    extends State<BookWritingStatisticsSheet> {
  late final TextEditingController _dailyGoal;
  late final TextEditingController _projectGoal;

  @override
  void initState() {
    super.initState();
    final state = widget.controller.activeProject!.writingState;
    _dailyGoal = TextEditingController(
      text: state.dailyTargetWords == 0 ? '' : '${state.dailyTargetWords}',
    );
    _projectGoal = TextEditingController(
      text: state.projectTargetWords == 0 ? '' : '${state.projectTargetWords}',
    );
  }

  @override
  void dispose() {
    _dailyGoal.dispose();
    _projectGoal.dispose();
    super.dispose();
  }

  void _saveGoals() {
    widget.controller.updateWritingGoals(
      dailyTargetWords: int.tryParse(_dailyGoal.text) ?? 0,
      projectTargetWords: int.tryParse(_projectGoal.text) ?? 0,
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject!;
    final statistics = ManuscriptProjectStatistics.fromProject(project);
    final writing = project.writingState;
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    String duration(int seconds) {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      final inMinutes = '$minutes ${strings.minutesShort}';
      return hours > 0 ? '$hours ${strings.hoursShort} $inMinutes' : inMinutes;
    }

    TextField goal(String key, String label, TextEditingController field) =>
        TextField(
          key: ValueKey(key),
          controller: field,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: InputDecoration(
            labelText: label,
            suffixText: strings.words.toLowerCase(),
            isDense: true,
            border: const OutlineInputBorder(),
          ),
          onChanged: (_) => _saveGoals(),
        );

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: ListView(
          key: const ValueKey('writing-statistics-sheet'),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
          children: [
            BookLeatherModalHeader(
              title: strings.writingStatistics,
              onClose: () => Navigator.pop(context),
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            ),
            BookSettingsCard(
              title: strings.wordsWritten,
              child: BookSettingsRow(
                children: [
                  _Progress(
                    title: strings.today,
                    value: writing.wordsForDay(DateTime.now()),
                    target: writing.dailyTargetWords,
                    number: number,
                  ),
                  _Progress(
                    title: strings.wholeBook,
                    value: statistics.words,
                    target: writing.projectTargetWords,
                    number: number,
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.statisticsDetails,
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.9,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                children: [
                  _Metric(strings.words, number.format(statistics.words)),
                  _Metric(
                    strings.characters,
                    number.format(statistics.characters),
                  ),
                  _Metric(
                    strings.paragraphs,
                    number.format(statistics.paragraphs),
                  ),
                  _Metric(
                    strings.writingTime,
                    duration(writing.totalWritingTimeSeconds),
                  ),
                  _Metric(strings.activeDays, '${writing.activeDays}'),
                  _Metric(
                    strings.writingStreak,
                    '${writing.streakAt(DateTime.now())}',
                  ),
                ],
              ),
            ),
            BookSettingsCard(
              title: strings.goals,
              hint: strings.goalsHint,
              child: BookSettingsRow(
                children: [
                  goal(
                    'daily-writing-goal',
                    strings.dailyWritingGoal,
                    _dailyGoal,
                  ),
                  goal(
                    'project-writing-goal',
                    strings.projectWritingGoal,
                    _projectGoal,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Words written so far and, when there is a goal, the way to it.
class _Progress extends StatelessWidget {
  const _Progress({
    required this.title,
    required this.value,
    required this.target,
    required this.number,
  });

  final String title;
  final int value;
  final int target;
  final NumberFormat number;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.labelMedium),
        Text(
          target > 0
              ? '${number.format(value)} / ${number.format(target)}'
              : number.format(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: target <= 0 ? 0 : (value / target).clamp(0, 1).toDouble(),
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}
