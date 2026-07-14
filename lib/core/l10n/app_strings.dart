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
    },
  };
}
