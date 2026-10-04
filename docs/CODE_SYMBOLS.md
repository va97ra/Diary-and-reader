# Указатель кода «Литерии»

Генерируется скриптом, руками не править: `dart run tool/code_map.dart`.
Число перед именем — строка в файле; после тире — первая фраза doc-комментария. Как всё связано — в `docs/CODE_MAP.md`.

## lib/

### lib/app/author_studio_app.dart (148)
- 24 class **AuthorStudioApp**
- 98 class **_WorkspaceSaveLifecycle**
- 112 class **_WorkspaceSaveLifecycleState**
  - 129 didChangeAppLifecycleState

### lib/app/desktop/literia_desktop_panel_frame.dart (81)
- 9 class **LiteriaDesktopPanelFrame** — Puts a slim bar above the app while it is a panel beside the clock: the panel has no title bar, so the bar expands it or hides it in the ...
- 36 class **_PanelBar**

### lib/app/desktop/literia_desktop_shell.dart (32)
- 7 enum **LiteriaWindowMode** — How the desktop window shows itself.
- 17 class **LiteriaDesktopShell** — The tray icon and the panel beside the clock that Literia has on Windows.
  - 20 showPanel
  - 22 showWindow
  - 25 hide — Hides the window; the app keeps running in the tray.
  - 28 quit — Saves the work and ends the app, tray icon included.
  - 31 updateLanguage — Re-labels the tray menu after the interface language changed.

### lib/app/desktop/literia_desktop_shell_io.dart (220)
- 15 fn startLiteriaDesktopShell — Starts the tray and window handling on Windows; elsewhere there is none.
- 29 class **_WindowsDesktopShell**
  - 46 get mode
  - 48 _start
  - 80 updateLanguage
  - 96 showPanel
  - 127 showWindow
  - 139 hide
  - 145 quit
  - 157 _showCurrentMode
  - 162 _reveal
  - 167 _rememberWindowBounds
  - 175 _defaultWindowBounds
  - 184 _workArea
  - 192 onTrayIconMouseDown
  - 202 onTrayIconRightMouseDown
  - 207 onTrayMenuItemClick
  - 217 onWindowClose

### lib/app/desktop/literia_desktop_shell_stub.dart (8)
- 4 fn startLiteriaDesktopShell — Without a desktop tray there is no shell: the app keeps its own window.

### lib/app/literia_book_details_page.dart (334)
- 13 class **LiteriaBookDetailsPage**
- 42 class **_BookDetailsBody**
  - 254 _editMetadata
  - 267 _formatDuration
- 277 class **_LeatherSection** — A section of the page on the leather of the book's title card.
- 301 class **_Fact** — A fact about the book with its name above it, or beside it when [inline].

### lib/app/literia_book_storage_page.dart (525)
- 13 enum **_StorageSort**
- 15 class **LiteriaBookStoragePage**
- 31 class **_LiteriaBookStoragePageState**
  - 185 _compareEntries
  - 196 _hasSelectedOriginal
  - 201 _addScanFolder
  - 209 _removeScanFolder
  - 216 _reload
  - 244 _deleteOriginals
  - 286 _deleteBooks
  - 309 _cleanupTemporaryFiles
  - 318 _selectedProjects
  - 322 _confirm
  - 342 _showMessage
- 349 class **_StorageSummary**
- 414 class **_ScanFoldersCard**
- 485 class **_StorageBookTile**

### lib/app/literia_device_books_page.dart (339)
- 10 class **LiteriaDeviceBooksPage**
- 27 class **_LiteriaDeviceBooksPageState**
  - 93 _buildBooks
  - 164 _chooseFolder
  - 172 _removeFolder
  - 184 _scan
  - 208 _importSelected
  - 237 _iconFor
- 242 class **_FolderBar**
- 297 class **_EmptyDeviceBooks**
- 332 fn formatFileSize

### lib/app/literia_home_page.dart (374)
- 9 class **LiteriaHomePage**
- 91 class **_HomeHeader**
- 142 class **_PrimaryTiles**
- 191 class **_LiteriaActionTile**
- 209 class **_LiteriaActionTileState**
- 243 class **_TileLabel**
- 277 class **_ContinueGrid** — The books to return to; a missing one simply leaves no card behind.
- 314 class **_ContinueCard**

### lib/app/literia_home_shell.dart (626)
- 30 class **LiteriaHomeShell**
- 58 class **_LiteriaHomeShellState**
  - 82 _openManuscriptLibrary
  - 95 _openReadingLibrary
  - 111 _createManuscript
  - 116 _openManuscript
  - 133 _importBook
  - 162 _showImportProgress
  - 191 _hideImportProgress
  - 204 _importFiles
  - 212 _importFileStream
  - 222 _importDeviceBooks
  - 256 _finishImport
  - 279 _scanAndImportDeviceBooks
  - 336 _scanAutomaticSources
  - 367 _ensureDownloadsAccess
  - 399 _repairScanFolderAccess
  - 436 _showScanResult
  - 449 _openReader
  - 493 _openBookDetails
  - 504 _deleteProject
  - 531 _openSettings
  - 549 _openBookStorage
  - 561 _backupLastManuscript
  - 578 _restoreProject
  - 619 _showMessage

### lib/app/literia_library_controls.dart (338)
- 5 fn _libraryIconButtonStyle — A square icon control that lines up with the search bar.
- 21 class **_LibraryControls**
- 113 class **_LibraryDisplayControls**
  - 187 _sortLabel
  - 196 _filterLabel
- 210 class **_LibraryMenuButton** — An icon control that drops a menu of [values] below itself.
  - 230 _openMenu
- 271 class **_LibraryPrimaryAction** — The library's main action, floating above the books.
- 294 class **_EmptyLibrary**
- 331 fn _readingStatusLabel

### lib/app/literia_library_items.dart (349)
- 4 const _coverActionStyle — A small dark disc that stays visible on light and dark covers alike.
- 13 class **_LibraryCard**
- 215 class **_LibraryListTile**
- 343 enum **_LibraryCardAction**

### lib/app/literia_library_page.dart (359)
- 16 enum **LiteriaLibraryMode**
- 21 class **LiteriaLibraryPage**
- 45 class **_LiteriaLibraryPageState**
  - 53 get _writing
  - 83 _buildPage
  - 269 _scanDeviceBooks
  - 279 _showCollectionDialog
  - 319 _toggleFavorite
  - 326 _showReadingStatusDialog

### lib/app/literia_settings_page.dart (154)
- 9 class **LiteriaSettingsPage**

### lib/app/literia_version.dart (3)
- 3 const literiaVersion — The version shown to people, as `version` in pubspec.yaml has it before the build number.

### lib/core/l10n/app_string_values_en.dart (554)
- 1 const appStringValuesEn

### lib/core/l10n/app_string_values_ru.dart (555)
- 1 const appStringValuesRu

