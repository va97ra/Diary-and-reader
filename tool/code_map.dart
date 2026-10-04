// Writes docs/CODE_SYMBOLS.md: every type, method, getter, top-level
// function and constant of lib/, with its line and the first sentence of its
// doc comment, and every test of test/ with its line.
//
// Run from the project root after a change: dart run tool/code_map.dart
import 'dart:io';

const _output = 'docs/CODE_SYMBOLS.md';

/// Members every class has; listing them would only hide the useful ones.
const _boilerplate = {
  'build',
  'copyWith',
  'createState',
  'didChangeDependencies',
  'didUpdateWidget',
  'dispose',
  'hashCode',
  'initState',
  'toJson',
  'toString',
};

const _keywords = {
  'Function',
  'assert',
  'catch',
  'else',
  'for',
  'if',
  'return',
  'super',
  'switch',
  'this',
  'while',
};

final _type = RegExp(
  r'^(?:(?:abstract|base|final|interface|sealed|mixin)\s+)*'
  r'(class|enum|mixin|extension|typedef)\s+([A-Za-z_]\w*)',
);
// Members stand exactly two spaces in, top-level code at the margin; deeper
// lines are bodies and arguments.
final _member = RegExp(
  r'^  (?! )(?:(?:static|external|factory|abstract)\s+)*'
  r'(?:[\w$<>?,\[\]\s.]+?\s+)?(get\s+)?([A-Za-z_]\w*)(?:<[^>]*>)?\s*(\(|=>|\{)',
);
final _topFunction = RegExp(
  r'^(?! )(?:[\w$<>?,\[\]\s.]+?\s+)?(get\s+)?([A-Za-z_]\w*)(?:<[^>]*>)?\s*'
  r'(\(|=>)',
);
final _topValue = RegExp(r'^(?:const|final)\s+(?:[\w<>?,\s]+\s+)?(\w+)\s*=');
final _test = RegExp(r'''^\s*(testWidgets|test|group)\(\s*['"](.+?)['"]''');

void main() {
  final out = StringBuffer()
    ..writeln('# Указатель кода «Литерии»')
    ..writeln()
    ..writeln(
      'Генерируется скриптом, руками не править: '
      '`dart run tool/code_map.dart`.',
    )
    ..writeln(
      'Число перед именем — строка в файле; после тире — первая фраза '
      'doc-комментария. Как всё связано — в `docs/CODE_MAP.md`.',
    )
    ..writeln()
    ..writeln('## lib/')
    ..writeln();
  for (final file in _dartFiles('lib')) {
    _writeSymbols(file, out);
  }
  out
    ..writeln('## test/ — какой тест что проверяет')
    ..writeln();
  for (final file in [
    ..._dartFiles('test'),
    ..._dartFiles('integration_test'),
  ]) {
    _writeTests(file, out);
  }
  File(_output).writeAsStringSync(out.toString());
  stdout.writeln('Wrote $_output');
}

List<File> _dartFiles(String root) {
  final directory = Directory(root);
  if (!directory.existsSync()) return const [];
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => _path(a).compareTo(_path(b)));
}

String _path(File file) => file.path.replaceAll(r'\', '/');

void _writeSymbols(File file, StringBuffer out) {
  final lines = file.readAsLinesSync();
  out.writeln('### ${_path(file)} (${lines.length})');
  var inString = false;
  String? currentType;
  for (var index = 0; index < lines.length; index++) {
    final line = lines[index];
    final quotes =
        "'''".allMatches(line).length + '"""'.allMatches(line).length;
    final startsInString = inString;
    if (quotes.isOdd) inString = !inString;
    if (startsInString || line.trimLeft().startsWith('//')) continue;

    final type = _type.firstMatch(line);
    if (type != null) {
      currentType = type.group(2);
      out.writeln(
        '- ${index + 1} ${type.group(1)} **${type.group(2)}**'
        '${_doc(lines, index)}',
      );
      continue;
    }
    if (line.startsWith('}')) {
      currentType = null;
      continue;
    }
    if (currentType != null) {
      final member = _member.firstMatch(line);
      final name = member?.group(2);
      if (member == null ||
          _keywords.contains(name) ||
          _boilerplate.contains(name) ||
          line.contains(' = ') && !line.contains('=>')) {
        continue;
      }
      final constructor = name == currentType;
      if (constructor && !line.contains('factory')) continue;
      final kind = member.group(1) != null ? 'get ' : '';
      out.writeln('  - ${index + 1} $kind$name${_doc(lines, index)}');
      continue;
    }
    if (line.startsWith(' ') || line.startsWith(RegExp(r'[@}\])]'))) {
      continue;
    }
    if (RegExp(r'^(import|export|part|library) ').hasMatch(line)) continue;
    final value = _topValue.firstMatch(line);
    if (value != null) {
      out.writeln(
        '- ${index + 1} const ${value.group(1)}${_doc(lines, index)}',
      );
      continue;
    }
    final function = _topFunction.firstMatch(line);
    if (function != null && !_keywords.contains(function.group(2))) {
      final kind = function.group(1) != null ? 'get' : 'fn';
      out.writeln(
        '- ${index + 1} $kind ${function.group(2)}${_doc(lines, index)}',
      );
    }
  }
  out.writeln();
}

/// The first sentence of the doc comment above [index], after a dash.
String _doc(List<String> lines, int index) {
  var start = index - 1;
  while (start >= 0 && lines[start].trimLeft().startsWith('@')) {
    start--;
  }
  final doc = <String>[];
  while (start >= 0 && lines[start].trimLeft().startsWith('///')) {
    doc.insert(0, lines[start].trimLeft().substring(3).trim());
    start--;
  }
  if (doc.isEmpty) return '';
  var text = doc.join(' ');
  final end = text.indexOf(RegExp(r'\.(\s|$)'));
  if (end > 0) text = text.substring(0, end + 1);
  if (text.length > 140) text = '${text.substring(0, 137)}...';
  return ' — $text';
}

void _writeTests(File file, StringBuffer out) {
  final lines = file.readAsLinesSync();
  final tests = <String>[];
  for (var index = 0; index < lines.length; index++) {
    final test = _test.firstMatch(lines[index]);
    if (test == null) continue;
    final marker = test.group(1) == 'group'
        ? '**${test.group(2)}**'
        : test.group(2);
    tests.add('- ${index + 1} $marker');
  }
  if (tests.isEmpty) return;
  out
    ..writeln('### ${_path(file)}')
    ..writeAll(tests, '\n')
    ..writeln()
    ..writeln();
}
