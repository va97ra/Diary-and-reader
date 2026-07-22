import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:dnevnik/features/books/application/book_pagination_measurement.dart';
import 'package:dnevnik/features/books/application/book_reader_hyphenation.dart';
import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_continuous_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_highlight_style.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page_card.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page_stage.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_selection_resolver.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

part 'book_reader_section_continuous.dart';
part 'book_reader_section_document.dart';
part 'book_reader_section_pagination.dart';

class BookReaderSectionView extends StatefulWidget {
  const BookReaderSectionView({
    required this.section,
    required this.languageCode,
    required this.assets,
    required this.settings,
    required this.palette,
    required this.initialProgress,
    required this.onProgressChanged,
    required this.highlights,
    required this.onTextSelection,
    required this.clearSelectionVersion,
    this.onNextSectionRequested,
    this.onPreviousSectionRequested,
    super.key,
  });

  final BookSection section;
  final String languageCode;
  final List<BookAsset> assets;
  final BookReaderSettings settings;
  final BookReaderPalette palette;
  final double initialProgress;
  final ValueChanged<double> onProgressChanged;
  final List<BookReaderHighlight> highlights;
  final ValueChanged<BookReaderTextSelection?> onTextSelection;
  final int clearSelectionVersion;
  final VoidCallback? onNextSectionRequested;
  final VoidCallback? onPreviousSectionRequested;

  @override
  State<BookReaderSectionView> createState() => _BookReaderSectionViewState();
}

class _BookReaderSectionViewState extends State<BookReaderSectionView> {
  late QuillController _continuousController;
  late FocusNode _continuousFocusNode;
  late ScrollController _continuousScrollController;

  final _pageControllers = <QuillController>[];
  final _pageFocusNodes = <FocusNode>[];
  final _pageScrollControllers = <ScrollController>[];
  final _pageEditorKeys = <GlobalKey<EditorState>>[];
  final _pageViewportKeys = <GlobalKey>[];
  List<RichDocument> _pageDocuments = const [];
  List<int> _pageStartOffsets = const [];
  List<int> _pageDisplayStartOffsets = const [];
  late BookReaderDisplayDocument _displayDocument;
  int _hyphenationRequest = 0;

  Timer? _progressTimer;
  Timer? _paginationTimer;
  double _progress = 0;
  double _pendingProgress = 0;
  int _activePage = 0;
  int _paginationRequest = 0;
  final _paginationMeasurement = BookPaginationMeasurement(maxRetries: 8);
  bool _isPaginating = false;
  int? _continuousPointer;
  double? _continuousPointerStartY;
  bool _continuousPointerStartedAtStart = false;
  bool _continuousPointerStartedAtEnd = false;
  _ReaderPageGeometry? _geometry;
  _ReaderPageGeometry? _completedGeometry;
  BookReaderViewMode _effectiveMode = BookReaderViewMode.continuous;