### lib/core/l10n/app_strings.dart (546)
- 5 class **AppStrings**
  - 16 of
  - 19 _text
  - 21 get appTitle
  - 22 get quote
  - 23 get openBook
  - 24 get entries
  - 25 get newEntry
  - 26 get newEntryTitle
  - 27 get deleteEntry
  - 28 get deleteQuestion
  - 29 get cancel
  - 30 get formatting
  - 31 get margins
  - 32 get startWriting
  - 33 get addPage
  - 34 get page
  - 35 a4Sheet
  - 37 get normal
  - 38 get narrow
  - 39 get wide
  - 40 get top
  - 41 get right
  - 42 get bottom
  - 43 get left
  - 44 get apply
  - 45 get language
  - 46 get data
  - 47 get exportData
  - 48 get importData
  - 49 get exportSuccess
  - 50 get importSuccess
  - 51 get importFailed
  - 52 get confirmImport
  - 53 get millimeters
  - 54 get studioTitle
  - 55 get homeTagline
  - 56 get write
  - 57 get writeSubtitle
  - 58 get read
  - 59 get readSubtitle
  - 60 get settings
  - 61 get continueWriting
  - 62 get continueReading
  - 63 get manuscriptLibrary
  - 64 get readingLibrary
  - 65 get createBook
  - 66 get supportedBookFormats
  - 67 get emptyManuscripts
  - 68 get emptyReadingLibrary
  - 69 get appearance
  - 70 get appTheme
  - 71 get showGuide
  - 72 get systemTheme
  - 73 get help
  - 74 get about
  - 75 get bookStorage
  - 76 get bookStorageSubtitle
  - 77 get bookStorageLoadFailed
  - 78 get totalBookData
  - 79 get storedOriginals
  - 80 get processedBooks
  - 81 get freeSpace
  - 82 get storedOriginal
  - 83 get originalNotStored
  - 84 get deleteStoredOriginal
  - 85 get deleteBooksCompletely
  - 86 get clearTemporaryFiles
  - 87 get originalDeleteWarning
  - 88 get completeDeleteWarning
  - 89 get temporaryFilesCleared
  - 90 get originalFilesDeleted
  - 91 get booksDeleted
  - 92 get bySize
  - 93 get byLastRead
  - 94 get structure
  - 95 get writerSettings
  - 96 get writerFormatting
  - 97 get onboarding
  - 98 get quickStart
  - 99 get quickStartBody
  - 100 get understood
  - 101 get more
  - 102 get previewBook
  - 103 get resetSettings
  - 104 get library
  - 105 get librarySearchHint
  - 106 get manuscriptLibrarySearchHint
  - 108 get sortBy
  - 109 get filterBooks
  - 110 get recentlyUpdated
  - 111 get byTitle
  - 112 get byAuthor
  - 113 get byProgress
  - 114 get allBooks
  - 115 get manuscripts
  - 116 get importedBooks
  - 117 get unreadBooks
  - 118 get readingBooks
  - 119 get finishedBooks
  - 120 get favoriteBooks
  - 121 get readingStatus
  - 122 get statusAutomatic
  - 123 get wantToRead
  - 124 get pausedReading
  - 125 get gridView
  - 126 get listView
  - 127 get aboutBook
  - 128 get editMetadata
  - 129 get editShort
  - 130 get readingTime
  - 131 get lastRead
  - 132 get readingHistory
  - 133 get series
  - 134 get genre
  - 135 get isbn
  - 136 get publisher
  - 137 get allCollections
  - 138 get noCollection
  - 139 get moveToCollection
  - 140 get collectionName
  - 141 get collectionHint
  - 142 get removeFromCollection
  - 143 get noBooksFound
  - 144 get emptyLibrary
  - 145 get manuscript
  - 146 get chapters
  - 147 get updated
  - 148 get properties
  - 149 get newBook
  - 150 get importEbook
  - 151 get importBooks
  - 152 get scanBooks
  - 153 get scanningBooks
  - 154 get noNewBooks
  - 155 get scanFolders
  - 156 get scanFolderAccessLost
  - 157 get selectScanFolder
  - 158 get scanFailed
  - 159 get downloadsAccessExplanation
  - 160 get grantFileAccess
  - 161 get fileAccessNotGranted
  - 162 get addBookFolder
  - 163 get refresh
  - 164 get addSelected
  - 165 get removeFolder
  - 166 get noBookFolders
  - 167 get noDeviceBooks
  - 168 get alreadyInLibrary
  - 169 get notAdded
  - 170 get noAccess
  - 171 get savingBooks
  - 172 get duplicateBooksSkipped
  - 173 get someBooksFailed
  - 174 get notEnoughStorage
  - 175 get importEbookHint
  - 176 get importedBook
  - 177 get importedBookHint
  - 178 get sourceFile
  - 179 get bookImported
  - 180 get importingBooks
  - 181 get openingBook
  - 182 get bookImportFailed
  - 183 get unsupportedBookFormat
  - 184 get conversionRequired
  - 185 get noReadableBookText
  - 186 sectionsInBook
  - 187 imagesInBook
  - 188 get newPart
  - 189 get newChapter
  - 190 get newScene
  - 191 get bookTitle
  - 192 get chapterTitle
  - 193 get author
  - 194 get subtitle
  - 195 get description
  - 196 get draftStatus
  - 197 get planned
  - 198 get draft
  - 199 get revision
  - 200 get complete
  - 201 get editor
  - 202 get focusWriting
  - 203 get exitFocusWriting
  - 204 get a4Preview
  - 205 get comfortableWriting
  - 206 get a4PreviewHint
  - 207 get moreActions
  - 208 get bookTools
  - 209 get keepingTextSafe
  - 210 get findAndReplaceHint
  - 211 get writingStatisticsHint
  - 212 get previewBookHint
  - 213 get exportBookHint
  - 214 get versionHistoryHint
  - 215 get trashHint
  - 216 get backupProjectHint
  - 217 get restoreProjectBackupHint
  - 218 get moveUp
  - 219 get moveDown
  - 220 get dragSectionHint
  - 221 get deleteSection
  - 222 get deleteBook
  - 223 get deleteSectionQuestion
  - 224 get trash
  - 225 get trashEmpty
  - 226 get trashEmptyHint
  - 227 get emptyTrash
  - 228 get emptyTrashHint
  - 229 get restoreSection
  - 230 get sectionRestored
  - 231 get deletePermanently
  - 232 get deleteForeverHint
  - 233 get automaticBeforeDelete
  - 234 get automaticBeforeReplace
  - 235 get deleteBookQuestion
  - 236 get pageLayout
  - 237 get chapterSettings
  - 238 get chapterSettingsHint
  - 239 get paperFormat
  - 240 get showChapterTitlesInBody
  - 241 get showChapterTitlesInBodyHint
  - 243 get orientation
  - 244 get portrait
  - 245 get landscape
  - 246 get words
  - 247 get characters
  - 248 get paragraphs
  - 249 get writingGoal
  - 250 get writingStatistics
  - 251 get today
  - 252 get wholeBook
  - 253 get writingTime
  - 254 get activeDays
  - 255 get writingStreak
  - 256 get goals
  - 257 get wordsWritten
  - 258 get statisticsDetails
  - 259 get goalsHint
  - 260 get hoursShort
  - 261 get minutesShort
  - 262 get dailyWritingGoal
  - 263 get projectWritingGoal
  - 264 get saved
  - 265 get saving
  - 266 get saveError
  - 267 get paragraphStyle
  - 268 get stylePreset
  - 269 get modernStyle
  - 270 get classicStyle
  - 271 get manuscriptStyle
  - 272 get customStyle
  - 273 get defaultFont
  - 274 get fontSize
  - 275 get points
  - 276 get paragraphIndent
  - 277 get lineSpacing
  - 278 get spacingBefore
  - 279 get spacingAfter
  - 280 get viewMode
  - 281 get continuousPagesShort
  - 282 get singlePageShort
  - 283 get twoPageSpread
  - 284 get previousPage
  - 285 get nextPage
  - 286 get paragraphType
  - 287 get insertIntoText
  - 288 get characterFormatting
  - 289 get paragraphFormatting
  - 290 get wholeManuscriptFormatting
  - 291 get wholeBookHint
  - 292 get formattingHint
  - 293 get font
  - 294 get paragraphSpacing
  - 295 get bodyText
  - 296 get heading1
  - 297 get heading2
  - 298 get heading3
  - 299 get quoteStyle
  - 300 get epigraph
  - 301 get sceneBreak
  - 302 get insertImage
  - 303 get imageInserted
  - 304 get imageInsertFailed
  - 305 get coverHint
  - 306 get uploadCover
  - 307 get replaceCover
  - 308 get removeCover
  - 309 get coverUpdated
  - 310 get illustrationSettings
  - 311 get illustrationSettingsHint
  - 312 get imagePosition
  - 313 get alignLeft
  - 314 get alignCenter
  - 315 get alignRight
  - 316 get alignJustify
  - 317 get imageSize
  - 318 get imageCaption
  - 319 get imageCaptionHint
  - 320 get moveImageUp
  - 321 get moveImageDown
  - 322 get moveImageToCursor
  - 323 get imageMoveHint
  - 324 get replaceImage
  - 325 get deleteImage
  - 326 get picture
  - 327 get addPicture
  - 328 get addPictureHint
  - 329 get imageFromGallery
  - 330 get imageFromFile
  - 331 get imageFromClipboard
  - 332 get pasteImage
  - 333 get clipboardHasNoImage
  - 334 get imageSmaller
  - 335 get imageLarger
  - 336 get imageMoreSettings
  - 337 get imageDragHint
  - 338 get insertPageBreak
  - 339 get pageBreak
  - 340 get pageBreakInserted
  - 341 get reader
  - 342 get tableOfContents
  - 343 get readingSettings
  - 344 get readerLook
  - 345 get readerText
  - 346 get readerControls
  - 347 get readerSettingsHint
  - 348 get weightLight
  - 349 get weightRegular
  - 350 get weightMedium
  - 351 get weightSemiBold
  - 352 get weightBold
  - 353 get extraWide
  - 354 get widthNarrow
  - 355 get widthMedium
  - 356 get widthWide
  - 357 get widthFull
  - 358 get speechSlow
  - 359 get speechNormal
  - 360 get speechFast
  - 361 get speechFastest
  - 362 get pitchLow
  - 363 get pitchNormal
  - 364 get pitchHigh
  - 365 get focusReading
  - 366 get exitFocusReading
  - 367 get readerTheme
  - 368 get lightTheme
  - 369 get sepiaTheme
  - 370 get darkTheme
  - 371 get readerFont
  - 372 get readerFontSize
  - 373 get fontWeight
  - 374 get justifyText
  - 375 get hyphenateWords
  - 376 get centerTapControls
  - 377 get swipeChapterNavigation
  - 378 get textToSpeech
  - 379 get voiceSettings
  - 380 get speechRate
  - 381 get speechPitch
  - 382 get speechShort
  - 383 get startReadingAloud
  - 384 get stopReadingAloud
  - 385 get chooseSpeechStart
  - 386 get cancelSpeechStart
  - 387 get pauseReadingAloud
  - 388 get resumeReadingAloud
  - 389 get resumeShort
  - 390 get slowerSpeech
  - 391 get fasterSpeech
  - 392 get speechError
  - 393 get textWidth
  - 394 get previousSection
  - 395 get nextSection
  - 396 get previousShort
  - 397 get nextShort
  - 398 get readingProgress
  - 399 get contentsShort
  - 400 get readerNavigation
  - 401 get bookmarks
  - 402 get notes
  - 403 get noBookmarks
  - 404 get noNotes
  - 405 get bookmark
  - 406 get addBookmark
  - 407 get removeBookmark
  - 408 get deleteBookmark
  - 409 get addNoteHere
  - 410 get newNote
  - 411 get editNote
  - 412 get deleteNote
  - 413 get noteText
  - 414 get save
  - 415 get searchShort
  - 416 get searchInBook
  - 417 get clearSearch
  - 418 get searchHint
  - 419 get nothingFound
  - 420 get findAndReplace
  - 421 get manuscriptSearchHint
  - 422 get replaceWith
  - 423 get replaceAll
  - 424 get caseSensitive
  - 425 matchesFound
  - 426 replacementsMade
  - 427 get readerViewMode
  - 428 get continuousReading
  - 429 get singlePageReading
  - 430 get spreadReading
  - 431 get spreadPhoneHint
  - 432 get horizontalMargins
  - 433 get verticalMargins
  - 434 get previousReaderPage
  - 435 get nextReaderPage
  - 436 get highlights
  - 437 get quotes
  - 438 get noHighlights
  - 439 get highlightActions
  - 440 get yellowHighlight
  - 441 get greenHighlight
  - 442 get blueHighlight
  - 443 get pinkHighlight
  - 444 get saveQuote
  - 445 get addNoteToSelection
  - 446 get copySelection
  - 447 get dictionary
  - 448 get translate
  - 449 get webSearch
  - 450 get externalActionFailed
  - 451 get closeSelectionActions
  - 452 get deleteHighlight
  - 453 get deleteQuote
  - 454 get exportAnnotations
  - 455 get exportMarkdown
  - 456 get exportMarkdownHint
  - 457 get exportJson
  - 458 get exportJsonHint
  - 459 get annotationsExported
  - 460 get annotationsExportFailed
  - 461 get quoteSaved
  - 462 get highlightSaved
  - 463 get selectionCopied
  - 464 get exportBook
  - 465 get exportEpub
  - 466 get exportEpubHint
  - 467 get exportFb2
  - 468 get exportFb2Hint
  - 469 get exportFb2Zip
  - 470 get exportFb2ZipHint
  - 471 get exportPdf
  - 472 get exportPdfHint
  - 473 get exportDocx
  - 474 get exportDocxHint
  - 475 get exportHtml
  - 476 get exportHtmlHint
  - 477 get exportTxt
  - 478 get exportTxtHint
  - 479 get readerExportFormats
  - 480 get printExportFormats
  - 481 get textExportFormats
  - 482 get bookExported
  - 483 get bookExportFailed
  - 484 get pdfPreview
  - 485 get savePdf
  - 486 get preparingPdf
  - 487 get pdfPreviewFailed
  - 488 get pdfSaved
  - 489 get retry
  - 490 get projectData
  - 491 get versionHistory
  - 492 get createVersion
  - 493 get versionLabel
  - 494 get versionLabelHint
  - 495 get unnamedVersion
  - 496 get noVersions
  - 497 get noVersionsHint
  - 498 get restoreVersion
  - 499 get restoreVersionQuestion
  - 500 get versionCreated
  - 501 get versionRestored
  - 502 get versionOperationFailed
  - 503 get deleteVersion
  - 504 get deleteVersionQuestion
  - 505 get safetyVersionLabel
  - 506 get backupProject
  - 507 get restoreProjectBackup
  - 508 get projectBackupSaved
  - 509 get projectBackupFailed
  - 510 get projectRestored
  - 511 get projectRestoreFailed
  - 512 get confirmProjectRestore
  - 513 get webVersionLimit
  - 516 readerPageOf — A null [count] means the rest of the chapter is still being laid out.
  - 518 sectionOf
  - 520 sectionTitle
  - 522 get restoreDeletedText
  - 523 get textRestored
  - 524 get deletedPicture
  - 525 get verse
  - 526 get textColor
  - 527 get boldText
  - 528 get italicText
  - 529 get underlineText
  - 530 get strikeText
  - 531 get clearFormatting
  - 532 get selectionBarHint
  - 533 get noTextColor
  - 534 textColorName
  - 536 get trayPanel
  - 537 get trayWindow
  - 538 get trayQuit
  - 539 get expandToWindow
  - 540 get hideToTray

### lib/core/theme/app_theme.dart (137)
- 3 class **AppTheme**
  - 11 get light
  - 13 get dark
  - 15 _theme

### lib/features/books/application/author_workspace_controller.dart (866)
- 33 class **AuthorWorkspaceController**
  - 62 get projects
  - 64 get languageCode
  - 65 get saveState
  - 66 get appPreferences
  - 67 get readerSettings
  - 68 get themePreference
  - 70 get lastManuscript
  - 75 get lastReading
  - 80 get activeProject
  - 88 get activeSection
  - 90 load
  - 103 compactImportedCatalogs
  - 124 addProject
  - 133 addImportedBook
  - 146 rollbackImportedBook
  - 164 deleteProject
  - 177 updateImportedBookSource
  - 196 clearImportedBookStoredSource
  - 205 addBookScanFolder
  - 213 removeBookScanFolder
  - 224 selectProject
  - 238 updateProjectCollection
  - 250 updateProjectMetadata
  - 260 updateProjectFavorite
  - 272 updateProjectReadingStatus
  - 284 recordReadingTime
  - 288 recordReadingTimeDuringReading
  - 293 _recordReadingTime
  - 308 selectSection
  - 315 addSection
  - 328 moveSection
  - 336 moveSectionToTarget
  - 351 deleteSection
  - 364 deleteSectionSafely
  - 376 restoreDeletedSection
  - 385 permanentlyDeleteSection
  - 393 emptyTrash
  - 399 restoreDeletedText
  - 407 permanentlyDeleteText
  - 416 updateSectionTitle
  - 424 updateSectionContent
  - 435 addAsset
  - 446 setCoverAsset
  - 460 clearCoverAsset
  - 472 replaceAllInManuscript
  - 491 replaceAllInManuscriptSafely
  - 514 updateSectionStatus
  - 522 updateSectionTargetWords
  - 533 updateWritingGoals
  - 550 recordWritingSession
  - 572 updateMetadata
  - 580 updateLayoutSettings
  - 589 updateParagraphSettings
  - 600 updateReaderSettings
  - 604 updateReaderSettingsDuringReading
  - 609 _updateReaderSettings
  - 623 updateReaderProgress
  - 627 updateReaderProgressDuringReading
  - 632 _updateReaderProgress
  - 646 updateReaderAnnotations
  - 650 updateReaderAnnotationsDuringReading
  - 657 _updateReaderAnnotations
  - 671 beginReaderSession
  - 683 finishReaderSession
  - 696 setLanguage
  - 704 _localizeDefaultTitles — Renames untouched default titles into the interface language; reports whether any changed.
  - 716 setThemePreference
  - 722 markOnboardingSeen
  - 728 resetOnboarding
  - 734 listVersions
  - 740 createVersion
  - 747 deleteVersion
  - 753 restoreVersion
  - 769 importProject
  - 777 flush
  - 781 flushWithResult
  - 783 _replaceActiveProjectFromExternalSource
  - 805 _newProject
  - 811 _replaceActiveProject
  - 818 _projectById
  - 831 _changed
  - 846 _markDirty
  - 848 get _snapshot

### lib/features/books/application/book_catalog_project.dart (63)
- 5 class **BookCatalogProject**
  - 6 compact
  - 23 hydrate

### lib/features/books/application/book_cover_thumbnail.dart (41)
- 7 class **BookCoverThumbnail**
  - 12 compact

### lib/features/books/application/book_deleted_text.dart (102)
- 8 class **BookDeletedText** — Finds what one edit deleted from a chapter and puts it back later.
  - 17 static — The fragment that turning [before] into [after] deleted, with the offset where it began: a whole word or more, or a picture.
  - 64 restore — [content] with [fragment] put back at [offset], or at the end of the chapter when the chapter has since become shorter.
  - 90 _isWord
  - 93 _flatten
  - 98 _json

### lib/features/books/application/book_device_catalog.dart (74)
- 4 class **DeviceBookCandidate**
- 20 class **DeviceBookScanResult**
- 30 class **BookDeviceCatalogGateway**
  - 33 chooseFolder
  - 35 scan
  - 37 materialize
  - 39 releaseFolder
  - 41 availableBytes
- 44 class **BookDownloadsCatalogGateway**
  - 45 hasDownloadsAccess
  - 47 requestDownloadsAccess
  - 49 scanDownloads
- 52 class **UnsupportedBookDeviceCatalog**
  - 56 get supportsFolderScanning
  - 59 availableBytes
  - 62 chooseFolder
  - 65 materialize
  - 69 releaseFolder
  - 72 scan

### lib/features/books/application/book_docx_content_renderer.dart (452)
- 12 class **BookDocxEmbeddedImage**
- 24 class **BookDocxRenderedContent**
- 40 class **BookDocxContentRenderer**
  - 41 render
- 47 class **_DocxRenderContext**
  - 64 render
  - 88 _titlePage
  - 137 _tableOfContents
  - 160 _section
  - 198 _block
  - 230 _paragraphProperties
  - 279 _run
  - 320 _simpleParagraph
  - 337 _plainRun
  - 340 _pageBreak
  - 342 _imageParagraph
  - 403 _outlineLevel
  - 418 _allocateNumbering
  - 424 _hyperlinkRelationship
  - 433 _bookmark
  - 435 _alignment
  - 442 _millimetersToTwips
  - 445 _text

### lib/features/books/application/book_docx_exporter.dart (101)
- 9 class **BookDocxExporter**
  - 13 create

### lib/features/books/application/book_docx_package_parts.dart (247)
- 3 class **BookDocxHyperlinkRelationship**
- 10 class **BookDocxImageRelationship**
- 17 class **BookDocxPackageParts**
  - 48 documentRelationships
  - 76 coreProperties
  - 106 styles
  - 141 numbering
  - 180 fontTable
  - 194 header
  - 208 sectionProperties
  - 224 _headingStyle
  - 227 _tocStyle
  - 230 _halfPoints
  - 232 _millimetersToTwips
  - 235 _wordDate
