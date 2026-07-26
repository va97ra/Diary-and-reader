import 'dart:async';
import 'dart:math' as math;

import 'package:dnevnik/features/books/application/book_reader_hyphenation.dart';
import 'package:dnevnik/features/books/application/book_reader_text_anchor.dart';
import 'package:dnevnik/features/books/domain/book_asset.dart';
import 'package:dnevnik/features/books/domain/book_reader_annotations.dart';
import 'package:dnevnik/features/books/domain/book_reader_settings.dart';
import 'package:dnevnik/features/books/domain/book_section.dart';
import 'package:dnevnik/features/books/domain/rich_document.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_continuous_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_model.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_document_view.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_layout_engine.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page_card.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_page_stage.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_palette.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_selection_resolver.dart';
import 'package:dnevnik/features/books/presentation/reader/book_reader_text_selection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

part 'book_reader_section_continuous.dart';
part 'book_reader_section_document.dart';
part 'book_reader_section_pagination.dart';

class BookReaderSectionController {
  _BookReaderSectionViewState? _state;

  Future<void> moveForward() async => _state?._moveByNavigation(1);

  Future<void> moveBackward() async => _state?._moveByNavigation(-1);

  void _attach(_BookReaderSectionViewState state) => _state = state;

  void _detach(_BookReaderSectionViewState state) {
    if (identical(_state, state)) _state = null;
  }
}

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
    required this.speechTargetMode,
    required this.onSpeechTargetSelected,
    required this.navigationController,
    this.speechRange,
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
  final bool speechTargetMode;
  final ValueChanged<int> onSpeechTargetSelected;
  final BookReaderSectionController navigationController;
  final BookReaderTextRange? speechRange;
  final VoidCallback? onNextSectionRequested;
  final VoidCallback? onPreviousSectionRequested;

  @override
  State<BookReaderSectionView> createState() => _BookReaderSectionViewState();
}

class _BookReaderSectionViewState extends State<BookReaderSectionView> {
  late final ScrollController _continuousScrollController;
  final _layoutEngine = BookReaderLayoutEngine();

  late BookReaderDisplayDocument _displayDocument;
  late BookReaderDocumentModel _readerDocument;
  List<BookReaderPageLayout> _pages = const [];
  int _hyphenationRequest = 0;
  int _selectionGeneration = 0;

  Timer? _progressTimer;
  double _progress = 0;
  double _pendingProgress = 0;
  int _activePage = 0;
  bool _navigationLocked = false;
  int? _continuousPointer;
  double? _continuousPointerStartY;
  bool _continuousPointerStartedAtStart = false;
  bool _continuousPointerStartedAtEnd = false;
  bool _continuousForwardInput = false;
  bool _continuousBackwardInput = false;
  _ReaderPageGeometry? _completedGeometry;
  BookReaderViewMode _effectiveMode = BookReaderViewMode.continuous;

  @override
  void initState() {
    super.initState();
    _progress = widget.initialProgress.clamp(0, 1).toDouble();
    _pendingProgress = _progress;
    widget.navigationController._attach(this);
    _displayDocument = BookReaderHyphenation.identity(widget.section.content);
    _readerDocument = BookReaderDocumentParser.parse(_displayDocument.document);
    _continuousScrollController = ScrollController()
      ..addListener(_handleContinuousScroll);
    _scheduleHyphenation();
    _restoreContinuousPosition();
  }

  @override
  void didUpdateWidget(covariant BookReaderSectionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sectionChanged =
        oldWidget.section.id != widget.section.id ||
        !identical(oldWidget.section.content, widget.section.content);
    if (!identical(
      oldWidget.navigationController,
      widget.navigationController,
    )) {
      oldWidget.navigationController._detach(this);
      widget.navigationController._attach(this);
    }
    if (sectionChanged) _navigationLocked = false;
    final hyphenationChanged =
        oldWidget.settings.hyphenateWords != widget.settings.hyphenateWords ||
        oldWidget.languageCode != widget.languageCode;
    if (sectionChanged || hyphenationChanged) {
      _displayDocument = BookReaderHyphenation.identity(widget.section.content);
      _readerDocument = BookReaderDocumentParser.parse(
        _displayDocument.document,
      );
      _layoutEngine.clear();
      _clearVisiblePages();
      _invalidatePagination();
      _scheduleHyphenation();
    } else if (_layoutSettingsChanged(oldWidget.settings, widget.settings)) {
      _invalidatePagination();
    }

    if (oldWidget.clearSelectionVersion != widget.clearSelectionVersion) {
      _clearSelection();
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
      final displayDocument = await hyphenation.applyInBackground(
        widget.section.content,
      );
      if (!mounted ||
          request != _hyphenationRequest ||
          !widget.settings.hyphenateWords ||
          widget.section.id != sectionId ||
          widget.languageCode != languageCode) {
        return;
      }
      setState(() {
        _displayDocument = displayDocument;
        _readerDocument = BookReaderDocumentParser.parse(
          _displayDocument.document,
        );
        _layoutEngine.clear();
        _clearVisiblePages();
        _invalidatePagination();
      });
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
      _ensurePagination(context, geometry);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_effectiveMode == BookReaderViewMode.continuous) {
        _restoreContinuousPosition();
      } else {
        _selectPageForProgress(_pendingProgress, rebuild: true);
      }
    });
  }

  Future<void> _moveByNavigation(int direction) async {
    if (_navigationLocked || direction == 0) return;
    if (_effectiveMode == BookReaderViewMode.continuous) {
      if (!_continuousScrollController.hasClients) return;
      final position = _continuousScrollController.position;
      final atBoundary = direction > 0
          ? position.extentAfter <= 1
          : position.extentBefore <= 1;
      if (atBoundary || position.maxScrollExtent <= 0) {
        _requestSectionNavigation(direction);
        return;
      }
      _navigationLocked = true;
      final target = (position.pixels + direction * position.viewportDimension)
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      await _continuousScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
      _navigationLocked = false;
      if (!mounted || !_continuousScrollController.hasClients) return;
      final updated = _continuousScrollController.position;
      final reachedBoundary = direction > 0
          ? updated.extentAfter <= 1
          : updated.extentBefore <= 1;
      if (reachedBoundary) _requestSectionNavigation(direction);
      return;
    }
    final step = _effectiveMode == BookReaderViewMode.spread ? 2 : 1;
    final target = _activePage + direction * step;
    if (target >= 0 && target < _pages.length) {
      _selectPage(target);
      return;
    }
    _requestSectionNavigation(direction);
  }

  void _requestSectionNavigation(int direction) {
    if (_navigationLocked) return;
    final callback = direction > 0
        ? widget.onNextSectionRequested
        : widget.onPreviousSectionRequested;
    if (callback == null) return;
    _navigationLocked = true;
    callback();
  }

  void _mutate(VoidCallback mutation) => setState(mutation);

  @override
  void dispose() {
    _progressTimer?.cancel();
    _hyphenationRequest++;
    widget.navigationController._detach(this);
    _continuousScrollController.dispose();
    super.dispose();
  }
}
