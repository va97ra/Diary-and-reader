import 'package:dnevnik/core/l10n/app_strings.dart';
import 'package:dnevnik/features/books/application/author_workspace_controller.dart';
import 'package:dnevnik/features/books/domain/manuscript_project_statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final project = widget.controller.activeProject!;
    final statistics = ManuscriptProjectStatistics.fromProject(project);
    final writing = project.writingState;
    final todayWords = writing.wordsForDay(DateTime.now());
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    );
    return Material(
      child: SafeArea(
        child: ListView(
          key: const ValueKey('writing-statistics-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.writingStatistics,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProgressCard(
              title: strings.today,
              value: todayWords,
              target: writing.dailyTargetWords,
              number: number,
            ),
            const SizedBox(height: 12),
            _ProgressCard(
              title: strings.wholeBook,
              value: statistics.words,
              target: writing.projectTargetWords,
              number: number,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _Metric(
                  label: strings.words,
                  value: number.format(statistics.words),
                ),
                _Metric(
                  label: strings.characters,
                  value: number.format(statistics.characters),
                ),
                _Metric(
                  label: strings.paragraphs,
                  value: number.format(statistics.paragraphs),
                ),
                _Metric(
                  label: strings.writingTime,
                  value: _duration(writing.totalWritingTimeSeconds),
                ),
                _Metric(
                  label: strings.activeDays,
                  value: '${writing.activeDays}',
                ),
                _Metric(
                  label: strings.writingStreak,
                  value: '${writing.streakAt(DateTime.now())}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(strings.goals, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('daily-writing-goal'),
              controller: _dailyGoal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: strings.dailyWritingGoal,
                suffixText: strings.words.toLowerCase(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('project-writing-goal'),
              controller: _projectGoal,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: strings.projectWritingGoal,
                suffixText: strings.words.toLowerCase(),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              key: const ValueKey('save-writing-goals'),
              onPressed: () {
                widget.controller.updateWritingGoals(
                  dailyTargetWords: int.tryParse(_dailyGoal.text) ?? 0,
                  projectTargetWords: int.tryParse(_projectGoal.text) ?? 0,
                );
                setState(() {});
              },
              icon: const Icon(Icons.check),
              label: Text(strings.saveGoals),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
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
    final progress = target <= 0
        ? 0.0
        : (value / target).clamp(0, 1).toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              target > 0
                  ? '${number.format(value)} / ${number.format(target)}'
                  : number.format(value),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (target > 0) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(value: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

String _duration(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  if (hours > 0) return '$hours ч $minutes мин';
  return '$minutes мин';
}