- 242 fn docxEscapeXml

### lib/features/books/application/book_epub_exporter.dart (331)
- 11 class **BookEpubExporter**
  - 12 create
  - 60 _package
  - 113 _navigation
  - 134 _navigationTree
  - 172 _titlePage
  - 194 _sectionPage
  - 212 _xhtml
  - 233 _stylesheet
  - 272 _metadataElement
  - 280 _seriesMetadata
  - 284 _htmlElement
  - 292 _sectionFile
  - 295 _imageFileName
  - 308 _epubType
  - 314 _epubDate
  - 320 _number
- 325 const _containerDocument

### lib/features/books/application/book_export_artifact.dart (15)
- 3 enum **BookExportFormat**
- 5 class **BookExportArtifact**

### lib/features/books/application/book_export_content.dart (237)
- 4 enum **BookExportBlockType**
- 19 enum **BookExportTextAlignment**
- 21 class **BookExportTextRun**
- 53 class **BookExportBlock**
  - 81 get isVerse — A line of a poem; consecutive lines form a stanza, an empty line ends it.
  - 85 get indentsFirstLine — Whether the first line takes the book's paragraph indent: body text set to the left or justified, as the writer draws it.
  - 91 get isListItem
- 100 class **BookExportContentParser**
  - 101 parse
  - 166 _run
  - 189 _block
  - 228 _safeLink
  - 235 _integer

### lib/features/books/application/book_fb2_exporter.dart (221)
- 13 class **BookFb2Exporter**
  - 17 create
  - 26 createZip
  - 39 _document
  - 82 _sections
  - 137 _indentedContent
  - 147 _author
  - 163 _annotation
  - 167 _sequence
  - 171 _publishInfo
  - 183 _customInfo
  - 187 _optionalElement
  - 190 _genre
  - 208 _date
  - 214 _binaries

### lib/features/books/application/book_format_parser.dart (14)
- 4 enum **BookImportFormat**
- 6 class **BookFormatParser**
  - 9 parse

### lib/features/books/application/book_html_exporter.dart (116)
- 10 class **BookHtmlExporter**
  - 11 create
  - 20 _document
  - 104 _meta
  - 108 _element
  - 113 _number

### lib/features/books/application/book_image_document_editing.dart (187)
- 16 class **BookImageDocumentEditing** — Edits illustration embeds in a Quill document.
  - 17 _embed
  - 20 _embedJson
  - 26 normalizeEmbeds — Rewrites legacy `custom`-wrapped illustrations as direct embeds so the editor works with attached nodes.
  - 45 placementAt — Reads the illustration stored at [offset], or null when there is none.
  - 63 insert — Inserts [placement] on its own line at [requestedOffset] and places the cursor after it.
  - 95 replace
  - 113 remove — Removes the illustration together with its line so no blank paragraph is left behind.
  - 129 move — Moves the illustration at [from] so that it starts the line at [targetOffset] (an offset in the current document).
  - 176 _startsLine
  - 182 _removalLength

### lib/features/books/application/book_image_file.dart (66)
- 5 class **BookImageFile**
- 13 class **BookImageFileGateway**
  - 14 open
- 17 class **BookClipboardImageGateway**
  - 20 hasImage — Cheap check that must not read the clipboard contents, so Android does not show its "pasted from clipboard" notice when a menu merely opens.
  - 22 read
- 25 class **BookImageFileCodec**
  - 28 createAsset
  - 40 _mediaType
  - 59 _startsWith

### lib/features/books/application/book_import_coordinator.dart (246)
- 10 enum **BookImportItemFailure**
- 20 class **BookImportItemResult**
  - 31 get succeeded
- 34 class **BookImportBatchResult**
  - 39 get imported
  - 44 get duplicateCount
  - 48 get failedCount
  - 55 get conversionRequiredCount
- 60 class **BookImportCoordinator**
  - 69 import
  - 77 importStream
  - 205 _rollbackFailedImport
  - 220 _deleteFailedImportFiles
- 229 fn _prepareBookImport
- 235 fn _sameSource
- 241 class **_PreparedBookImport**

### lib/features/books/application/book_import_file.dart (38)
- 3 class **BookImportFile**
  - 18 get effectiveSizeBytes
- 21 enum **BookImportFailure**
- 28 class **BookImportException**

### lib/features/books/application/book_import_parser.dart (118)
- 14 class **BookImportParser**
  - 22 parse
  - 46 parseCatalog
  - 81 _detect
  - 116 _isZip

### lib/features/books/application/book_import_parsing_support.dart (173)
- 13 class **BookImportParsingSupport**
  - 14 project
  - 45 catalogProject
  - 69 firstElement
  - 74 directElement
  - 79 elements
  - 83 textOf
  - 91 archiveFile
  - 99 archiveBytes
  - 102 resolveArchivePath
  - 108 normalizePath
  - 111 baseName
  - 122 language
  - 125 imageReference
  - 134 cleanImageReference
  - 137 normalizedImageMediaType
  - 146 canStoreImage
- 152 class **ImportedBookMedia**
  - 163 get pathToAssetId
  - 165 resolve
- 171 extension **BookImportString**
  - 172 ifEmpty

### lib/features/books/application/book_library_query.dart (103)
- 5 enum **BookLibraryFilter**
- 15 enum **BookLibrarySort**
- 17 class **BookLibraryQuery**
  - 32 apply
  - 52 _matchesCollection
  - 55 _matchesFilter
  - 69 _compare
- 86 fn effectiveReadingStatus
- 95 fn readingProgress
- 100 fn _text
- 102 fn _lastRead

### lib/features/books/application/book_manuscript_search.dart (118)
- 6 class **BookManuscriptMatch**
- 22 class **BookDocumentReplacement**
- 29 class **BookManuscriptSearch**
  - 30 find
  - 45 replaceAll
  - 73 _findInSection
  - 90 _offsets
  - 108 _excerpt

### lib/features/books/application/book_markdown_exporter.dart (53)
- 9 class **BookMarkdownExporter**
  - 10 create
  - 41 _heading
  - 47 _inline

### lib/features/books/application/book_page_paginator.dart (191)
- 5 class **BookPageSplit**
- 14 class **BookPagePaginator** — Splits a Quill Delta into screen pages without adding hard paragraph breaks to the saved manuscript.
  - 20 splitAtFirstHardPageBreak — Returns the first author-inserted page break that fits inside the measured page.
  - 40 split
  - 59 prependOverflow
  - 67 merge
  - 81 _isSoftPageBreak
  - 88 _appendNormalized
  - 103 _sameAttributes
  - 106 _length
  - 112 _firstHardPageBreakEnd
  - 131 _slice
  - 156 _nextNewlineAttributes
  - 178 _endsWithNewline
  - 184 _isBlank
  - 189 _copy

### lib/features/books/application/book_pagination_measurement.dart (69)
- 6 class **BookPaginationMeasurement**
  - 13 get currentPageNumber
  - 15 get completedPages
  - 18 begin
  - 23 scheduleRetry
  - 25 resetRetries
  - 27 advance
- 52 class **BookPaginationMeasurementStep**

### lib/features/books/application/book_pdf_content_renderer.dart (335)
- 8 class **BookPdfContentRenderer**
  - 52 _spacing
  - 82 _blockWidget
  - 199 _richText
  - 269 _listRow
  - 284 _checkRow
  - 319 _decoration
  - 328 _alignment

### lib/features/books/application/book_pdf_exporter.dart (316)
- 12 class **BookPdfExporter**
  - 13 create
  - 104 formatFor
  - 116 _theme
  - 135 _titlePage
  - 201 _header
  - 231 _footer
  - 240 _tableOfContents
  - 283 _depth
  - 298 _sectionTitleSize
  - 304 _defaultContentsTitle
  - 307 _optional
- 311 class **_PdfOutlineEntry**

### lib/features/books/application/book_pdf_font_assets.dart (19)
- 3 class **BookPdfFontAssets**
- 17 class **BookPdfFontLoader**
  - 18 load

### lib/features/books/application/book_project_archive_codec.dart (33)
- 5 class **BookProjectArchiveCodec**
  - 9 encode
  - 17 decode

### lib/features/books/application/book_reader_annotation_exporter.dart (162)
- 6 enum **BookReaderAnnotationExportFormat**
- 8 class **BookReaderAnnotationExport**
- 20 class **BookReaderAnnotationExporter**
  - 21 create
  - 56 _markdown
  - 151 _percent
  - 153 _singleLine
  - 156 _colorMarker

### lib/features/books/application/book_reader_external_lookup.dart (36)
- 3 enum **BookReaderLookupAction**
- 5 typedef **BookReaderUriLauncher**
- 7 class **BookReaderExternalLookup**
  - 8 uri
- 35 fn launchBookReaderUri

### lib/features/books/application/book_reader_hyphenation.dart (214)
- 7 class **BookReaderDisplayDocument**
  - 18 get originalLength
  - 19 get displayLength
  - 21 originalToDisplay
  - 24 displayToOriginal
- 28 class **BookReaderHyphenation**
  - 45 forLanguage
  - 58 identity
  - 61 apply
  - 64 applyInBackground
  - 78 _build
- 131 fn _createHyphenator
- 143 class **_StoredHyphenationResource**
- 160 class **_RepairedRussianResource** — The bundled Russian TeX file in `hyphenator_impure` is UTF-8 text that was accidentally encoded a second time through Windows-1252.
- 172 fn _repairWindows1252Utf8
- 186 const _windows1252Bytes

### lib/features/books/application/book_reader_search.dart (77)
- 4 class **BookReaderSearchResult**
- 20 class **BookReaderSearch**
  - 21 find
  - 67 _excerpt

### lib/features/books/application/book_reader_text_anchor.dart (44)
- 3 class **BookReaderTextRange**
- 10 class **BookReaderTextAnchor**
  - 11 resolve

### lib/features/books/application/book_reading_session_loader.dart (53)
- 8 class **BookReadingSessionLoader**
  - 13 load
- 51 fn _parseReadingSource

### lib/features/books/application/book_section_outline.dart (51)
- 3 class **BookSectionOutlineEntry**
- 15 class **BookSectionOutline**
  - 16 flatten

### lib/features/books/application/book_source_storage.dart (146)
- 6 class **StoredBookSource**
- 13 class **BookStorageEntry**
  - 26 get totalBytes
- 29 class **BookStorageOverview**
  - 42 get totalBytes
- 45 class **BookSourceStorage**
  - 46 store
  - 51 deleteOriginal
  - 53 deleteProjectFiles
  - 55 inspect
  - 60 cleanup
- 63 class **BookReadingCacheStorage**
  - 64 loadOriginal
  - 66 loadProcessed
  - 68 storeProcessed
  - 70 hasOriginal
- 73 class **EphemeralBookSourceStorage**
  - 81 cleanup
  - 84 deleteOriginal
  - 89 deleteProjectFiles
  - 95 hasOriginal
  - 99 loadOriginal
  - 103 loadProcessed
  - 107 storeProcessed
  - 115 inspect
  - 139 store

### lib/features/books/application/book_speech_engine.dart (342)
- 7 class **BookSpeechEngine**
  - 8 configure
  - 16 setCompletionHandler
  - 18 setErrorHandler
  - 20 speak
  - 22 pause
  - 24 resume
  - 26 stop
- 29 class **BookSpeechProgressEngine**
  - 30 setProgressHandler
- 33 class **FlutterBookSpeechEngine**
  - 40 get _supportsSystemMediaSession
  - 48 setProgressHandler
  - 56 configure
  - 71 setCompletionHandler
  - 75 setErrorHandler
  - 79 speak
  - 82 pause
  - 85 resume
  - 88 stop
- 91 class **_DirectBookSpeechEngine**
  - 99 setProgressHandler
  - 109 configure
  - 128 setCompletionHandler
  - 133 setErrorHandler
  - 138 speak
  - 144 pause
  - 149 resume
  - 154 stop
- 160 class **_AudioServiceBookSpeechEngine**
  - 167 async
  - 175 _createHandler
  - 188 configure
  - 206 setCompletionHandler
  - 215 setErrorHandler
  - 224 setProgressHandler
  - 233 speak
  - 236 pause
  - 239 resume
  - 242 stop
- 245 class **_BookTtsAudioHandler**
  - 272 configure
  - 299 speakText
  - 307 play
  - 313 pause
  - 319 stop
  - 326 _broadcast

### lib/features/books/application/book_speech_segmenter.dart (77)
- 1 class **BookSpeechSegment**
- 13 class **BookSpeechSegmenter**
  - 14 split
  - 53 wordStart
  - 66 _isSentenceBoundary
  - 73 _isWhitespace
  - 75 _isBoundary

### lib/features/books/application/book_txt_exporter.dart (50)
- 9 class **BookTxtExporter**
  - 10 create

### lib/features/books/application/epub_book_format_parser.dart (588)
- 15 class **EpubBookFormatParser**
  - 19 get formats
  - 22 parse
  - 104 parseCatalog
  - 165 _parseXml
  - 171 _readSections
  - 342 _readNavigationTitles
  - 433 _readMedia
  - 518 _readCatalogCover

### lib/features/books/application/epub_rich_text_renderer.dart (157)
- 5 class **EpubRichTextRenderer**
  - 6 render
  - 106 _inline
  - 130 _blockAttributes
  - 147 _number
- 152 fn escapeXml

### lib/features/books/application/fb2_book_format_parser.dart (482)
- 18 class **Fb2BookFormatParser**
  - 22 get formats
  - 28 parse
  - 44 parseCatalog
  - 95 _catalogArchiveSource
  - 106 _parseArchive
  - 122 _parseSource
  - 180 _readSections
  - 273 _readFlattenedChapterSections
  - 333 _flatHeadingTitle
  - 347 _readMedia
  - 402 _readCatalogCover
  - 471 _author

### lib/features/books/application/fb2_rich_text_renderer.dart (122)
- 5 class **Fb2RichTextRenderer**
  - 6 render
  - 109 _inline

