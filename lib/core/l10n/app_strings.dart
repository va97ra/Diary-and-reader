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
  String get librarySearchHint => _text('librarySearchHint');
  String get sortBy => _text('sortBy');
  String get recentlyUpdated => _text('recentlyUpdated');
  String get byTitle => _text('byTitle');
  String get byAuthor => _text('byAuthor');
  String get byProgress => _text('byProgress');
  String get allBooks => _text('allBooks');
  String get manuscripts => _text('manuscripts');
  String get importedBooks => _text('importedBooks');
  String get unreadBooks => _text('unreadBooks');
  String get readingBooks => _text('readingBooks');
  String get finishedBooks => _text('finishedBooks');
  String get allCollections => _text('allCollections');
  String get noCollection => _text('noCollection');
  String get moveToCollection => _text('moveToCollection');
  String get collectionName => _text('collectionName');
  String get collectionHint => _text('collectionHint');
  String get removeFromCollection => _text('removeFromCollection');
  String get noBooksFound => _text('noBooksFound');
  String get emptyLibrary => _text('emptyLibrary');
  String get manuscript => _text('manuscript');
  String get properties => _text('properties');
  String get newBook => _text('newBook');
  String get importEbook => _text('importEbook');
  String get importEbookHint => _text('importEbookHint');
  String get importedBook => _text('importedBook');
  String get importedBookHint => _text('importedBookHint');
  String get sourceFile => _text('sourceFile');
  String get bookImported => _text('bookImported');
  String get bookImportFailed => _text('bookImportFailed');
  String get unsupportedBookFormat => _text('unsupportedBookFormat');
  String get noReadableBookText => _text('noReadableBookText');
  String sectionsInBook(int count) => '${_text('sectionsInBook')}: $count';
  String imagesInBook(int count) => '${_text('imagesInBook')}: $count';
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
  String get focusWriting => _text('focusWriting');
  String get exitFocusWriting => _text('exitFocusWriting');
  String get a4Preview => _text('a4Preview');
  String get comfortableWriting => _text('comfortableWriting');
  String get a4PreviewHint => _text('a4PreviewHint');
  String get moreActions => _text('moreActions');
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
  String get insertImage => _text('insertImage');
  String get imageInserted => _text('imageInserted');
  String get imageInsertFailed => _text('imageInsertFailed');
  String get insertPageBreak => _text('insertPageBreak');
  String get pageBreak => _text('pageBreak');
  String get pageBreakInserted => _text('pageBreakInserted');
  String get reader => _text('reader');
  String get tableOfContents => _text('tableOfContents');
  String get readingSettings => _text('readingSettings');
  String get focusReading => _text('focusReading');
  String get exitFocusReading => _text('exitFocusReading');
  String get readerTheme => _text('readerTheme');
  String get lightTheme => _text('lightTheme');
  String get sepiaTheme => _text('sepiaTheme');
  String get darkTheme => _text('darkTheme');
  String get readerFont => _text('readerFont');
  String get readerFontSize => _text('readerFontSize');
  String get textWidth => _text('textWidth');
  String get previousSection => _text('previousSection');
  String get nextSection => _text('nextSection');
  String get readingProgress => _text('readingProgress');
  String get contentsShort => _text('contentsShort');
  String get bookmarks => _text('bookmarks');
  String get notes => _text('notes');
  String get noBookmarks => _text('noBookmarks');
  String get noNotes => _text('noNotes');
  String get bookmark => _text('bookmark');
  String get addBookmark => _text('addBookmark');
  String get removeBookmark => _text('removeBookmark');
  String get deleteBookmark => _text('deleteBookmark');
  String get addNoteHere => _text('addNoteHere');
  String get newNote => _text('newNote');
  String get editNote => _text('editNote');
  String get deleteNote => _text('deleteNote');
  String get noteText => _text('noteText');
  String get save => _text('save');
  String get searchInBook => _text('searchInBook');
  String get clearSearch => _text('clearSearch');
  String get searchHint => _text('searchHint');
  String get nothingFound => _text('nothingFound');
  String get findAndReplace => _text('findAndReplace');
  String get manuscriptSearchHint => _text('manuscriptSearchHint');
  String get replaceWith => _text('replaceWith');
  String get replaceAll => _text('replaceAll');
  String get caseSensitive => _text('caseSensitive');
  String matchesFound(int count) => '${_text('matchesFound')}: $count';
  String replacementsMade(int count) => '${_text('replacementsMade')}: $count';
  String get readerViewMode => _text('readerViewMode');
  String get continuousReading => _text('continuousReading');
  String get singlePageReading => _text('singlePageReading');
  String get spreadReading => _text('spreadReading');
  String get spreadPhoneHint => _text('spreadPhoneHint');
  String get horizontalMargins => _text('horizontalMargins');
  String get verticalMargins => _text('verticalMargins');
  String get previousReaderPage => _text('previousReaderPage');
  String get nextReaderPage => _text('nextReaderPage');
  String get highlights => _text('highlights');
  String get quotes => _text('quotes');
  String get noHighlights => _text('noHighlights');
  String get highlightActions => _text('highlightActions');
  String get yellowHighlight => _text('yellowHighlight');
  String get greenHighlight => _text('greenHighlight');
  String get blueHighlight => _text('blueHighlight');
  String get pinkHighlight => _text('pinkHighlight');
  String get saveQuote => _text('saveQuote');
  String get addNoteToSelection => _text('addNoteToSelection');
  String get copySelection => _text('copySelection');
  String get closeSelectionActions => _text('closeSelectionActions');
  String get deleteHighlight => _text('deleteHighlight');
  String get deleteQuote => _text('deleteQuote');
  String get exportAnnotations => _text('exportAnnotations');
  String get exportMarkdown => _text('exportMarkdown');
  String get exportMarkdownHint => _text('exportMarkdownHint');
  String get exportJson => _text('exportJson');
  String get exportJsonHint => _text('exportJsonHint');
  String get annotationsExported => _text('annotationsExported');
  String get annotationsExportFailed => _text('annotationsExportFailed');
  String get quoteSaved => _text('quoteSaved');
  String get highlightSaved => _text('highlightSaved');
  String get selectionCopied => _text('selectionCopied');
  String get exportBook => _text('exportBook');
  String get exportEpub => _text('exportEpub');
  String get exportEpubHint => _text('exportEpubHint');
  String get exportFb2 => _text('exportFb2');
  String get exportFb2Hint => _text('exportFb2Hint');
  String get exportFb2Zip => _text('exportFb2Zip');
  String get exportFb2ZipHint => _text('exportFb2ZipHint');
  String get exportPdf => _text('exportPdf');
  String get exportPdfHint => _text('exportPdfHint');
  String get exportDocx => _text('exportDocx');
  String get exportDocxHint => _text('exportDocxHint');
  String get exportHtml => _text('exportHtml');
  String get exportHtmlHint => _text('exportHtmlHint');
  String get exportTxt => _text('exportTxt');
  String get exportTxtHint => _text('exportTxtHint');
  String get readerExportFormats => _text('readerExportFormats');
  String get printExportFormats => _text('printExportFormats');
  String get textExportFormats => _text('textExportFormats');
  String get bookExported => _text('bookExported');
  String get bookExportFailed => _text('bookExportFailed');
  String get pdfPreview => _text('pdfPreview');
  String get savePdf => _text('savePdf');
  String get preparingPdf => _text('preparingPdf');
  String get pdfPreviewFailed => _text('pdfPreviewFailed');
  String get pdfSaved => _text('pdfSaved');
  String get retry => _text('retry');
  String get projectData => _text('projectData');
  String get versionHistory => _text('versionHistory');
  String get createVersion => _text('createVersion');
  String get versionLabel => _text('versionLabel');
  String get versionLabelHint => _text('versionLabelHint');
  String get unnamedVersion => _text('unnamedVersion');
  String get noVersions => _text('noVersions');
  String get restoreVersion => _text('restoreVersion');
  String get restoreVersionQuestion => _text('restoreVersionQuestion');
  String get versionCreated => _text('versionCreated');
  String get versionRestored => _text('versionRestored');
  String get versionOperationFailed => _text('versionOperationFailed');
  String get deleteVersion => _text('deleteVersion');
  String get deleteVersionQuestion => _text('deleteVersionQuestion');
  String get safetyVersionLabel => _text('safetyVersionLabel');
  String get backupProject => _text('backupProject');
  String get restoreProjectBackup => _text('restoreProjectBackup');
  String get projectBackupSaved => _text('projectBackupSaved');
  String get projectBackupFailed => _text('projectBackupFailed');
  String get projectRestored => _text('projectRestored');
  String get projectRestoreFailed => _text('projectRestoreFailed');
  String get confirmProjectRestore => _text('confirmProjectRestore');
  String get webVersionLimit => _text('webVersionLimit');
  String readerPageOf(int current, int count) =>
      '${_text('readerPage')} $current ${_text('ofPages')} $count';
  String sectionOf(int current, int count) =>
      '${_text('section')} $current ${_text('ofPages')} $count';

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
      'librarySearchHint': 'Название, автор, серия или коллекция',
      'sortBy': 'Сортировка',
      'recentlyUpdated': 'Недавно открытые',
      'byTitle': 'По названию',
      'byAuthor': 'По автору',
      'byProgress': 'По прогрессу',
      'allBooks': 'Все',
      'manuscripts': 'Рукописи',
      'importedBooks': 'Загруженные',
      'unreadBooks': 'Не начаты',
      'readingBooks': 'Читаю',
      'finishedBooks': 'Прочитаны',
      'allCollections': 'Все коллекции',
      'noCollection': 'Без коллекции',
      'moveToCollection': 'Добавить в коллекцию',
      'collectionName': 'Коллекция',
      'collectionHint': 'Например: Фантастика',
      'removeFromCollection': 'Убрать из коллекции',
      'noBooksFound': 'По заданным условиям книг не найдено',
      'emptyLibrary': 'Создайте рукопись или импортируйте книгу',
      'manuscript': 'Рукопись',
      'properties': 'Свойства',
      'newBook': 'Новая книга',
      'importEbook': 'Импортировать книгу для чтения',
      'importEbookHint': 'Поддерживаются EPUB, FB2 и FB2.ZIP без DRM',
      'importedBook': 'Импортированная книга',
      'importedBookHint':
          'Текст защищён от случайного редактирования. Прогресс, закладки и заметки сохраняются.',
      'sourceFile': 'Исходный файл',
      'sectionsInBook': 'Разделов',
      'imagesInBook': 'Изображений',
      'bookImported': 'Книга добавлена в библиотеку',
      'bookImportFailed': 'Не удалось прочитать книгу',
      'unsupportedBookFormat': 'Поддерживаются EPUB, FB2 и FB2.ZIP',
      'noReadableBookText':
          'В книге не найдено доступное содержимое. Возможно, файл повреждён или защищён DRM.',
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
      'focusWriting': 'Скрыть панели',
      'exitFocusWriting': 'Показать панели',
      'a4Preview': 'Предпросмотр A4',
      'comfortableWriting': 'Удобный набор',
      'a4PreviewHint':
          'Точная разметка A4: поля, переносы и страницы пересчитаны под печатный лист.',
      'moreActions': 'Другие действия',
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
      'insertImage': 'Вставить изображение',
      'imageInserted': 'Изображение добавлено в рукопись',
      'imageInsertFailed':
          'Не удалось добавить изображение. Поддерживаются PNG, JPEG, GIF и WebP до 20 МБ.',
      'insertPageBreak': 'Вставить разрыв страницы',
      'pageBreak': 'Разрыв страницы',
      'pageBreakInserted': 'Следующий текст начнётся с новой страницы',
      'reader': 'Читать книгу',
      'tableOfContents': 'Оглавление',
      'readingSettings': 'Настройки чтения',
      'focusReading': 'Скрыть панели',
      'exitFocusReading': 'Показать панели',
      'readerTheme': 'Тема',
      'lightTheme': 'Светлая',
      'sepiaTheme': 'Сепия',
      'darkTheme': 'Тёмная',
      'readerFont': 'Шрифт читалки',
      'readerFontSize': 'Размер текста',
      'textWidth': 'Ширина текста',
      'previousSection': 'Предыдущий раздел',
      'nextSection': 'Следующий раздел',
      'readingProgress': 'Прогресс чтения',
      'section': 'Раздел',
      'contentsShort': 'Главы',
      'bookmarks': 'Закладки',
      'notes': 'Заметки',
      'noBookmarks': 'Здесь появятся сохранённые места книги',
      'noNotes': 'Добавьте заметку к текущему месту чтения',
      'bookmark': 'Закладка',
      'addBookmark': 'Добавить закладку',
      'removeBookmark': 'Убрать закладку',
      'deleteBookmark': 'Удалить закладку',
      'addNoteHere': 'Заметка к этому месту',
      'newNote': 'Новая заметка',
      'editNote': 'Изменить заметку',
      'deleteNote': 'Удалить заметку',
      'noteText': 'Текст заметки',
      'save': 'Сохранить',
      'searchInBook': 'Поиск по книге',
      'clearSearch': 'Очистить поиск',
      'searchHint': 'Введите минимум два символа для поиска по всей книге',
      'nothingFound': 'Совпадений не найдено',
      'findAndReplace': 'Поиск и замена в рукописи',
      'manuscriptSearchHint': 'Введите минимум два символа',
      'replaceWith': 'Заменить на',
      'replaceAll': 'Заменить всё',
      'caseSensitive': 'Учитывать регистр',
      'matchesFound': 'Найдено совпадений',
      'replacementsMade': 'Выполнено замен',
      'readerViewMode': 'Режим чтения',
      'continuousReading': 'Лента',
      'singlePageReading': 'Страница',
      'spreadReading': 'Разворот',
      'spreadPhoneHint':
          'На узком экране разворот автоматически становится одной страницей.',
      'horizontalMargins': 'Поля слева и справа',
      'verticalMargins': 'Поля сверху и снизу',
      'previousReaderPage': 'Предыдущая страница книги',
      'nextReaderPage': 'Следующая страница книги',
      'readerPage': 'Страница',
      'highlights': 'Выделения',
      'quotes': 'Цитаты',
      'noHighlights':
          'Выделите текст в книге, чтобы сохранить его цветом или как цитату',
      'highlightActions': 'Действия с выделением',
      'yellowHighlight': 'Жёлтое выделение',
      'greenHighlight': 'Зелёное выделение',
      'blueHighlight': 'Синее выделение',
      'pinkHighlight': 'Розовое выделение',
      'saveQuote': 'Цитата',
      'addNoteToSelection': 'Заметка к выбранному тексту',
      'copySelection': 'Копировать выбранный текст',
      'closeSelectionActions': 'Закрыть действия с текстом',
      'deleteHighlight': 'Удалить выделение',
      'deleteQuote': 'Удалить цитату',
      'exportAnnotations': 'Экспорт аннотаций',
      'exportMarkdown': 'Markdown (.md)',
      'exportMarkdownHint': 'Удобно читать и открывать в текстовых редакторах',
      'exportJson': 'JSON (.json)',
      'exportJsonHint': 'Структурированная резервная копия для переноса данных',
      'annotationsExported': 'Аннотации сохранены',
      'annotationsExportFailed': 'Не удалось сохранить аннотации',
      'quoteSaved': 'Цитата сохранена',
      'highlightSaved': 'Выделение сохранено',
      'selectionCopied': 'Текст скопирован',
      'exportBook': 'Экспорт книги',
      'exportEpub': 'EPUB 3.3 (.epub)',
      'exportEpubHint':
          'Адаптивная электронная книга с оглавлением и оформлением текста',
      'exportFb2': 'FictionBook (.fb2)',
      'exportFb2Hint':
          'Формат для популярных читалок с главами и оформлением текста',
      'exportFb2Zip': 'FictionBook в архиве (.fb2.zip)',
      'exportFb2ZipHint':
          'Компактный FB2 для библиотек и устройств с поддержкой архивов',
      'exportPdf': 'Печатный PDF (.pdf)',
      'exportPdfHint':
          'Фиксированные страницы A4 с полями, оглавлением и нумерацией',
      'exportDocx': 'Документ Word (.docx)',
      'exportDocxHint':
          'Редактируемая рукопись со стилями, оглавлением и разметкой A4',
      'exportHtml': 'Веб-страница (.html)',
      'exportHtmlHint':
          'Автономная адаптивная страница с оглавлением и оформлением',
      'exportTxt': 'Обычный текст (.txt)',
      'exportTxtHint': 'Максимально совместимый текст без оформления',
      'readerExportFormats': 'Для электронных читалок',
      'printExportFormats': 'Для печати и редактирования',
      'textExportFormats': 'Открытые текстовые форматы',
      'bookExported': 'Книга сохранена',
      'bookExportFailed': 'Не удалось сохранить книгу',
      'pdfPreview': 'Предварительный просмотр PDF',
      'savePdf': 'Сохранить PDF',
      'preparingPdf': 'Подготавливаем печатные страницы…',
      'pdfPreviewFailed': 'Не удалось создать предварительный просмотр PDF',
      'pdfSaved': 'PDF сохранён',
      'retry': 'Повторить',
      'projectData': 'Данные проекта',
      'versionHistory': 'История версий',
      'createVersion': 'Создать снимок',
      'versionLabel': 'Название снимка',
      'versionLabelHint': 'Например: перед редактурой главы',
      'unnamedVersion': 'Снимок без названия',
      'noVersions':
          'Снимков пока нет. Создайте первый перед крупными правками.',
      'restoreVersion': 'Восстановить',
      'restoreVersionQuestion':
          'Текущая версия будет сохранена защитным снимком, затем рукопись заменится выбранной версией.',
      'versionCreated': 'Снимок версии создан',
      'versionRestored': 'Версия восстановлена',
      'versionOperationFailed': 'Не удалось выполнить операцию с версией',
      'deleteVersion': 'Удалить снимок',
      'deleteVersionQuestion':
          'Удалить этот снимок без возможности восстановления?',
      'safetyVersionLabel': 'Автоматически перед восстановлением',
      'backupProject': 'Сохранить резервную копию',
      'restoreProjectBackup': 'Восстановить из файла',
      'projectBackupSaved': 'Резервная копия проекта сохранена',
      'projectBackupFailed': 'Не удалось сохранить резервную копию',
      'projectRestored': 'Проект восстановлен из резервной копии',
      'projectRestoreFailed': 'Не удалось прочитать резервную копию проекта',
      'confirmProjectRestore':
          'Текущая книга будет сохранена защитным снимком и заменена данными из выбранного файла.',
      'webVersionLimit':
          'В браузере хранятся пять последних снимков каждой книги. Для долговременного хранения сохраняйте резервные копии в файл.',
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
      'librarySearchHint': 'Title, author, series, or collection',
      'sortBy': 'Sort by',
      'recentlyUpdated': 'Recently opened',
      'byTitle': 'Title',
      'byAuthor': 'Author',
      'byProgress': 'Reading progress',
      'allBooks': 'All',
      'manuscripts': 'Manuscripts',
      'importedBooks': 'Imported',
      'unreadBooks': 'Not started',
      'readingBooks': 'Reading',
      'finishedBooks': 'Finished',
      'allCollections': 'All collections',
      'noCollection': 'No collection',
      'moveToCollection': 'Add to collection',
      'collectionName': 'Collection',
      'collectionHint': 'For example: Science fiction',
      'removeFromCollection': 'Remove from collection',
      'noBooksFound': 'No books match these filters',
      'emptyLibrary': 'Create a manuscript or import a book',
      'manuscript': 'Manuscript',
      'properties': 'Properties',
      'newBook': 'New book',
      'importEbook': 'Import a book for reading',
      'importEbookHint': 'Supports DRM-free EPUB, FB2, and FB2.ZIP files',
      'importedBook': 'Imported book',
      'importedBookHint':
          'The text is protected from accidental editing. Progress, bookmarks, and notes are saved.',
      'sourceFile': 'Source file',
      'sectionsInBook': 'Sections',
      'imagesInBook': 'Images',
      'bookImported': 'Book added to the library',
      'bookImportFailed': 'The book could not be read',
      'unsupportedBookFormat': 'EPUB, FB2, and FB2.ZIP are supported',
      'noReadableBookText':
          'No readable content was found. The file may be damaged or use DRM.',
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
      'focusWriting': 'Hide panels',
      'exitFocusWriting': 'Show panels',
      'a4Preview': 'A4 preview',
      'comfortableWriting': 'Comfortable writing',
      'a4PreviewHint':
          'Exact A4 layout: margins, line wrapping, and pages use the print sheet.',
      'moreActions': 'More actions',
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
      'insertImage': 'Insert image',
      'imageInserted': 'Image added to the manuscript',
      'imageInsertFailed':
          'Could not add the image. PNG, JPEG, GIF, and WebP up to 20 MB are supported.',
      'insertPageBreak': 'Insert page break',
      'pageBreak': 'Page break',
      'pageBreakInserted': 'The following text will start on a new page',
      'reader': 'Read book',
      'tableOfContents': 'Table of contents',
      'readingSettings': 'Reading settings',
      'focusReading': 'Hide controls',
      'exitFocusReading': 'Show controls',
      'readerTheme': 'Theme',
      'lightTheme': 'Light',
      'sepiaTheme': 'Sepia',
      'darkTheme': 'Dark',
      'readerFont': 'Reader font',
      'readerFontSize': 'Text size',
      'textWidth': 'Text width',
      'previousSection': 'Previous section',
      'nextSection': 'Next section',
      'readingProgress': 'Reading progress',
      'section': 'Section',
      'contentsShort': 'Contents',
      'bookmarks': 'Bookmarks',
      'notes': 'Notes',
      'noBookmarks': 'Saved places will appear here',
      'noNotes': 'Add a note to the current reading position',
      'bookmark': 'Bookmark',
      'addBookmark': 'Add bookmark',
      'removeBookmark': 'Remove bookmark',
      'deleteBookmark': 'Delete bookmark',
      'addNoteHere': 'Note at this place',
      'newNote': 'New note',
      'editNote': 'Edit note',
      'deleteNote': 'Delete note',
      'noteText': 'Note text',
      'save': 'Save',
      'searchInBook': 'Search in book',
      'clearSearch': 'Clear search',
      'searchHint': 'Enter at least two characters to search the whole book',
      'nothingFound': 'No matches found',
      'findAndReplace': 'Find and replace in manuscript',
      'manuscriptSearchHint': 'Enter at least two characters',
      'replaceWith': 'Replace with',
      'replaceAll': 'Replace all',
      'caseSensitive': 'Match case',
      'matchesFound': 'Matches found',
      'replacementsMade': 'Replacements made',
      'readerViewMode': 'Reading mode',
      'continuousReading': 'Scroll',
      'singlePageReading': 'Page',
      'spreadReading': 'Spread',
      'spreadPhoneHint':
          'On a narrow screen, a spread automatically becomes one page.',
      'horizontalMargins': 'Left and right margins',
      'verticalMargins': 'Top and bottom margins',
      'previousReaderPage': 'Previous book page',
      'nextReaderPage': 'Next book page',
      'readerPage': 'Page',
      'highlights': 'Highlights',
      'quotes': 'Quotes',
      'noHighlights': 'Select book text to save a highlight or quote',
      'highlightActions': 'Highlight actions',
      'yellowHighlight': 'Yellow highlight',
      'greenHighlight': 'Green highlight',
      'blueHighlight': 'Blue highlight',
      'pinkHighlight': 'Pink highlight',
      'saveQuote': 'Quote',
      'addNoteToSelection': 'Note on selected text',
      'copySelection': 'Copy selected text',
      'closeSelectionActions': 'Close text actions',
      'deleteHighlight': 'Delete highlight',
      'deleteQuote': 'Delete quote',
      'exportAnnotations': 'Export annotations',
      'exportMarkdown': 'Markdown (.md)',
      'exportMarkdownHint': 'Easy to read and open in text editors',
      'exportJson': 'JSON (.json)',
      'exportJsonHint': 'Structured backup for transferring data',
      'annotationsExported': 'Annotations saved',
      'annotationsExportFailed': 'Annotations could not be saved',
      'quoteSaved': 'Quote saved',
      'highlightSaved': 'Highlight saved',
      'selectionCopied': 'Text copied',
      'exportBook': 'Export book',
      'exportEpub': 'EPUB 3.3 (.epub)',
      'exportEpubHint':
          'Reflowable ebook with a table of contents and rich text styling',
      'exportFb2': 'FictionBook (.fb2)',
      'exportFb2Hint':
          'Reader-friendly book with chapters and rich text styling',
      'exportFb2Zip': 'Archived FictionBook (.fb2.zip)',
      'exportFb2ZipHint':
          'Compact FB2 for libraries and devices that support archives',
      'exportPdf': 'Print PDF (.pdf)',
      'exportPdfHint':
          'Fixed A4 pages with margins, contents, and page numbering',
      'exportDocx': 'Word document (.docx)',
      'exportDocxHint':
          'Editable manuscript with styles, contents, and A4 page layout',
      'exportHtml': 'Web page (.html)',
      'exportHtmlHint':
          'Standalone responsive page with contents and rich text styling',
      'exportTxt': 'Plain text (.txt)',
      'exportTxtHint': 'Maximum compatibility without text styling',
      'readerExportFormats': 'For ebook readers',
      'printExportFormats': 'For print and editing',
      'textExportFormats': 'Open text formats',
      'bookExported': 'Book saved',
      'bookExportFailed': 'Book could not be saved',
      'pdfPreview': 'PDF preview',
      'savePdf': 'Save PDF',
      'preparingPdf': 'Preparing print pages…',
      'pdfPreviewFailed': 'PDF preview could not be created',
      'pdfSaved': 'PDF saved',
      'retry': 'Retry',
      'projectData': 'Project data',
      'versionHistory': 'Version history',
      'createVersion': 'Create snapshot',
      'versionLabel': 'Snapshot name',
      'versionLabelHint': 'For example: before revising the chapter',
      'unnamedVersion': 'Unnamed snapshot',
      'noVersions': 'No snapshots yet. Create one before major edits.',
      'restoreVersion': 'Restore',
      'restoreVersionQuestion':
          'The current version will be saved as a safety snapshot before the manuscript is replaced.',
      'versionCreated': 'Version snapshot created',
      'versionRestored': 'Version restored',
      'versionOperationFailed': 'The version operation could not be completed',
      'deleteVersion': 'Delete snapshot',
      'deleteVersionQuestion': 'Delete this snapshot permanently?',
      'safetyVersionLabel': 'Automatic snapshot before restore',
      'backupProject': 'Save backup copy',
      'restoreProjectBackup': 'Restore from file',
      'projectBackupSaved': 'Project backup saved',
      'projectBackupFailed': 'The backup could not be saved',
      'projectRestored': 'Project restored from backup',
      'projectRestoreFailed': 'The project backup could not be read',
      'confirmProjectRestore':
          'The current book will be saved as a safety snapshot and replaced with data from the selected file.',
      'webVersionLimit':
          'The browser keeps the five newest snapshots for each book. Save a backup file for long-term storage.',
    },
  };
}