  RichDocument? _measurementDocument;
  QuillController? _measurementController;
  FocusNode? _measurementFocusNode;
  ScrollController? _measurementScrollController;
  GlobalKey<EditorState>? _measurementEditorKey;
  GlobalKey? _measurementViewportKey;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress.clamp(0, 1).toDouble();
    _pendingProgress = _progress;
    _displayDocument = BookReaderHyphenation.identity(widget.section.content);
    _createContinuousResources();
    _scheduleHyphenation();
    _restoreContinuousPosition();
  }

  void _createContinuousResources() {
    _continuousController = QuillController(
      document: _readerDocument(_displayDocument.document, displayStart: 0),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: true,
      onSelectionChanged: (selection) =>
          _handleTextSelection(selection, displayStart: 0),
    );
    _continuousFocusNode = FocusNode();
    _continuousScrollController = ScrollController()
      ..addListener(_handleContinuousScroll);
  }

  @override
  void didUpdateWidget(covariant BookReaderSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sectionChanged =
        oldWidget.section.id != widget.section.id ||
        jsonEncode(oldWidget.section.content) !=
            jsonEncode(widget.section.content);
    final highlightsChanged =
        jsonEncode(
          oldWidget.highlights.map((item) => item.toJson()).toList(),
        ) !=
        jsonEncode(widget.highlights.map((item) => item.toJson()).toList());
    final hyphenationChanged =
        oldWidget.settings.hyphenateWords != widget.settings.hyphenateWords ||
        oldWidget.languageCode != widget.languageCode;
    if (sectionChanged || hyphenationChanged) {
      _displayDocument = BookReaderHyphenation.identity(widget.section.content);
      _scheduleHyphenation();
      _replaceContinuousResources();
      _clearVisiblePages();
      _invalidatePagination();
    } else if (highlightsChanged ||
        oldWidget.settings.theme != widget.settings.theme) {
      _replaceContinuousResources();
      _replaceVisiblePagesForHighlights();
    } else if (_layoutSettingsChanged(oldWidget.settings, widget.settings)) {
      _invalidatePagination();
    }

    if (oldWidget.clearSelectionVersion != widget.clearSelectionVersion) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _clearSelection());
    }

    if ((widget.initialProgress - _progress).abs() > 0.004 || sectionChanged) {
      _progress = widget.initialProgress.clamp(0, 1).toDouble();
      _pendingProgress = _progress;
      _restoreCurrentPosition();
    } else if (oldWidget.settings != widget.settings) {
      _restoreCurrentPosition();
    }
  }

  void _scheduleHyphenation() {
    final request = ++_hyphenationRequest;
    if (!widget.settings.hyphenateWords) return;
    final sectionId = widget.section.id;
    final languageCode = widget.languageCode;
    unawaited(() async {
      final hyphenation = await BookReaderHyphenation.forLanguage(languageCode);
      if (!mounted ||
          request != _hyphenationRequest ||
          !widget.settings.hyphenateWords ||
          widget.section.id != sectionId ||
          widget.languageCode != languageCode) {
        return;
      }
      _displayDocument = hyphenation.apply(widget.section.content);
      _replaceContinuousResources();
      _clearVisiblePages();
      _invalidatePagination();
    }());
  }

  bool _layoutSettingsChanged(
    BookReaderSettings oldSettings,
    BookReaderSettings newSettings,
  ) =>
      oldSettings.fontFamily != newSettings.fontFamily ||
      oldSettings.fontSize != newSettings.fontSize ||
      oldSettings.fontWeight != newSettings.fontWeight ||
      oldSettings.justifyText != newSettings.justifyText ||
      oldSettings.lineHeight != newSettings.lineHeight ||
      oldSettings.contentWidth != newSettings.contentWidth ||
      oldSettings.horizontalPadding != newSettings.horizontalPadding ||
      oldSettings.verticalPadding != newSettings.verticalPadding;

  void _replaceContinuousResources() {
    final oldController = _continuousController;
    final oldFocusNode = _continuousFocusNode;
    final oldScrollController = _continuousScrollController;
    _createContinuousResources();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldController.dispose();
      oldFocusNode.dispose();
      oldScrollController.dispose();
    });
  }

  void _mutate(VoidCallback mutation) => setState(mutation);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final mode = _modeForWidth(constraints.maxWidth);
      if (_effectiveMode != mode) {
        _effectiveMode = mode;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _restoreCurrentPosition(),
        );
      }
      if (mode == BookReaderViewMode.continuous) {
        return _buildContinuousView();
      }
      final geometry = _ReaderPageGeometry.fromConstraints(
        constraints,
        settings: widget.settings,
        spread: mode == BookReaderViewMode.spread,
      );
      if (_geometry != geometry) {
        _geometry = geometry;
        _schedulePagination();
      }
      return _buildPagedView(context, geometry, mode);
    },
  );

  BookReaderViewMode _modeForWidth(double width) {
    if (widget.settings.viewMode == BookReaderViewMode.spread && width < 700) {
      return BookReaderViewMode.singlePage;
    }
    return widget.settings.viewMode;
  }

  void _restoreCurrentPosition() {
    if (_effectiveMode == BookReaderViewMode.continuous) {
      _restoreContinuousPosition();
    } else {
      _selectPageForProgress(_pendingProgress, rebuild: true);
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _paginationTimer?.cancel();
    _paginationRequest++;
    _hyphenationRequest++;
    _continuousController.dispose();
    _continuousFocusNode.dispose();
    _continuousScrollController.dispose();
    for (final controller in _pageControllers) {
      controller.dispose();
    }
    for (final node in _pageFocusNodes) {
      node.dispose();
    }
    for (final controller in _pageScrollControllers) {
      controller.dispose();
    }
    _measurementController?.dispose();
    _measurementFocusNode?.dispose();
    _measurementScrollController?.dispose();
    super.dispose();
  }
}