### lib/features/books/application/legacy_diary_migrator.dart (66)
- 9 class **LegacyDiaryMigrator**
  - 12 migrate

### lib/features/books/application/manuscript_project_editor.dart (331)
- 17 class **ManuscriptProjectEditor**
  - 18 addSection
  - 38 moveSection
  - 47 deleteSection
  - 95 restoreDeletedSection
  - 122 deleteTrashEntry
  - 130 emptyTrash
  - 138 restoreDeletedText — Puts deleted text back where it was, in its chapter if that still exists and in the active one otherwise, and opens that chapter.
  - 168 deleteTextTrashEntry
  - 176 updateSectionTitle
  - 187 updateSectionContent — Replaces the active chapter's text.
  - 215 addAsset
  - 224 replaceAll
  - 254 updateSectionStatus
  - 262 updateSectionTargetWords
  - 271 updateMetadata
  - 276 updateLayoutSettings
  - 281 updateParagraphSettings
  - 286 _updateActiveSection
  - 300 _parentForNewSection
- 319 class **ManuscriptReplaceResult**

### lib/features/books/application/markdown_rich_text_renderer.dart (93)
- 4 class **MarkdownRichTextRenderer**
  - 5 render
  - 69 _inline
  - 81 _plain
  - 84 _code
  - 89 _escape

### lib/features/books/application/mobi_book_format_parser.dart (259)
- 12 class **MobiBookFormatParser**
  - 16 get formats
  - 19 parse
  - 100 parseCatalog
  - 137 _recordOffsets
  - 149 _record
  - 158 _mobiOffset
  - 170 _title
  - 189 _decompressPalmDoc
  - 223 _decode
  - 228 _htmlToText

### lib/features/books/application/plain_text_rich_renderer.dart (46)
- 4 class **PlainTextRichRenderer**
  - 5 render

### lib/features/books/application/section_tree_editor.dart (175)
- 3 enum **TreeMoveDirection**
- 5 class **SectionTreeEditor**
  - 8 insertAtEndOfParent
  - 36 removeSubtree
  - 46 moveSubtree
  - 88 canMoveToTarget
  - 114 moveToTarget — Moves a complete subtree onto another visible tree item.
  - 160 subtreeIds

### lib/features/books/application/text_document_book_format_parser.dart (260)
- 15 class **TextDocumentBookFormatParser**
  - 19 get formats
  - 26 parse
  - 47 parseCatalog
  - 83 _catalogDocxMetadata
  - 92 _parseDocx
  - 122 _docxParagraphText
  - 137 _docxMetadata
  - 166 _textProject
  - 214 _decodeText
  - 224 _decodeUtf16
  - 236 _decodeRtf

### lib/features/books/application/transient_book_version_repository.dart (45)
- 5 class **TransientBookVersionRepository**
  - 9 list
  - 17 create
  - 37 delete

### lib/features/books/application/workspace_library_editor.dart (138)
- 8 class **WorkspaceLibraryEditor**
  - 9 importedCopy
  - 47 updateSource
  - 60 clearStoredSource
  - 63 updateCollection
  - 71 updateMetadata
  - 76 updateFavorite
  - 82 updateReadingStatus
  - 90 recordReading
  - 95 selectProject
  - 102 removeProject
  - 116 addScanFolder
  - 130 removeScanFolder

### lib/features/books/application/workspace_persistence_coordinator.dart (89)
- 7 class **WorkspacePersistenceCoordinator**
  - 30 get saveState
  - 32 load
  - 34 markChanged
  - 39 scheduleSave
  - 45 flush
  - 69 _cancelTimers
  - 76 _setSaveState
  - 82 _enqueueSave
- 89 typedef **VoidCallback**

### lib/features/books/application/workspace_save_state.dart (1)
- 1 enum **WorkspaceSaveState**

### lib/features/books/application/workspace_version_coordinator.dart (63)
- 5 class **WorkspaceVersionCoordinator**
  - 10 list
  - 13 create
  - 16 delete
  - 19 replaceFromExternalSource

### lib/features/books/application/xml_book_content_converter.dart (411)
- 4 typedef **BookImageResolver**
- 6 class **XmlBookContentConverter**
  - 50 convert
  - 62 _appendChildren — Appends container content: block children as their own blocks, and each run of text and inline elements between them as one paragraph, so...
  - 93 _isInline — Text, or an inline element holding nothing but inline content; a link wrapped around whole blocks still reads as those blocks.
  - 103 _appendNode
  - 203 _directReadableBlocks
  - 210 _appendParagraph — Appends [nodes] as one paragraph whose closing line break carries [blockAttributes]; nothing at all when they hold no readable content.
  - 237 _appendInline
  - 314 _appendImage
  - 341 _trimBlockRuns — Removes the whitespace markup leaves at the edges of the block started at [start] and around its line breaks, then drops runs left empty.
  - 396 _normalized
  - 399 _isVerseContainer

### lib/features/books/application/xml_text_decoder.dart (177)
- 4 class **XmlTextDecoder**
  - 5 decode
  - 26 normalizeEntities
  - 34 _utf16
  - 43 _windows1251

### lib/features/books/data/book_clipboard_image_service.dart (60)
- 6 class **BookClipboardImageService**
  - 11 get _isAndroid
  - 15 hasImage
  - 34 read — Returns null when the clipboard has no image; throws [PlatformException] when an image exists but cannot be read.

### lib/features/books/data/book_device_catalog_factory.dart (2)

### lib/features/books/data/book_device_catalog_factory_io.dart (216)
- 9 fn createBookDeviceCatalog
- 12 class **IoBookDeviceCatalogGateway**
  - 17 get supportsFolderScanning
  - 20 hasDownloadsAccess
  - 26 requestDownloadsAccess
  - 32 scanDownloads
  - 51 chooseFolder
  - 70 scan
  - 83 _scanDirectories
  - 119 materialize
  - 152 releaseFolder
  - 159 availableBytes
  - 164 _candidateFromMap
  - 182 _scanResultFromMap
  - 198 _isBookName
  - 211 _lastSegment

### lib/features/books/data/book_device_catalog_factory_stub.dart (4)
- 3 fn createBookDeviceCatalog

### lib/features/books/data/book_export_file_service.dart (51)
- 6 class **BookExportFileSaver**
  - 7 save
- 13 class **BookExportFileService**
  - 19 save
  - 44 _safeName

### lib/features/books/data/book_image_file_service.dart (32)
- 6 class **BookImageFileService**
  - 16 get _usesPhotoPicker
  - 22 open

### lib/features/books/data/book_import_file_service.dart (141)
- 8 class **BookImportFileGateway**
  - 9 open
- 12 class **BookBatchImportFileGateway**
  - 14 openMany
- 17 class **BookImportFileService**
  - 66 get _acceptedTypes
  - 73 open
  - 84 openMany
  - 101 _normalizedName

### lib/features/books/data/book_pdf_asset_font_loader.dart (19)
- 4 class **BookPdfAssetFontLoader**
  - 8 load
  - 15 _bytes

### lib/features/books/data/book_project_backup_file_service.dart (72)
- 8 class **BookProjectBackupFileGateway**
  - 9 save
  - 11 open
- 14 class **BookProjectBackupFileService**
  - 26 save
  - 53 open
  - 61 _safeName
- 71 fn decodeBackupBytes — A backup as the app writes it: UTF-8, maybe behind a byte order mark.

### lib/features/books/data/book_reader_annotation_file_service.dart (45)
- 8 class **BookReaderAnnotationFileSaver**
  - 9 save
- 15 class **BookReaderAnnotationFileService**
  - 19 save
  - 38 _safeName

### lib/features/books/data/book_source_storage_factory.dart (2)

### lib/features/books/data/book_source_storage_factory_io.dart (8)
- 5 fn createBookSourceStorage

### lib/features/books/data/book_source_storage_factory_stub.dart (4)
- 3 fn createBookSourceStorage

### lib/features/books/data/book_version_repository_factory.dart (2)

### lib/features/books/data/book_version_repository_factory_io.dart (18)
- 8 fn createBookVersionRepository

### lib/features/books/data/book_version_repository_factory_preferences.dart (7)
- 5 fn createBookVersionRepository

### lib/features/books/data/file_author_workspace_repository.dart (161)
- 8 class **FileAuthorWorkspaceRepository**
  - 28 get _primary
  - 29 get _pending
  - 30 get _rollback
  - 31 get _firstBackup
  - 32 get _secondBackup
  - 35 load
  - 59 save
  - 86 _writePending
  - 93 _archiveRollback
  - 111 _backupIsDue
  - 118 _readSnapshot
  - 130 _file
  - 133 _deleteIfExists
- 138 fn _encodeSnapshot
- 146 fn _decodeSnapshot

### lib/features/books/data/file_book_source_storage.dart (256)
- 9 const _processedCacheVersion
- 11 class **FileBookSourceStorage**
  - 17 get _libraryDirectory
  - 20 get _temporaryDirectory
  - 24 store
  - 58 deleteOriginal
  - 65 deleteProjectFiles
  - 78 hasOriginal
  - 84 loadOriginal
  - 97 loadProcessed
  - 116 storeProcessed
  - 138 inspect
  - 169 cleanup
  - 191 _projectDirectory
  - 195 _processedFile
  - 199 _resolveRelative
  - 206 _safeSegment
  - 209 _safeExtension
  - 224 _deleteFileIfExists
  - 228 _deleteDirectoryIfEmpty
- 234 fn _decodeProcessed

### lib/features/books/data/file_book_version_repository.dart (109)
- 8 class **FileBookVersionRepository**
  - 17 list
  - 33 create
  - 66 delete
  - 77 _read
  - 96 _projectDirectory
  - 100 _safeComponent
  - 105 _normalizedLabel

### lib/features/books/data/preferences_author_workspace_repository.dart (67)
- 9 class **PreferencesAuthorWorkspaceRepository**
  - 21 load
  - 38 save
  - 47 _decodeWorkspace
  - 53 _decodeDiary
  - 58 _decodeMap

### lib/features/books/data/preferences_book_version_repository.dart (93)
- 8 class **PreferencesBookVersionRepository**
  - 17 list
  - 25 create
  - 56 delete
  - 66 _readAll
  - 88 _writeAll

### lib/features/books/data/workspace_repository_factory.dart (2)

### lib/features/books/data/workspace_repository_factory_io.dart (20)
- 9 fn createAuthorWorkspaceRepository

### lib/features/books/data/workspace_repository_factory_preferences.dart (7)
- 5 fn createAuthorWorkspaceRepository

### lib/features/books/domain/author_workspace_repository.dart (6)
- 3 class **AuthorWorkspaceRepository**
  - 4 load
  - 5 save

### lib/features/books/domain/author_workspace_snapshot.dart (84)
- 7 class **AuthorWorkspaceSnapshot**
  - 46 get projects
  - 49 get activeProject
- 61 fn _legacyPreferences

### lib/features/books/domain/book_asset.dart (52)
- 4 class **BookAsset**
  - 24 tryFromJson
  - 37 get isRenderableImage

### lib/features/books/domain/book_chapter_heading.dart (13)
- 1 class **BookChapterHeading**
  - 12 isRecognized

### lib/features/books/domain/book_default_titles.dart (71)
- 6 class **BookDefaultTitles** — Names the app gives new books and sections.
  - 9 book
  - 12 firstChapter
  - 15 section
  - 26 localize — [project] with its untouched default names in [languageCode].
  - 45 _localizedSection
  - 62 _translated — [value] in [languageCode] when it is one of the [defaultIn] names.
  - 70 _english

### lib/features/books/domain/book_image_placement.dart (90)
- 5 enum **BookImageAlignment**
- 7 class **BookImagePlacement**
  - 43 fromEmbed — Reads an illustration from a document insert in either embed form.
  - 55 encode
  - 76 alignedTo — Moves the illustration to a side of the page.
  - 86 _int
  - 89 _supportedWidth

### lib/features/books/domain/book_layout_settings.dart (114)
- 4 enum **BookPaperSize**
- 6 enum **BookPageOrientation**
- 8 class **BookLayoutSettings**
  - 53 get pageFormat
  - 89 withUniformMargins
  - 107 _margin
- 113 fn _enumValue

### lib/features/books/domain/book_library_state.dart (110)
- 1 enum **BookReadingStatus**
- 3 class **BookReadingSession**
- 29 class **BookLibraryState**
  - 82 recordReading

### lib/features/books/domain/book_metadata.dart (75)
- 1 class **BookMetadata**

### lib/features/books/domain/book_page_format.dart (82)
- 7 class **BookPageFormat** — Physical manuscript page dimensions converted to Flutter logical pixels.
  - 46 get width
  - 47 get height
  - 48 get marginTop
  - 49 get marginRight
  - 50 get marginBottom
  - 51 get marginLeft
  - 53 scaleForWidth
  - 56 millimetersToLogicalPixels
  - 59 pointsToLogicalPixels

### lib/features/books/domain/book_page_view_mode.dart (1)
- 1 enum **BookPageViewMode**

### lib/features/books/domain/book_paragraph_settings.dart (168)
- 1 enum **BookParagraphPreset**
- 3 class **BookParagraphSettings**
- 117 const bookFontFamilies
- 129 const bookIndentLevelEm — One level of a paragraph's indent, in sizes of the book's text, wherever the book is drawn: the writer, the reader and every export.
- 133 const bookDefaultTextSize — The size the writer gives the text of a new book, 12 pt, in logical pixels.
- 136 const bookFontSizesPt — Text sizes offered by the formatting controls, in points.
- 152 fn _enumValue
- 155 fn _bounded
- 165 fn _fontFamily

### lib/features/books/domain/book_paragraph_style.dart (10)
- 1 enum **BookParagraphStyle**

### lib/features/books/domain/book_plain_text_chunk.dart (134)
- 3 class **BookPlainTextChunk**
- 17 class **BookPlainTextChunker**
  - 22 split
  - 45 _splitRange
  - 72 _chapterHeadingOffsets
  - 82 _splitOffset
  - 102 _nextHeadingBoundary
  - 121 _hasBlankLineBefore
  - 126 _heading

