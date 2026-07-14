import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this._languageCode);

  final String _languageCode;

  static const supportedLocales = [Locale('ru'), Locale('en')];

  static AppStrings of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return AppStrings._(code == 'en' ? 'en' : 'ru');
  }

  String _text(String key) => _values[_languageCode]![key]!;

  String get appTitle => _text('appTitle');
  String get quote => _text('quote');
  String get openBook => _text('openBook');
  String get entries => _text('entries');
  String get newEntry => _text('newEntry');
  String get newEntryTitle => _text('newEntryTitle');
  String get deleteEntry => _text('deleteEntry');
  String get deleteQuestion => _text('deleteQuestion');
  String get cancel => _text('cancel');
  String get formatting => _text('formatting');
  String get margins => _text('margins');
  String get startWriting => _text('startWriting');
  String get addPage => _text('addPage');
  String get page => _text('page');
  String a4Sheet(int pageNumber, int pageCount) =>
      '${_text('a4Sheet')} $pageNumber ${_text('ofPages')} $pageCount';
  String get normal => _text('normal');
  String get narrow => _text('narrow');
  String get wide => _text('wide');
  String get top => _text('top');
  String get right => _text('right');
  String get bottom => _text('bottom');
  String get left => _text('left');
  String get apply => _text('apply');
  String get language => _text('language');
  String get data => _text('data');
  String get exportData => _text('exportData');
  String get importData => _text('importData');
  String get exportSuccess => _text('exportSuccess');
  String get importSuccess => _text('importSuccess');
  String get importFailed => _text('importFailed');
  String get confirmImport => _text('confirmImport');
  String get millimeters => _text('millimeters');
  String get studioTitle => _text('studioTitle');
  String get library => _text('library');
  String get manuscript => _text('manuscript');
  String get properties => _text('properties');
  String get newBook => _text('newBook');
  String get newPart => _text('newPart');
  String get newChapter => _text('newChapter');
  String get newScene => _text('newScene');
  String get bookTitle => _text('bookTitle');
  String get author => _text('author');
  String get subtitle => _text('subtitle');
  String get description => _text('description');
  String get draftStatus => _text('draftStatus');
  String get planned => _text('planned');
  String get draft => _text('draft');
  String get revision => _text('revision');
  String get complete => _text('complete');
  String get editor => _text('editor');
  String get moveUp => _text('moveUp');
  String get moveDown => _text('moveDown');
  String get deleteSection => _text('deleteSection');
  String get deleteBook => _text('deleteBook');
  String get deleteSectionQuestion => _text('deleteSectionQuestion');
  String get deleteBookQuestion => _text('deleteBookQuestion');
  String get pageLayout => _text('pageLayout');
  String get paperFormat => _text('paperFormat');
  String get orientation => _text('orientation');
  String get portrait => _text('portrait');
  String get landscape => _text('landscape');
  String get words => _text('words');
  String get characters => _text('characters');
  String get paragraphs => _text('paragraphs');
  String get writingGoal => _text('writingGoal');
  String get writingGoalHint => _text('writingGoalHint');
  String get saved => _text('saved');
  String get saving => _text('saving');
  String get saveError => _text('saveError');
  String get paragraphStyle => _text('paragraphStyle');
  String get stylePreset => _text('stylePreset');
  String get modernStyle => _text('modernStyle');
  String get classicStyle => _text('classicStyle');
  String get manuscriptStyle => _text('manuscriptStyle');
  String get customStyle => _text('customStyle');
  String get defaultFont => _text('defaultFont');
  String get fontSize => _text('fontSize');
  String get points => _text('points');
  String get paragraphIndent => _text('paragraphIndent');
  String get lineSpacing => _text('lineSpacing');
  String get spacingBefore => _text('spacingBefore');
  String get spacingAfter => _text('spacingAfter');
  String get viewMode => _text('viewMode');
  String get continuousPages => _text('continuousPages');
  String get singlePage => _text('singlePage');
  String get twoPageSpread => _text('twoPageSpread');
  String get previousPage => _text('previousPage');
  String get nextPage => _text('nextPage');
  String get paragraphType => _text('paragraphType');
  String get bodyText => _text('bodyText');
  String get heading1 => _text('heading1');
  String get heading2 => _text('heading2');
  String get heading3 => _text('heading3');
  String get quoteStyle => _text('quoteStyle');
  String get epigraph => _text('epigraph');
  String get sceneBreak => _text('sceneBreak');

  static const _values = <String, Map<String, String>>{
    'ru': {
      'appTitle': 'Мой дневник',
      'quote': 'Путешествие в тысячу миль начинается с одного шага.',
      'openBook': 'Открыть книгу',
      'entries': 'Записи',
      'newEntry': 'Новая запись',
      'newEntryTitle': 'Заголовок записи',
      'deleteEntry': 'Удалить',
      'deleteQuestion': 'Удалить эту запись без возможности восстановления?',
      'cancel': 'Отмена',
      'formatting': 'Форматирование',
      'margins': 'Поля страницы',
      'startWriting': 'Начните писать…',
      'addPage': 'Добавить страницу',
      'page': 'Страница',
      'a4Sheet': 'Лист A4',
      'ofPages': 'из',
      'normal': 'Обычные',
      'narrow': 'Узкие',
      'wide': 'Широкие',
      'top': 'Верх',
      'right': 'Право',
      'bottom': 'Низ',
      'left': 'Лево',
      'apply': 'Применить',
      'language': 'Язык',
      'data': 'Данные',
      'exportData': 'Экспортировать',
      'importData': 'Импортировать',
      'exportSuccess': 'Резервная копия сохранена',
      'importSuccess': 'Дневник восстановлен из файла',
      'importFailed': 'Не удалось прочитать файл дневника',
      'confirmImport': 'Текущие записи будут заменены данными из файла.',
      'millimeters': 'мм',
      'studioTitle': 'Авторская студия',
      'library': 'Библиотека',
      'manuscript': 'Рукопись',
      'properties': 'Свойства',
      'newBook': 'Новая книга',
      'newPart': 'Новая часть',
      'newChapter': 'Новая глава',
      'newScene': 'Новая сцена',
      'bookTitle': 'Название книги',
      'author': 'Автор',
      'subtitle': 'Подзаголовок',
      'description': 'Аннотация',
      'draftStatus': 'Статус текста',
      'planned': 'Запланировано',
      'draft': 'Черновик',
      'revision': 'Редактура',
      'complete': 'Готово',
      'editor': 'Редактор',
      'moveUp': 'Переместить выше',
      'moveDown': 'Переместить ниже',
      'deleteSection': 'Удалить раздел',
      'deleteBook': 'Удалить книгу',
      'deleteSectionQuestion':
          'Раздел и все его вложенные сцены будут удалены.',
      'deleteBookQuestion': 'Книга и все её главы будут удалены.',
      'pageLayout': 'Макет страницы',
      'paperFormat': 'Формат бумаги',
      'orientation': 'Ориентация',
      'portrait': 'Книжная',
      'landscape': 'Альбомная',
      'words': 'Слов',
      'characters': 'Знаков',
      'paragraphs': 'Абзацев',
      'writingGoal': 'Цель раздела, слов',
      'writingGoalHint': 'Оставьте пустым, если цель не нужна',
      'saved': 'Сохранено',
      'saving': 'Сохранение…',
      'saveError': 'Не сохранено',
      'paragraphStyle': 'Стиль основного текста',
      'stylePreset': 'Готовый стиль',
      'modernStyle': 'Современный',
      'classicStyle': 'Классическая книга',
      'manuscriptStyle': 'Рукопись для редактора',
      'customStyle': 'Пользовательский',
      'defaultFont': 'Основной шрифт',
      'fontSize': 'Размер',
      'points': 'пт',
      'paragraphIndent': 'Отступ абзаца',
      'lineSpacing': 'Межстрочный интервал',
      'spacingBefore': 'Перед абзацем',
      'spacingAfter': 'После абзаца',
      'viewMode': 'Режим просмотра',
      'continuousPages': 'Лента страниц',
      'singlePage': 'Одна страница',
      'twoPageSpread': 'Разворот',
      'previousPage': 'Предыдущая страница',
      'nextPage': 'Следующая страница',
      'paragraphType': 'Стиль абзаца',
      'bodyText': 'Основной текст',
      'heading1': 'Заголовок 1',
      'heading2': 'Заголовок 2',
      'heading3': 'Заголовок 3',
      'quoteStyle': 'Цитата',
      'epigraph': 'Эпиграф',
      'sceneBreak': 'Разделитель сцены',
    },
    'en': {
      'appTitle': 'My diary',
      'quote': 'A journey of a thousand miles begins with a single step.',
      'openBook': 'Open book',
      'entries': 'Entries',
      'newEntry': 'New entry',
      'newEntryTitle': 'Entry title',
      'deleteEntry': 'Delete',
      'deleteQuestion': 'Delete this entry permanently?',
      'cancel': 'Cancel',
      'formatting': 'Formatting',
      'margins': 'Page margins',
      'startWriting': 'Start writing…',
      'addPage': 'Add page',
      'page': 'Page',
      'a4Sheet': 'A4 sheet',
      'ofPages': 'of',
      'normal': 'Normal',
      'narrow': 'Narrow',
      'wide': 'Wide',
      'top': 'Top',
      'right': 'Right',
      'bottom': 'Bottom',
      'left': 'Left',
      'apply': 'Apply',
      'language': 'Language',
      'data': 'Data',
      'exportData': 'Export',
      'importData': 'Import',
      'exportSuccess': 'Backup file saved',
      'importSuccess': 'Diary restored from file',
      'importFailed': 'The diary file could not be read',
      'confirmImport': 'Current entries will be replaced by the imported file.',
      'millimeters': 'mm',
      'studioTitle': 'Author studio',
      'library': 'Library',
      'manuscript': 'Manuscript',
      'properties': 'Properties',
      'newBook': 'New book',
      'newPart': 'New part',
      'newChapter': 'New chapter',
      'newScene': 'New scene',
      'bookTitle': 'Book title',
      'author': 'Author',
      'subtitle': 'Subtitle',
      'description': 'Description',
      'draftStatus': 'Draft status',
      'planned': 'Planned',
      'draft': 'Draft',
      'revision': 'Revision',
      'complete': 'Complete',
      'editor': 'Editor',
      'moveUp': 'Move up',
      'moveDown': 'Move down',
      'deleteSection': 'Delete section',
      'deleteBook': 'Delete book',
      'deleteSectionQuestion':
          'The section and all of its nested scenes will be deleted.',
      'deleteBookQuestion': 'The book and all of its chapters will be deleted.',
      'pageLayout': 'Page layout',
      'paperFormat': 'Paper size',
      'orientation': 'Orientation',
      'portrait': 'Portrait',
      'landscape': 'Landscape',
      'words': 'Words',
      'characters': 'Characters',
      'paragraphs': 'Paragraphs',
      'writingGoal': 'Section goal, words',
      'writingGoalHint': 'Leave empty if no goal is needed',
      'saved': 'Saved',
      'saving': 'Saving…',
      'saveError': 'Not saved',
      'paragraphStyle': 'Body text style',
      'stylePreset': 'Style preset',
      'modernStyle': 'Modern',
      'classicStyle': 'Classic book',
      'manuscriptStyle': 'Editor manuscript',
      'customStyle': 'Custom',
      'defaultFont': 'Default font',
      'fontSize': 'Size',
      'points': 'pt',
      'paragraphIndent': 'Paragraph indent',
      'lineSpacing': 'Line spacing',
      'spacingBefore': 'Before paragraph',
      'spacingAfter': 'After paragraph',
      'viewMode': 'View mode',
      'continuousPages': 'Continuous pages',
      'singlePage': 'Single page',
      'twoPageSpread': 'Two-page spread',
      'previousPage': 'Previous page',
      'nextPage': 'Next page',
      'paragraphType': 'Paragraph style',
      'bodyText': 'Body text',
      'heading1': 'Heading 1',
      'heading2': 'Heading 2',
      'heading3': 'Heading 3',
      'quoteStyle': 'Quote',
      'epigraph': 'Epigraph',
      'sceneBreak': 'Scene break',
    },
  };
}
