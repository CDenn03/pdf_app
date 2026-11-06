import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/reader_page_match.dart';
import 'package:sefer/features/reader/domain/reader_page_navigation.dart';
import 'package:sefer/features/reader/domain/reader_search_backend.dart';
import 'package:sefer/features/reader/domain/reader_search_controller.dart';
import 'package:sefer/features/reader/domain/reader_search_highlights.dart';
import 'package:sefer/features/reader/domain/reader_search_results.dart';
import 'package:sefer/features/reader/domain/search_backend_detached_exception.dart';

class DocumentSearchController extends ChangeNotifier
    implements ReaderSearchController, ReaderSearchHighlights {
  DocumentSearchController({
    required ReaderSearchBackend backend,
    required ReaderPageNavigation navigation,
    required Duration typingDelay,
  }) : _backend = backend,
       _navigation = navigation,
       _typingDelay = typingDelay;

  static const _firstMatchMargin = 50.0;

  final ReaderSearchBackend _backend;
  final ReaderPageNavigation _navigation;
  final Duration _typingDelay;

  String _query = '';
  ReaderSearchResults _results = ReaderSearchResults.empty;
  int? _activeIndex;
  ReaderPageMatch? _matchToRestore;
  bool _searching = false;
  int _generation = 0;
  Timer? _typingTimer;
  StreamSubscription<List<ReaderPageMatch>>? _subscription;
  bool _disposed = false;

  ReaderSearchResults get results => _results;

  @override
  int? get currentIndex => _activeIndex;

  @override
  bool get isSearching => _searching;

  @override
  List<FindMatch> get matches => [
    for (final match in _results.matches)
      FindMatch(page: match.pageNumber, excerpt: match.excerpt),
  ];

  @override
  ReaderPageMatch? get activeMatch {
    final index = _activeIndex;
    return index == null ? null : _results.matches[index];
  }

  @override
  List<ReaderPageMatch> matchesOnPage(int pageNumber) =>
      _results.onPage(pageNumber);

  @override
  void startTextSearch(String query) {
    if (query.isEmpty) return resetTextSearch();
    if (query == _query) return;
    _query = query;
    _supersedeRunningSearch();
    _typingTimer = Timer(_typingDelay, () => _run(revealFirstMatch: true));
  }

  @override
  void resetTextSearch() {
    _query = '';
    _supersedeRunningSearch();
    _results = ReaderSearchResults.empty;
    _activeIndex = null;
    _searching = false;
    notifyListeners();
  }

  void rerunQuery() {
    if (_query.isEmpty) return;
    _supersedeRunningSearch();
    _matchToRestore = activeMatch;
    _run(revealFirstMatch: false);
  }

  @override
  Future<void> goToMatchAt(int index, {required double chromeMargin}) async {
    if (index < 0 || index >= _results.matches.length) return;
    _activeIndex = index;
    _matchToRestore = null;
    notifyListeners();
    await _show(_results.matches[index], chromeMargin);
  }

  @override
  Future<void> goToNextMatch({required double chromeMargin}) async {
    if (_results.isEmpty) return;
    await goToMatchAt(
      _results.nextIndex(_activeIndex),
      chromeMargin: chromeMargin,
    );
  }

  @override
  Future<void> goToPreviousMatch({required double chromeMargin}) async {
    if (_results.isEmpty) return;
    await goToMatchAt(
      _results.previousIndex(_activeIndex),
      chromeMargin: chromeMargin,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _supersedeRunningSearch();
    super.dispose();
  }

  void _supersedeRunningSearch() {
    _generation++;
    _matchToRestore = null;
    _typingTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _run({required bool revealFirstMatch}) {
    final generation = _generation;
    _results = ReaderSearchResults.empty;
    _activeIndex = null;
    _searching = true;
    notifyListeners();
    _subscription = _backend
        .search(_query)
        .listen(
          (pageMatches) => _accept(generation, pageMatches, revealFirstMatch),
          onError: (Object error, StackTrace stack) =>
              _fail(generation, error, stack),
          onDone: () => _finish(generation),
        );
  }

  void _accept(
    int generation,
    List<ReaderPageMatch> pageMatches,
    bool revealFirstMatch,
  ) {
    if (generation != _generation || pageMatches.isEmpty) return;
    final isFirstResult = _results.isEmpty;
    _results = _results.including(pageMatches);
    _updateActiveIndex(isFirstResult: isFirstResult);
    notifyListeners();
    if (isFirstResult && revealFirstMatch) {
      unawaited(_show(_results.matches.first, _firstMatchMargin));
    }
  }

  void _updateActiveIndex({required bool isFirstResult}) {
    final restoring = _matchToRestore;
    if (restoring == null) {
      if (isFirstResult) _activeIndex = 0;
      return;
    }
    final restoredIndex = _results.matches.indexOf(restoring);
    if (restoredIndex < 0) return;
    _activeIndex = restoredIndex;
    _matchToRestore = null;
  }

  void _fail(int generation, Object error, StackTrace stack) {
    if (generation != _generation) return;
    if (error is SearchBackendDetachedException) return _awaitRerun();
    developer.log(
      'Text search failed for query of ${_query.length} characters',
      name: 'sefer.search',
      level: 1000,
      error: error,
      stackTrace: stack,
    );
    _finish(generation);
  }

  void _awaitRerun() {
    _generation++;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _finish(int generation) {
    if (generation != _generation) return;
    _searching = false;
    _matchToRestore = null;
    if (_activeIndex == null && !_results.isEmpty) _activeIndex = 0;
    notifyListeners();
  }

  Future<void> _show(ReaderPageMatch match, double margin) async {
    try {
      final placed = await _backend.reveal(match, margin: margin);
      if (!placed && !_disposed) {
        await _navigation.goToPage(match.pageNumber);
      }
    } catch (error, stack) {
      developer.log(
        'Showing search match on page ${match.pageNumber} failed',
        name: 'sefer.search',
        level: 1000,
        error: error,
        stackTrace: stack,
      );
    }
  }
}