### lib/features/books/domain/book_project.dart (627)
- 19 enum **BookProjectKind**
- 21 class **BookProject**
  - 269 get isReadOnly
  - 270 get isCatalogOnly
  - 272 get sections
  - 275 get assets
  - 277 get sectionTrash
  - 281 get textTrash — Deleted text and pictures, oldest first.
  - 284 get coverAsset
  - 288 assetById
  - 291 get activeSection
  - 294 childrenOf
- 396 const _currentDocumentFormatVersion
- 397 const _automaticLineHeightMigrationVersion
- 399 fn _normalizedProgress
- 405 fn _migrateOversizedPlainTextSections
- 466 const _plainTextSourceFormats
- 468 class **_PlainTextChunkRange**
  - 479 get length
- 482 class **_PlainTextSectionMigration**
  - 491 remapProgress
  - 500 remapAnnotations
  - 563 _point
  - 582 _range
- 608 class **_RemappedPoint**
- 615 class **_RemappedRange**

### lib/features/books/domain/book_project_version.dart (49)
- 3 class **BookProjectVersion**

### lib/features/books/domain/book_reader_annotations.dart (459)
- 1 class **BookReaderBookmark**
- 56 class **BookReaderNote**
- 132 enum **BookReaderHighlightColor**
  - 138 fromJson
- 144 class **BookReaderHighlight**
- 231 class **BookReaderQuote**
- 298 class **BookReaderAnnotations**
  - 360 addBookmark
  - 363 removeBookmark
  - 367 addNote
  - 370 updateNote
  - 374 removeNote
  - 377 addHighlight
  - 389 updateHighlight
  - 396 removeHighlight
  - 400 addQuote
  - 410 removeQuote
  - 413 retainSections
  - 433 _copyWith
- 446 fn _normalized

### lib/features/books/domain/book_reader_progress.dart (42)
- 1 class **BookReaderProgress**
- 38 fn _normalized

### lib/features/books/domain/book_reader_settings.dart (191)
- 1 enum **BookReaderTheme**
- 3 enum **BookReaderViewMode**
- 5 class **BookReaderSettings**
- 170 const bookReaderFontFamilies
- 177 fn _bounded
- 188 fn _readerFontFamily

### lib/features/books/domain/book_reading_progress.dart (49)
- 5 fn bookReadingProgress
- 16 fn bookSectionReadableLengths — Measuring a chapter walks its whole text, so readers that ask for progress repeatedly measure once and pass the lengths back in.
- 19 fn bookReadingProgressForLengths
- 48 fn _readableLength

### lib/features/books/domain/book_scan_folder.dart (13)
- 1 class **BookScanFolder**

### lib/features/books/domain/book_section.dart (122)
- 4 enum **BookSectionType**
- 6 enum **DraftStatus**
- 8 class **BookSection**
- 116 fn _enumValue
- 119 fn _nonNegativeInt

### lib/features/books/domain/book_section_trash.dart (43)
- 3 class **BookSectionTrashEntry**
  - 35 get root

### lib/features/books/domain/book_text_trash.dart (49)
- 4 class **BookTextTrashEntry** — Text or pictures deleted from a chapter, kept so they can be put back.
  - 40 get hasEmbed — Whether the fragment holds a picture or another embedded object.

### lib/features/books/domain/book_version_repository.dart (13)
- 4 class **BookVersionRepository**
  - 5 list
  - 7 create
  - 12 delete

### lib/features/books/domain/book_writing_state.dart (138)
- 1 class **BookWritingSession**
- 28 class **BookWritingState**
  - 59 get totalWritingTimeSeconds
  - 62 wordsForDay
  - 66 get activeDays
  - 71 streakAt
  - 100 record
- 128 fn _nonNegative
- 133 fn _sameDay
- 138 fn _dayKey

### lib/features/books/domain/literia_app_preferences.dart (87)
- 6 enum **LiteriaThemePreference**
- 8 class **LiteriaAppPreferences**
  - 52 get bookScanFolders

### lib/features/books/domain/manuscript_project_statistics.dart (36)
- 4 class **ManuscriptProjectStatistics**

### lib/features/books/domain/manuscript_statistics.dart (45)
- 3 class **ManuscriptStatistics**
  - 41 progressFor

### lib/features/books/domain/rich_document.dart (69)
- 3 typedef **RichDocument**
  - 15 emptyRichDocument
- 18 fn mergeRichDocuments
- 28 fn richDocumentEmbedData — Reads the payload of a [type] embed, stored either directly (`{type: data}`) or wrapped by Quill as `{'custom': '{"type": data}'}`.
- 41 fn richDocumentIsPageBreak
- 44 fn richDocumentPlainText
- 47 fn richDocumentHasContent
- 54 fn withoutLegacyDefaultLineHeight — Removes the line height that older builds wrote into every paragraph.

### lib/features/books/domain/unique_timestamp.dart (11)
- 5 fn uniqueTimestamp — Microseconds of [timestamp], raised past every earlier result, so identifiers made within the same microsecond still differ.

### lib/features/books/legacy/legacy_diary_snapshot.dart (82)
- 1 typedef **LegacyPageDocument**
- 3 class **LegacyDiaryEntry**
  - 38 _emptyPage
  - 42 _pageFromJson
- 52 class **LegacyDiarySnapshot**

### lib/features/books/presentation/author_workspace_page.dart (1424)
- 51 class **AuthorWorkspacePage**
- 73 class **_AuthorWorkspacePageState**
  - 94 didChangeAppLifecycleState
  - 193 _buildCompactWriterTop
  - 271 _buildCompactWriterBottom
  - 318 _compactWriterAction
  - 338 _buildWideWriterStart
  - 438 _buildWideWriterEnd
  - 470 _wideWriterAction
  - 487 _workspaceActionButton
  - 533 _workspaceActionHint — What a tool does, in a few words for someone new to the app.
  - 547 _showWorkspaceTools
  - 601 _handleEditorMetrics
  - 607 _handleWorkspaceAction
  - 628 _handleContentChanged
  - 643 _projectWordCount
  - 679 _showWritingStatistics
  - 694 _toggleFocusMode
  - 704 get _usesPagedLayout — Whether the editor shows sheets: always on a wide screen, and on a phone in the A4 preview.
  - 707 _toggleA4Preview
  - 722 _renameBook
  - 747 _renameSection
  - 773 _showManuscriptSearch
  - 806 _openSearchMatch
  - 813 _handleEditorControllerReady
  - 820 _revealSearchMatch
  - 831 _showManuscript
  - 847 _showWriterSettings
  - 882 _showFormatting
  - 911 get _picksFromGallery
  - 916 _showAddPicture
  - 969 _insertImage
  - 977 _pasteClipboardImage
  - 983 _pasteClipboardImageInto
  - 1007 _insertImageFile
  - 1022 _insertImageAsset
  - 1038 _pickImageAsset
  - 1050 _chooseCover
  - 1059 _showImageSettings
  - 1116 _updateImageInProject
  - 1134 _deleteImageFromProject
  - 1148 _moveImageToCursor
  - 1174 _editActiveSection
  - 1195 _resolveImageOffset
  - 1222 _insertPageBreak
  - 1240 _showExportSheet
  - 1274 _showVersionHistory
  - 1286 _showSectionTrash
  - 1298 _backupProject
  - 1314 _restoreProjectBackup
  - 1353 _exportArtifact
  - 1372 _openPdfPreview
  - 1386 _showMessage
  - 1399 _openReader
- 1424 enum **_PictureSource**

### lib/features/books/presentation/book_export_sheet.dart (137)
- 6 class **BookExportSheet**
- 98 class **_SectionLabel**
- 110 class **_ExportTile**

### lib/features/books/presentation/book_manuscript_search_sheet.dart (169)
- 9 class **BookReplaceRequest**
- 21 class **BookManuscriptSearchSheet**
- 36 class **_BookManuscriptSearchSheetState**

### lib/features/books/presentation/book_paragraph_style_actions.dart (191)
- 10 class **BookParagraphStyleActions**
  - 13 current
  - 33 apply
  - 55 _isQuoteBlock — Whether [style], by its name in a document, is drawn as a quote block.
  - 65 repairQuoteBlocks — Gives the quote mark back to lines of a quote, an epigraph or a poem that lost it while keeping the style's name, as Enter on an empty li...
  - 92 get _clearedBlockAttributes
  - 104 _visualAttributes
  - 124 _insertSceneMarkerIntoEmptyLine
- 150 class **BookQuoteBlockExitRule** — Enter on an empty line at the end of a quote, an epigraph or a poem.
  - 154 applyRule

### lib/features/books/presentation/book_pdf_preview_page.dart (156)
- 12 class **BookPdfPreviewPage**
- 28 class **_BookPdfPreviewPageState**
  - 113 _load
  - 123 _retry
  - 130 _save
  - 144 _showMessage

### lib/features/books/presentation/book_text_colors.dart (21)
- 5 class **BookTextColors** — Colours an author can give to words.
  - 19 hex — [color] as a document stores it, such as `#c62828`.

### lib/features/books/presentation/book_trash_sheet.dart (222)
- 11 enum **_TrashAction**
- 14 class **BookTrashSheet** — Deleted chapters and deleted text of the book, newest first.
- 23 class **_BookTrashSheetState**
  - 69 _sectionEntry
  - 88 _textEntry
  - 120 _when
  - 127 _restore
  - 135 _delete
  - 142 _emptyTrash
  - 149 _confirm
- 170 class **_TrashTile**

### lib/features/books/presentation/book_typography.dart (258)
- 7 class **BookTypography**
  - 15 get titleSize
  - 18 editorStyles
  - 102 textSpanBuilder — Draws the first line of a body paragraph indented by the book's paragraph indent, as the exports do.
  - 166 indentsFirstLine — Whether a line with these attributes is body text whose first line takes the paragraph indent: not a heading, quote, poem or list, and ne...
  - 179 _drawsAlone — Whether the first character can be drawn apart from the rest: a single code unit that no combining mark follows and that is not a line br...
  - 194 _indentWidth — Quill indents a level by one size of the text; the book by [bookIndentLevelEm], so a level looks the same here and in the exports.
  - 216 _textStyle
  - 233 _block

### lib/features/books/presentation/book_version_history_sheet.dart (271)
- 9 enum **_VersionAction**
- 11 class **BookVersionHistorySheet**
- 21 class **_BookVersionHistorySheetState**
  - 31 _reload
  - 126 _createVersion
  - 173 _handleAction
  - 185 _restore
  - 212 _delete
  - 235 _confirm
  - 259 _formattedDate
  - 266 _showMessage

### lib/features/books/presentation/book_writing_statistics_sheet.dart (246)
- 12 class **BookWritingStatisticsSheet** — How much has been written, the details of the book, and the goals, which are kept as soon as they are typed.
- 22 class **_BookWritingStatisticsSheetState**
  - 46 _saveGoals
- 176 class **_Progress** — Words written so far and, when there is a goal, the way to it.
- 214 class **_Metric**

### lib/features/books/presentation/reader/book_reader_annotation_actions.dart (132)
- 6 class **BookReaderAnnotationActions**
  - 15 bookmarkAt — The bookmark on the part of the chapter in sight: from [sectionProgress], the start of the page or screen, up to [visibleEnd], where the ...
  - 64 toggleBookmark — Takes away the bookmark in sight, or puts one at [sectionProgress].
  - 86 addHighlight
  - 102 addQuote
  - 116 excerpt

### lib/features/books/presentation/reader/book_reader_annotation_export_sheet.dart (47)
- 6 class **BookReaderAnnotationExportSheet**

### lib/features/books/presentation/reader/book_reader_annotations_panel.dart (176)
- 8 class **BookReaderAnnotationsPanel**
- 142 class **_Header**
- 154 fn _locationLabel
- 166 const _deleteHighlight
- 168 fn _highlightColorName

### lib/features/books/presentation/reader/book_reader_bookmark_flag.dart (87)
- 6 typedef **BookReaderBookmarkMark** — Where a bookmark stands in the shown text, in display offsets, and its number in the book.
- 10 class **BookReaderBookmarkFlag** — The ribbon of a bookmark on the page, with its number in the book, the same number the list of bookmarks shows.
- 47 class **BookReaderBookmarkFlags** — The flags of [marks] in a row, for the bookmarks in one place.
- 66 class **_RibbonPainter** — A ribbon with a notch cut into its lower end.
  - 72 paint
  - 86 shouldRepaint

### lib/features/books/presentation/reader/book_reader_contents.dart (73)
- 5 class **BookReaderContents**
  - 56 _depthOf
  - 68 _iconFor

### lib/features/books/presentation/reader/book_reader_context_bar.dart (143)
- 5 class **BookReaderContextBar**
- 88 class **_ReaderAction**

### lib/features/books/presentation/reader/book_reader_continuous_view.dart (495)
- 18 class **BookReaderContinuousController** — Reports and changes the reading position of a [BookReaderContinuousView] in display text offsets, independent of how much of the chapter ...
  - 22 get topOffset — Display offset of the text at the top of the viewport.
  - 25 get bottomOffset — Display offset of the text at the bottom of the viewport.
  - 28 reveal — Scrolls [displayOffset] to the top unless it is already on screen.
- 37 class **BookReaderContinuousView** — Scrolling chapter view that builds and paints only the visible blocks, so opening and scrolling cost the same for short and very long cha...
- 99 class **_BookReaderContinuousViewState**
  - 110 get _blocks
  - 142 _blockIndexFor
  - 156 _fractionInBlock
  - 163 _anchorAt
  - 174 _jumpToAnchor
  - 179 _scheduleAnchorCorrection
  - 203 get _viewport
  - 218 _topOffset
  - 240 _bottomOffset
  - 259 _reveal
  - 341 _buildItem
  - 377 _buildBlockContent
  - 409 _fragmentFor
  - 443 _imageHeight
- 451 class **_ContinuousBlockItem** — Registers a built block so the view can find which one is on screen.
- 467 class **_ContinuousBlockItemState**
  - 489 _unregister

### lib/features/books/presentation/reader/book_reader_document_model.dart (348)
- 4 enum **BookReaderBlockType**
- 21 enum **BookReaderTextAlignment**
- 23 class **BookReaderTextRun**
- 57 class **BookReaderBlock**
  - 94 get text
  - 96 _joined
  - 114 get isText
- 122 class **BookReaderDocumentModel**
- 134 class **BookReaderDocumentParser**
  - 135 parse
  - 225 _textRun
  - 249 _embedBlock
  - 281 _joinVerseLines — Marks the lines of each poem, so they are laid out without the spacing that separates paragraphs.
  - 295 _blockType
  - 314 _alignment
  - 322 _fontSize
  - 333 _color
  - 339 _integer
  - 342 _safeLink

### lib/features/books/presentation/reader/book_reader_document_view.dart (469)
- 17 class **BookReaderRenderHighlight**
- 29 class **BookReaderDocumentView**
- 83 class **BookReaderFragmentView**
- 176 class **BookReaderTextFragment**
  - 198 selectSpeechOffset
  - 204 selectRange
- 249 class **_SpeechTargetText** — Plain text that turns a tap into a speech start offset.
- 258 class **_SpeechTargetTextState**
- 297 class **_BookReaderImageFragment**
- 381 fn _styledSpan

### lib/features/books/presentation/reader/book_reader_highlight_style.dart (26)
- 5 class **BookReaderHighlightStyle**
  - 6 displayColor
  - 13 backgroundHex

### lib/features/books/presentation/reader/book_reader_layout_engine.dart (486)
- 11 const bookReaderCursorWidth — Caret width of the selectable reader text.
- 16 const bookReaderCaretReserve — Room [SelectableText] keeps free at the end of every line for its caret: the cursor plus a fixed 1 px gap.
- 18 class **BookReaderPageMetrics**
  - 63 get contentWidth
  - 66 get contentHeight
- 71 class **BookReaderBlockSlice**
  - 92 get startsBlock
  - 93 get endsBlock
  - 95 get sourceStart
  - 98 get sourceEnd
- 102 class **BookReaderPageLayout**
- 116 class **BookReaderLayoutEngine** — Caches paginations per document, settings, and page geometry.
  - 120 paginate
  - 153 clear
- 157 class **BookReaderPagination** — Pages of one chapter, laid out block by block on demand.
  - 179 get isComplete
  - 182 covers — Whether the page holding [displayOffset] is final.
  - 211 _finishPage
  - 224 _layoutBlock
  - 388 _textPainter
  - 407 _embedHeight
- 419 fn textSpanForRange
- 453 class **_BookReaderLayoutCacheKey**

### lib/features/books/presentation/reader/book_reader_location_callback.dart (2)
- 1 typedef **BookReaderLocationCallback**

### lib/features/books/presentation/reader/book_reader_navigation_panel.dart (336)
- 12 class **BookReaderNavigationPanel**
- 147 fn _readerTab
- 155 class **_BookmarksList**
- 213 class **_NotesList**
- 302 class **_EmptyReaderList**
- 324 fn _locationLabel
- 336 enum **_NoteAction**

### lib/features/books/presentation/reader/book_reader_note_dialog.dart (62)
- 5 class **BookReaderNoteDialog**
- 14 class **_BookReaderNoteDialogState**

### lib/features/books/presentation/reader/book_reader_page.dart (1351)
- 36 const _compactTopPanelHeight
- 37 const _compactBottomPanelHeight
- 39 class **BookReaderPage**
- 67 class **_BookReaderPageState**
  - 98 get _sections
  - 99 get _section
  - 100 get _sectionText
  - 102 _textOf
  - 137 _goToLocation
  - 163 _saveProgress
  - 170 _saveSessionAfterPop
  - 181 _handleSectionProgress
  - 188 get _overallProgress
  - 314 _moveReaderForward
  - 317 _moveReaderBackward
  - 320 _handleReaderEscape
  - 328 _showChapterTransition
  - 344 _buildCompactReaderTop
  - 400 _buildCompactReaderBottom
  - 454 _compactReaderAction
  - 476 _buildWideReaderStart
  - 562 _buildWideReaderEnd
  - 592 _wideReaderAction
  - 609 get _speechIcon
  - 617 _speechLabel
  - 626 _speechShortLabel — The same state in a word that fits the phone's bottom bar.
  - 634 _toggleFocusMode
  - 640 _handleUserNavigation — Reading hides the floating panels so they never cover the text.
  - 647 _readingInsets — Space the floating panels cover on a phone.
  - 655 _toggleSpeech
  - 668 _configureSpeechForSection
  - 676 _prepareSpeechSegments
  - 685 _handleSpeechTargetSelected
  - 692 _startSpeechAt
  - 711 _speakNextSegment
  - 730 _handleSpeechProgress
  - 751 _handleSpeechCompleted
  - 761 _continueSpeechInNextReadableSection
  - 788 _pauseOrResumeSpeech
  - 799 _stopSpeech
  - 816 _cancelSpeechTargetSelection
  - 821 _handleSpeechError
  - 835 _changeSpeechRate
  - 841 _applyReaderSettings
  - 852 _refreshSpeechAfterSettingsChange
  - 892 _buildReadingSurface
  - 1035 _resetSurfaceTap
  - 1041 _handleReadingSurfaceTap
  - 1048 get _currentBookmark
  - 1056 _navigationPanel
  - 1083 _goToNextSection
  - 1090 _goToPreviousSectionEnd
  - 1095 _showContents
  - 1106 _showSearch
  - 1123 _showSettings
  - 1134 _goToSearchResult
  - 1137 _toggleBookmark
  - 1148 _updateAnnotations
  - 1153 _handleTextSelection
  - 1158 _clearTextSelection
  - 1166 _saveHighlight
  - 1181 _saveQuote
  - 1195 _copySelection
  - 1204 _openSelectionLookup
  - 1222 _addNoteForSelection
  - 1240 _showAnnotationExport
  - 1253 _exportAnnotations
  - 1275 _showMessage
  - 1288 _currentExcerpt
  - 1293 _addNote
  - 1308 _editNote
  - 1321 _showNoteEditor
- 1331 class **_TypefaceIcon** — "Aa" drawn in an icon's box, so its label lines up with the other actions.

### lib/features/books/presentation/reader/book_reader_page_card.dart (128)
- 11 class **BookReaderPageCard**
  - 75 _buildPage

### lib/features/books/presentation/reader/book_reader_page_stage.dart (224)
- 7 class **BookReaderPageStage**
- 67 class **_ReaderPagedInput**
- 84 class **_ReaderPagedInputState**
  - 91 _move
  - 111 _handlePointerSignal
  - 120 _handlePointerDown
  - 127 _handlePointerMove
  - 138 _handlePointerUp
  - 158 _handlePointerCancel

### lib/features/books/presentation/reader/book_reader_palette.dart (85)
- 4 class **BookReaderPalette**
  - 48 themeData

### lib/features/books/presentation/reader/book_reader_progress_rail.dart (46)
- 3 class **BookReaderProgressRail**

### lib/features/books/presentation/reader/book_reader_search_sheet.dart (133)
- 6 class **BookReaderSearchSheet**
- 20 class **_BookReaderSearchSheetState**
  - 24 _search
- 113 class **_SearchMessage**

### lib/features/books/presentation/reader/book_reader_section_continuous.dart (147)
- 3 extension **_BookReaderContinuousFlow**
  - 4 _buildContinuousView
  - 31 _handleContinuousScroll
  - 46 _reportContinuousProgress — Progress is the share of the chapter text above the viewport, the same measure the paged view uses, so switching modes keeps the place.
  - 72 _handleContinuousPointerMove
  - 82 _handleContinuousPointerSignal
  - 94 _maybeNavigateAtContinuousBoundary
  - 106 _handleContinuousPointerDown
  - 120 _handleContinuousPointerUp
  - 136 _resetContinuousPointer
  - 145 _restoreContinuousPosition

### lib/features/books/presentation/reader/book_reader_section_document.dart (72)
- 3 extension **_BookReaderDocumentFlow**
  - 6 get _renderHighlights — Resolving an anchor scans the chapter text, so the result is kept until the highlights or the displayed text change.
  - 33 get _renderSpeechRange
  - 42 _selectSpeechTarget
  - 49 _handleDisplaySelection
  - 68 _clearSelection

### lib/features/books/presentation/reader/book_reader_section_pagination.dart (240)
- 4 const _foregroundPaginationBudget — Layout time allowed inside a frame when a page must appear right away.
- 7 const _backgroundPaginationBudget — Layout time per background slice; frames still render between slices.
- 9 extension **_BookReaderPaginationFlow**
  - 10 _buildPagedView
  - 44 _buildPage
  - 66 _ensurePagination
  - 87 _advanceToPendingPage — Lays out pages up to the reading position and shows it once ready.
  - 103 _schedulePaginationSlice
  - 127 _selectPage
  - 142 _selectPageForProgress
  - 174 _hasPage — Makes sure [page] is laid out; the turn is skipped while it is not.
  - 186 _invalidatePagination
  - 192 _clearVisiblePages
- 198 class **_ReaderPageGeometry**

### lib/features/books/presentation/reader/book_reader_section_view.dart (387)
- 28 class **BookReaderSectionController**
  - 31 moveForward
  - 33 moveBackward
  - 37 get visibleEnd — Where the part of the chapter in sight ends, as a share of the chapter like the reading progress; null while it is not known yet.
  - 39 _attach
  - 41 _detach
- 46 class **BookReaderSectionView**
- 100 class **_BookReaderSectionViewState**
  - 117 get _pages
  - 147 _readDisplayDocument
  - 154 _displayOffsetFor — Display offset of [progress], the measure both view modes report.
  - 200 _scheduleHyphenation
  - 233 _layoutSettingsChanged
  - 279 get _bookmarkMarks
  - 286 _visibleEndProgress — The start of the next page, or the text at the bottom of the screen, as a share of the chapter; 1 once the end of the chapter is in sight.
  - 307 _modeForWidth
  - 314 _restoreCurrentPosition
  - 325 _moveByNavigation
  - 365 _requestSectionNavigation
  - 376 _mutate

### lib/features/books/presentation/reader/book_reader_selection_bar.dart (119)
- 7 class **BookReaderSelectionBar**
- 111 fn _highlightColorName

### lib/features/books/presentation/reader/book_reader_selection_resolver.dart (41)
- 6 class **BookReaderSelectionResolver**
  - 9 resolve

### lib/features/books/presentation/reader/book_reader_settings_sheet.dart (368)
- 11 class **BookReaderSettingsSheet** — The reading settings: how the book looks, its text and margins, the gestures, and reading aloud.
- 26 class **_BookReaderSettingsSheetState**

### lib/features/books/presentation/reader/book_reader_soft_hyphens.dart (128)
- 4 const _softHyphen
- 8 const bookReaderHyphenReserve — The room left at the end of every line of hyphenated text, where a hyphen hangs when a word breaks there, as a share of the font size.
- 11 typedef **BookReaderHyphenBreak** — A line of [painter] that ends by breaking a word at a soft hyphen.
- 40 class **BookReaderSoftHyphens** — Draws the hyphen where a line ends at a soft hyphen.
- 70 class **_SoftHyphenPainter**
  - 84 paint
  - 114 _styleAt — The style of the letters the hyphen follows, less any highlight.
  - 124 shouldRepaint

### lib/features/books/presentation/reader/book_reader_speech_controls.dart (113)
- 4 class **BookReaderSpeechControls**

### lib/features/books/presentation/reader/book_reader_text_selection.dart (13)
- 1 class **BookReaderTextSelection**

### lib/features/books/presentation/reader/book_reader_typography.dart (224)
- 8 class **BookReaderBlockTypography**
- 35 class **BookReaderTypography**
  - 36 block
  - 159 run — The style of [run] within a block of [typography].
  - 191 color
  - 195 _legible — [color] brought closer to white on a dark page, or to black on a light one, until it reads well; the page is judged by its [on] ink colour.
  - 208 _fontWeight
  - 216 _color

### lib/features/books/presentation/widgets/book_adaptive_control_shell.dart (820)
- 6 const bookControlBreakpoint
- 8 class **BookLeatherColors**
- 21 fn bookStatusBarStyle — Status bar icons that stay readable over a [background] of this brightness.
- 31 class **BookAdaptiveControlShell**
  - 67 _buildInline
  - 119 _buildOverlay
- 228 class **_RevealedPanel** — Slides a panel in and out and leaves the tree once it is hidden, so a hidden panel neither takes taps nor reaches screen readers.
- 245 class **_RevealedPanelState**
- 286 class **BookLeatherPanel**
- 353 class **LiteriaLeatherAppBar**
  - 369 get preferredSize
- 387 class **LiteriaParchmentBackground**
- 411 class **LiteriaLeatherCard**
- 452 class **LiteriaCompactActionTile**
- 542 class **BookPanelAction**
  - 560 _buildLabel
- 631 class **BookPanelIconAction**
- 652 class **BookPanelSectionLabel**
- 676 class **BookWholeWordsText** — A short label that never breaks a word in the middle, as «Оформлен-ие»: when its longest word is wider than the room, the whole label get...
  - 707 _fitted
- 733 class **BookPanelTitleAction**
- 796 class **_LeatherStitchPainter**
  - 800 paint
  - 819 shouldRepaint

### lib/features/books/presentation/widgets/book_cover_view.dart (73)
- 5 class **BookCoverView**

### lib/features/books/presentation/widgets/book_editor_context_menu.dart (418)
- 18 class **BookEditorContextMenu** — The menu of selected words in the editor: the regular copy and paste menu above the words, with "Paste image" when the clipboard holds a ...
- 34 class **_BookEditorContextMenuState**
  - 46 get _canFormat
- 114 class **_BelowSelectionLayout** — Places the formatting bar right below the selected words, clear of the selection handles and of the copy menu, which drops below the word...
  - 136 getConstraintsForChild
  - 145 getPositionForChild
  - 166 shouldRelayout
- 177 class **BookSelectionBarTrigger** — On a computer, shows the formatting bar as soon as words are selected with the mouse, by dragging or a double click, as a phone shows it ...
- 192 class **BookSelectionBarTriggerState**
  - 198 get _computer
  - 207 _pointerDown
  - 214 _pointerUp
- 243 class **BookSelectionFormattingBar** — Bold, italic, underlined, struck through, the colour of the selected words and clearing them, so that they need not open the formatting s...
- 253 class **_BookSelectionFormattingBarState**
  - 257 _toggle
  - 268 _clear — Takes away the formatting of the words, not of their paragraph.
  - 280 _color
  - 307 _buttons
  - 346 _palette
- 382 class **_BarButton**

### lib/features/books/presentation/widgets/book_editor_metrics.dart (22)
- 1 class **BookEditorMetrics**

### lib/features/books/presentation/widgets/book_editor_page_stage.dart (142)
- 7 class **BookEditorPageStage**

### lib/features/books/presentation/widgets/book_empty_state.dart (51)
- 5 class **BookEmptyState** — What an empty list is for, so that a newcomer knows what will appear there and how.

### lib/features/books/presentation/widgets/book_focus_mode_bar.dart (47)
- 7 class **BookFocusModeBar**

### lib/features/books/presentation/widgets/book_formatting_sheet.dart (305)
- 18 class **BookFormattingSheet** — The formatting sheet of the writer.
  - 34 get _buttons
  - 41 _applying — Applies a change to the text and hides the sheet.
- 222 class **_FormattingDropdown** — A drop-down that follows the formatting at the cursor.
- 253 class **_EvenToolbarRow**
- 269 fn _currentFontFamily
- 283 fn _currentFontSize
- 302 fn _nearest

### lib/features/books/presentation/widgets/book_image_editing_scope.dart (208)
- 10 typedef **BookImageTapCallback**
- 17 typedef **BookImagePasteCallback**
- 20 typedef **BookImageFileInsertCallback**
- 25 class **BookImageSelection** — Tracks which illustration is selected for on-page editing.
  - 33 isSelected
  - 36 isAttached
  - 41 attach — Starts watching [controller] so that typing or moving the cursor drops the illustration selection.
  - 62 detach
  - 72 swallowEditorTap — Called when an illustration handles a tap.
  - 77 takeEditorTap
  - 83 select
  - 91 clear
  - 100 edit — Applies an edit made by the illustration controls.
- 129 class **BookImageEditingScope** — Provides illustration editing services to the editors and embeds below it.
  - 146 maybeOf
  - 158 contentInsertionFor — Accepts images committed by the keyboard, such as Gboard's clipboard strip, stickers, and GIFs.
  - 175 handleEditorTapUp — Passed to `QuillEditorConfig.onTapUp`; returns true to make Quill ignore a tap that an illustration has already handled.
  - 180 get contextMenuBuilder
  - 192 updateShouldNotify
- 202 fn bookClipboardPrefersImage — Keyboard shortcut helper shared by the editors: whether an image paste should take precedence over the regular text paste.

### lib/features/books/presentation/widgets/book_image_embed_builder.dart (780)
- 14 class **BookImageEmbedBuilder**
  - 24 get key
  - 27 toPlainText
- 61 class **BookImageEmbedView**
- 85 class **_BookImageEmbedViewState**
  - 106 get _selection
  - 107 get _offset
  - 108 get _selected
  - 141 _buildLayout
  - 200 _buildImage
  - 224 _buildInteractiveImage
  - 284 _buildResizeHandle
  - 323 _buildToolbarOverlay
  - 362 _spaceAboveRow — Free space between the top of the scroll viewport and this illustration.
  - 373 _select
  - 381 _keepKeyboardClosed — Quill handles a tap even after the embed has won it, moving the cursor and opening the keyboard over the page; ask the editor to skip it.
  - 383 _openSettings
  - 389 _apply
  - 400 _delete
  - 411 _startResize
  - 416 _updateResize
  - 424 _updatePinch
  - 429 _setPreview
  - 439 _commitResize
  - 448 _startDrag
  - 467 _updateDrag
  - 473 _dropImage
  - 485 _finishDrag
  - 502 _updateDropTarget — Finds the paragraph boundary nearest to the finger: the illustration is dropped either before or after the paragraph under the pointer.
  - 531 _autoScrollTick
  - 557 _buildDragOverlay
- 621 class **_PercentBadge**
- 647 class **_ImageToolbar**
  - 751 _divider
  - 760 _tool

### lib/features/books/presentation/widgets/book_image_settings_sheet.dart (219)
- 7 enum **BookImageSettingsAction**
- 9 class **BookImageSettingsSheet**
- 25 class **_BookImageSettingsSheetState**
  - 39 _update
  - 45 _updateFromControl
  - 50 _releaseCaptionFocus
  - 54 _replace

### lib/features/books/presentation/widgets/book_leather_modal.dart (288)
- 4 const bookModalGrid
- 5 const bookModalRadius
- 7 fn showBookLeatherBottomSheet
- 30 class **BookLeatherModalSurface**
- 54 class **BookLeatherModalHeader**
- 119 class **BookLeatherDialog**
- 174 fn bookLeatherModalTheme

### lib/features/books/presentation/widgets/book_metadata_editor_dialog.dart (113)
- 6 class **BookMetadataEditorDialog**
- 16 class **_BookMetadataEditorDialogState**
  - 77 _field
  - 97 _save

### lib/features/books/presentation/widgets/book_mobile_editor.dart (122)
- 14 class **BookMobileEditor**

### lib/features/books/presentation/widgets/book_navigator.dart (268)
- 9 class **BookNavigator**
  - 116 _handleSectionAction
  - 155 _depthOf
- 170 class **_SectionTile**
  - 214 _tile
- 262 fn _sectionIcon
- 268 enum **_SectionAction**

### lib/features/books/presentation/widgets/book_page_break_embed_builder.dart (40)
- 5 class **BookPageBreakEmbedBuilder**
  - 11 get key
  - 14 toPlainText

### lib/features/books/presentation/widgets/book_page_canvas.dart (195)
- 14 class **BookPageCanvas**
  - 50 get _isFirstPage

### lib/features/books/presentation/widgets/book_page_settings_section.dart (186)
- 10 class **BookPageSettingsSection** — How the pages of the manuscript look: the A4 preview, how the sheets are shown, their orientation and margins.
  - 37 _buildSettings
  - 172 _update
  - 177 _uniformMarginPreset

### lib/features/books/presentation/widgets/book_paragraph_settings_section.dart (148)
- 9 class **BookParagraphSettingsSection** — The text settings of the whole manuscript: every value is a compact drop-down, and the three paragraph spacings share one line.
  - 136 _update
  - 141 _presetLabel

### lib/features/books/presentation/widgets/book_paragraph_style_selector.dart (52)
- 8 class **BookParagraphStyleSelector**
  - 41 _label

### lib/features/books/presentation/widgets/book_properties_panel.dart (269)
- 12 class **BookPropertiesPanel** — The settings of a manuscript: what the book is, how its pages look, and the progress of the chapter being written.
  - 144 _updateMetadata
  - 161 _statusLabel
- 171 fn _denseDecoration — The outlined field of the settings sheets, as low as their drop-downs.
- 178 class **_CoverSettings**
- 244 class **_PropertyField**

### lib/features/books/presentation/widgets/book_rename_title_dialog.dart (77)
- 5 class **BookRenameTitleDialog**
- 25 class **_BookRenameTitleDialogState**
  - 73 _submit

### lib/features/books/presentation/widgets/book_save_status.dart (82)
- 5 class **BookSaveStatus**

### lib/features/books/presentation/widgets/book_section_editor.dart (748)
- 23 class **BookSectionEditor**
- 69 class **BookSectionEditorState**
  - 100 get controller
  - 101 get pageCount
  - 103 suspendTextInputFocus
  - 111 resumeTextInputFocus
  - 172 _collapseToMobileDocument
  - 184 _createPageControllers
  - 232 _pasteClipboardImage — Runs before Quill's own paste handling; a picture wins only when the clipboard holds no text.
  - 241 _handleDocumentChanged
  - 256 didChangeMetrics — The keyboard came up or the screen turned: the caret may now be hidden.
  - 261 _revealCaret — Keeps the caret of the page being written in sight, also above the keyboard.
  - 279 _activatePage
  - 287 get _pageDocuments
  - 297 _schedulePagination
  - 308 _beginPaginationMeasurement
  - 314 _installMeasurementDocument
  - 340 _measureCurrentDocument
  - 400 _finishPaginationMeasurement
  - 426 _selectPage
  - 433 revealTextRange
  - 451 _globalSelectionOffset
  - 478 _pageContentLength
  - 481 _documentLength
  - 490 _hasSoftPageBreak
  - 527 _disposeMeasurementResourcesAfterFrame
  - 558 _buildEditors
  - 580 _scheduleMetricsNotification
  - 595 _buildPagedEditorWithMeasurement
  - 630 _buildPagedEditor
  - 646 _buildContinuousPages
  - 665 _buildSinglePage
  - 681 _buildPageSpread
  - 699 _buildPage
  - 731 _disposePageControllers

### lib/features/books/presentation/widgets/book_settings_controls.dart (276)
- 8 class **BookSettingsCard** — A section of a settings sheet: a card with a title and, when the title alone may puzzle a newcomer, a one-line hint.
- 70 class **BookSettingsRow** — Settings side by side, equally wide unless [flex] gives each its share, as for a long name beside short ones.
- 88 class **BookCompactChoice** — A choice between two or three options that are all shown at once.
- 148 class **BookSettingSwitch** — An on-off setting with a short name and, if needed, a hint below it.
- 183 class **BookCompactDropdown** — A small outlined drop-down with its name in the border, so that several settings fit on one line of the formatting sheet.
- 253 fn bookNumberChoices — The choices of a numeric setting plus its current value when that is not one of them, as a value typed in an older version.
- 264 fn bookNamedChoices — Named choices of a numeric setting, such as narrow or wide margins, plus its current value under [fallback] when that is none of them.
- 274 fn bookSettingNumber — Formats a setting without trailing zeros: 1, 1.15, 12.7.

### lib/features/books/presentation/widgets/book_sheet_keyboard_dismiss.dart (19)
- 5 class **BookSheetKeyboardDismiss** — Gives every modal book panel the same desktop escape-key behavior.

### lib/features/books/presentation/widgets/book_text_color_menu.dart (93)
- 7 fn bookTextColorAt — The colour of the words at the cursor as `#rrggbb`, or empty for text without a colour of its own.
- 17 fn applyBookTextColor — Colours the selected words; an empty [hex] takes their colour away.
- 21 fn bookTextColorOf — [hex] as a colour, or null for text without a colour of its own.
- 25 class **BookTextColorSwatch**
- 47 class **BookTextColorIcon** — The sign of a colour button: a letter with a bar below it in the colour of the words, or in a rainbow while they have none, so that the b...

### lib/features/books/presentation/widgets/book_workspace_action.dart (15)
- 3 enum **BookWorkspaceAction** — The less frequent writer tools: the book's own tools first, then those that keep the text safe.
  - 14 get keepsTextSafe — Whether this tool keeps the text safe rather than works on the book.

### lib/main.dart (52)
- 14 fn main

## test/ — какой тест что проверяет

### test/app_smoke_test.dart
- 10 opens the new home without creating a test manuscript
- 31 new writer and reader never show legacy navigation

### test/author_studio_autosave_test.dart
- 10 flushes pending text when the app leaves the foreground

### test/author_workspace_adaptive_layout_scenarios.dart
- 4 shows manuscript and properties on desktop
- 63 shows chapter title only in explicit A4 preview
- 110 shows compact bottom navigation on mobile
- 314 groups writer formatting into a compact mobile grid
- 374 groups manuscript settings into compact mobile cards

### test/author_workspace_adaptive_workflow_scenarios.dart
- 4 renames a manuscript by tapping its title
- 33 renames and starts a chapter without a large mobile field
- 77 finds and replaces text across a mobile manuscript
- 120 inserts an image into a mobile manuscript
- 279 inserts consecutive images at the text cursor
- 338 uploads and removes a manuscript cover
- 380 inserts a page break without deleting selected text
- 423 imports an FB2 as a catalog card and opens it on demand
- 483 exports the active project as EPUB
- 513 exports the active project as DOCX
- 543 shows every export group and creates an archived FB2
- 583 opens PDF preview and reports generation errors
- 616 creates a named snapshot from the project data menu
- 647 exports and safely restores a portable project backup
- 687 refreshes the editor content after version restore

### test/author_workspace_controller_test.dart
- 61 creates a book and persists chapter and scene hierarchy
- 76 default titles follow the interface language until renamed
- 121 persists the selected page orientation with the book
- 139 persists a section word target and reports save state
- 158 saves during uninterrupted typing before the idle delay
- 186 reports a save error and succeeds when retried
- 209 replaces text across the manuscript and persists the result
- 234 persists project paragraph settings
- 249 removes reader locations that belong to a deleted section
- 278 serializes saves so an older write cannot win a race
- 306 restores a version and first saves the replaced state
- 334 creates an automatic checkpoint before deleting a section
- 350 imports a backup under the current project identity
- 367 a restored backup brings its pictures and cover
- 398 persists imported books but blocks authoring changes
- 447 a bookmark made while reading is written soon

### test/book_additional_exporters_test.dart
- 16 **additional book exporters**
- 17 creates well-formed FB2 with metadata and nested content sections
- 42 creates a readable FB2.ZIP archive containing one FB2 document
- 56 creates standalone responsive HTML with escaped project data
- 71 creates structured Markdown and formatting-free UTF-8 text
- 91 hides body chapter headings but keeps navigation metadata

### test/book_deleted_text_test.dart
- 18 **BookDeletedText**
- 19 keeps a deleted word with its formatting and place
- 38 ignores an erased letter, a typo fix and part of a word
- 53 keeps a deleted picture
- 63 keeps what a replacement took out, not what it put in
- 72 puts a fragment back where it was, or at the end
- 99 **text trash**
- 136 the trash keeps only the newest fragments

### test/book_docx_exporter_test.dart
- 15 creates an editable WordprocessingML package with book structure
- 89 keeps TOC text while hiding chapter heading paragraphs
- 111 indents first lines and levels as the writer draws them

### test/book_epub_exporter_test.dart
- 12 creates a portable EPUB 3 archive with metadata and reading order
- 63 keeps a chapter in navigation when its body title is hidden

### test/book_export_file_service_test.dart
- 18 uses the native Android document saver for exported books

### test/book_formatting_sheet_test.dart
- 27 formatting goes from the words to the whole book
- 59 formatting leaves out tools a book does not need
- 97 the whole book spacings are drop-downs on one line
- 134 a paragraph change hides the sheet to show the text

### test/book_image_document_editing_test.dart
- 20 moving a full-width picture aside narrows it so the move shows
- 33 inserts an illustration on its own line in the middle of text
- 49 inserting at the end of a paragraph adds no blank line
- 61 replaces placement data in place
- 79 removes the illustration line without leaving a blank paragraph
- 93 moves an illustration up and down between paragraphs
- 115 moving onto its own line is a no-op and undo restores a move
- 133 reads legacy custom embed payloads

### test/book_image_inline_editing_test.dart
- 90 tapping an illustration selects it without the keyboard
- 113 a full-width picture moves to the side it is aligned to
- 138 inline tools align, resize, and delete into the trash
- 177 dragging a corner handle resizes the illustration
- 204 long press drags the illustration to another paragraph
- 234 pastes a clipboard picture from the picture sheet
- 260 reports an empty clipboard instead of pasting nothing
- 275 the paste command inserts a picture when there is no text

### test/book_image_pipeline_test.dart
- 18 validates supported image bytes instead of trusting the extension
- 34 parses both authored and imported image embeds
- 66 keeps smooth illustration widths within a usable range
- 76 embeds manuscript images in EPUB, FB2, and HTML exports

### test/book_import_additional_formats_test.dart
- 11 imports UTF-8 and UTF-16 plain text
- 33 splits short TXT books by visible chapter headings
- 54 imports RTF paragraphs and Unicode escapes
- 70 splits short RTF books by visible chapter headings
- 89 imports DOCX text and core metadata
- 122 splits short DOCX books by visible chapter headings
- 148 imports unencrypted PalmDOC MOBI content
- 161 splits flat MOBI content by visible chapter headings

### test/book_import_parser_test.dart
- 21 **BookImportParser**
- 22 imports the representative FB2 fixture used for visual checks
- 46 imports an exported FB2 as a read-only book with rich text
- 82 imports FB2.ZIP and restores the archived source format
- 95 decodes legacy Windows-1251 FB2 files
- 111 splits a flat FB2 by visible chapter-heading paragraphs
- 159 imports EPUB metadata and spine content in reading order
- 180 reopens every readable format exported by Literia
- 208 uses EPUB navigation labels when page titles are repeated
- 220 splits chapters stored in one flat EPUB document
- 241 imports an EPUB cover and relative inline images
- 259 keeps a supported image-only FB2 section
- 276 rejects unsupported and textless book files with clear reasons
- 313 persists imported-book identity through project serialization
- 332 ignores scripts and unsafe links in imported markup
- 350 keeps a link inside the paragraph around it
- 364 adds no empty paragraphs for whitespace between blocks
- 374 keeps a heading with a line break in one styled block
- 392 reads a link wrapped around blocks as those blocks
- 403 keeps imported verse lines compact inside one paragraph

### test/book_import_storage_test.dart
- 27 imports a private source copy and skips a content duplicate
- 61 deleting only the original keeps processed book data
- 136 rolls back the import when the workspace cannot be saved
- 161 cleanup removes orphaned and temporary source directories

### test/book_large_project_stress_test.dart
- 19 searches and serializes a million-character manuscript
- 35 splits and merges a very long chapter without data loss
- 56 imports a large FB2 and keeps every generated chapter
- 78 round-trips several megabytes of embedded image data

### test/book_layout_settings_test.dart
- 6 defaults old books to portrait A4
- 17 persists landscape orientation and margins
- 34 applies a uniform margin preset without changing orientation

### test/book_library_query_test.dart
- 9 library query searches filters collections and sorts books

### test/book_library_state_test.dart
- 5 records bounded reading sessions and preserves old payloads
- 33 zero-length visit updates last read without a fake history item

### test/book_manuscript_search_test.dart
- 9 finds case-insensitive matches across every manuscript section
- 26 replaces all matches without losing unrelated rich formatting

### test/book_page_break_export_test.dart
- 20 parses a page break without creating an empty paragraph
- 30 preserves page breaks in ebook and text-oriented exports
- 43 turns a manuscript page break into a PDF page boundary

### test/book_page_format_test.dart
- 5 A4 landscape keeps physical proportions at 96 DPI
- 15 A4 portrait swaps physical sides without changing the paper
- 23 typographic points convert independently from page zoom
- 28 page stays at 100 percent when enough width is available

### test/book_page_paginator_test.dart
- 5 visual page split does not add a paragraph break when merged
- 20 keeps real paragraph ending at a page boundary
- 31 honors and preserves an author-inserted page break
- 49 does not apply a page break that is below measured content

### test/book_pagination_measurement_test.dart
- 5 collects pages until the remaining document fits
- 27 bounds render retries for a measurement pass

### test/book_pagination_widget_test.dart
- 19 flows a chapter across A4 pages without losing content
- 97 the sheets scroll to the caret, as above a keyboard

### test/book_panel_layout_test.dart
- 7 a side panel grows by the cutout on its side
- 34 a long word gets smaller instead of breaking apart
- 66 words that fit keep their size and wrap between words

### test/book_panel_semantics_test.dart
- 6 panel controls announce their label once and stay tappable

### test/book_paragraph_settings_test.dart
- 5 classic preset has book-oriented paragraph measurements
- 17 custom values round-trip and remain within safe bounds
- 37 unknown fonts fall back to Georgia

### test/book_paragraph_style_actions_test.dart
- 8 applies and replaces semantic paragraph styles
- 60 sets every selected line of a poem as verse
- 92 inserts and marks a scene divider on an empty line
- 119 keeps semantic style after document serialization

### test/book_pdf_exporter_test.dart
- 33 uses the project paper orientation and physical margins

### test/book_project_archive_codec_test.dart
- 6 round-trips a complete book project
- 22 rejects unrelated and unsupported archives

### test/book_project_backup_file_service_test.dart
- 8 a backup is read as UTF-8, so Russian titles survive
- 17 a byte order mark before the backup is dropped

### test/book_project_test.dart
- 10 book project round-trips metadata and section hierarchy
- 115 invalid active section falls back to the first section
- 136 catalog-only imported book keeps its invisible resume position
- 152 old projects preserve the former paragraph appearance
- 174 migrates automatic line height only for old document versions

### test/book_reader_annotation_actions_test.dart
- 15 adds and removes a bookmark on the page in sight
- 36 the next page takes a bookmark of its own
- 71 creates a highlight and quote from the same selection

### test/book_reader_annotation_exporter_test.dart
- 9 exports portable Markdown and structured JSON annotations

### test/book_reader_annotations_test.dart
- 5 reader annotations round-trip and keep valid locations
- 55 reader annotations add, edit and remove immutable entries
- 85 a new overlapping highlight replaces the old color range

### test/book_reader_external_lookup_test.dart
- 5 builds encoded dictionary translation and search links

### test/book_reader_hyphenation_test.dart
- 8 Russian hyphenation preserves original text and offsets
- 31 Identity display keeps rich document and offset lengths unchanged
- 53 English hyphenation keeps an existing soft hyphen stable
- 75 background hyphenation preserves the synchronous result

### test/book_reader_page_test.dart
- 20 contents distinguishes repeated legacy chapter titles
- 55 reader opens with contents and keeps independent settings
- 218 reader uses compact contents action on a phone

### test/book_reader_paged_view_test.dart
- 17 single page mode paginates a long chapter and keeps progress
- 73 a page slot holds every line its paragraph renders
- 117 spread shows two consecutive pages on a wide screen
- 146 spread automatically becomes one page on a phone
- 168 each page of a long chapter keeps a bookmark of its own
- 230 the continuous text shows a bookmark as a numbered ribbon
- 263 a page on a phone stands between the floating panels
- 293 paged reader stays usable in compact landscape constraints
- 318 next chapter appears without a pagination placeholder
- 368 last reader page continues with the next chapter
- 411 continuous reader advances after scrolling to chapter end
- 450 continuous reader swipes between short chapters
- 500 desktop keyboard crosses chapter boundaries

### test/book_reader_search_test.dart
- 6 search finds all case-insensitive matches across book sections
- 40 search ignores short queries and respects the result limit
- 56 search includes matching section titles

### test/book_reader_selection_resolver_test.dart
- 6 maps a local page selection to the whole chapter
- 20 trims whitespace without producing an empty selection

### test/book_reader_settings_sheet_test.dart
- 8 spread choice is hidden on a portrait phone
- 34 spread choice remains available on a wide screen
- 60 text size and named choices apply and hide the sheet

### test/book_reader_settings_test.dart
- 6 reader settings round-trip independently from manuscript settings
- 22 reader settings and progress reject unsafe persisted values

### test/book_reader_soft_hyphens_test.dart
- 27 finds a line broken inside a word at a soft hyphen
- 37 a line broken at a space or unbroken text needs no hyphen
- 42 hyphenated text leaves room for the hanging hyphen
- 67 draws the hyphen the text engine leaves out

### test/book_reader_text_anchor_test.dart
- 5 keeps a valid range and relocates a shifted excerpt
- 28 chooses the occurrence closest to saved progress

### test/book_reader_tts_test.dart
- 13 TTS continues with the next chapter

### test/book_reader_verse_and_color_test.dart
- 15 lines of a poem stand together and the poem is spaced apart
- 49 a dark word colour is lightened only on a dark page
- 74 the reader text size and font apply to words the author styled
- 102 the reader line spacing applies to an older spaced paragraph

### test/book_reading_progress_test.dart
- 8 weights reading progress by readable section length
- 46 falls back to section order when every section is empty

### test/book_selection_formatting_test.dart
- 69 formatting appears right below the selected words
- 93 the colour button shows a rainbow, then the chosen colour
- 122 clearing takes the words\

### test/book_speech_segmenter_test.dart
- 5 starts at the requested Cyrillic word and keeps source offsets
- 17 skips whitespace and safely splits a long sentence
- 30 groups sentences into long continuous utterances

### test/book_typography_test.dart
- 9 converts paragraph measurements for the editor canvas
- 24 justified, centred, indented and listed paragraphs keep spacing
- 69 the paragraph indent moves only the first line

### test/book_verse_and_color_export_test.dart
- 41 export blocks keep verse lines and word colours
- 49 EPUB gathers a poem and colours the word
- 65 FB2 writes a poem with a stanza per group of lines
- 75 Markdown and plain text keep stanzas compact
- 91 DOCX gives verse its own style and keeps the colour
- 115 PDF lays verse out without failing

### test/book_verse_editing_test.dart
- 48 one empty line in a poem separates stanzas and the poem goes on
- 73 a second empty line leaves the poem for plain text
- 90 an empty line of a quote turns into plain text, name and all
- 111 lines that lost the quote mark of their poem get it back

### test/book_writer_productivity_widget_test.dart
- 11 writing statistics keep goals as they are typed
- 48 shows deleted chapter in the section trash

### test/book_writer_safety_and_color_test.dart
- 34 deleted words wait in the trash and go back into the text
- 65 the bar below the selection colours the words
- 102 the exit button stands out on the dark focus bar

### test/book_writing_state_test.dart
- 5 records writing goals, time, words and streaks
- 26 old projects receive an empty safe writing state

### test/desktop_panel_frame_test.dart
- 11 the panel beside the clock expands or hides from its bar

### test/epub_rich_text_renderer_test.dart
- 5 renders supported inline and block semantics as safe XHTML

### test/file_author_workspace_repository_test.dart
- 22 stores the workspace in a versioned durable envelope
- 50 recovers through two rotating backups
- 80 uses rollback after an interrupted atomic replacement
- 107 migrates preferences once and then prefers the native file

### test/file_book_version_repository_test.dart
- 18 persists, orders and deletes named project versions
- 47 skips a corrupt version without hiding valid snapshots

### test/legacy_diary_migrator_test.dart
- 7 migrates diary entries and pages into semantic book chapters

### test/literia_device_storage_pages_test.dart
- 20 device page scans remembered folders and selects a book
- 62 storage page can remove only the stored original

### test/literia_import_progress_test.dart
- 20 opens only one file picker while an import is pending
- 58 shows progress while an imported book is being stored
- 115 closes only its own progress dialog when an import ends
- 177 starts scanning without opening a folder picker after access

### test/literia_library_page_test.dart
- 16 reading library switches layouts, searches, and favorites
- 92 mobile library keeps leather controls on a compact grid
- 172 system back closes an open library menu, not the library
- 226 manuscript menu does not expose reading-only status

### test/literia_settings_page_test.dart
- 29 the shown version is the one in pubspec.yaml
- 38 theme and language share a line and the guide stays folded

### test/manuscript_section_trash_test.dart
- 7 deleted chapter subtree can be restored at its original position
- 48 trash survives project serialization and can be emptied

### test/manuscript_statistics_test.dart
- 5 counts Russian, English and hyphenated words
- 15 ignores embeds and clamps target progress

### test/preferences_author_workspace_repository_test.dart
- 11 migrates legacy diary storage once and persists version 2
- 44 uses version 2 backup when primary storage is corrupted

### test/preferences_book_version_repository_test.dart
- 11 keeps the newest five Web versions per project
- 37 keeps valid Web snapshots when one entry is corrupt

### test/rich_document_defaults_test.dart
- 5 removes only the legacy automatic line height

### test/section_tree_editor_test.dart
- 17 moves a chapter together with its scenes
- 39 removes a part and every nested section
- 52 inserts a child before the next root section
- 71 drops a chapter into another part together with its scenes
- 99 drops a scene into another chapter and rejects cyclic drops
- 118 generates unique ids for sections created in the same clock tick

### integration_test/critical_data_flows_test.dart
- 20 autosave survives an app lifecycle restart
- 93 FB2 import is persisted and remains readable

