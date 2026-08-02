import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../bookmarks/data/services/bookmark_service.dart';
import '../../data/models/test_engine_models.dart';
import '../../services/test_service.dart';

/// Presentation controller for a single live test attempt.
/// Owns timer + navigation state; delegates business rules to [TestService].
class TestEngineController extends ChangeNotifier {
  TestEngineController({
    required this.test,
    TestService? service,
  }) : service = service ?? TestService() {
    attempts = this.service.startTest(test);
    _hydrateBookmarks();
    _remaining = test.duration;
  }

  final Test test;
  final TestService service;

  late final List<QuestionAttempt> attempts;
  int currentIndex = 0;
  bool started = false;
  bool submitted = false;
  bool _submitting = false;
  TestResult? result;
  TestAnalysis? analysis;

  Duration _remaining = Duration.zero;
  DateTime? _questionEnteredAt;
  Timer? _timer;

  Duration get remaining => _remaining;
  bool get isTimeUp => _remaining <= Duration.zero;
  bool get isFirst => currentIndex <= 0;
  bool get isLast => currentIndex >= test.questions.length - 1;
  TestQuestion get currentQuestion => test.questions[currentIndex];
  QuestionAttempt get currentAttempt => attempts[currentIndex];
  int get questionNumber => currentIndex + 1;

  /// Bookmarks only for Practice Bits & Current Affairs (practice mode).
  bool get bookmarksEnabled => test.mode == TestMode.practice;

  Map<QuestionStatus, int> get statusCounts => service.statusCounts(attempts);

  void _hydrateBookmarks() {
    if (!bookmarksEnabled) return;
    final bookmarks = BookmarkService.instance;
    for (final attempt in attempts) {
      attempt.bookmarked = bookmarks.isBookmarked(attempt.questionId);
    }
  }

  Future<void> start() async {
    if (started) return;
    started = true;
    await service.prepareTest(test);
    _markCurrentVisited();
    _questionEnteredAt = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  void selectOption(String label) {
    if (submitted) return;
    service.saveAnswer(attempt: currentAttempt, optionLabel: label);
    _persist();
    notifyListeners();
  }

  void clearResponse() {
    if (submitted) return;
    service.clearResponse(currentAttempt);
    _persist();
    notifyListeners();
  }

  void toggleBookmark() {
    if (submitted || !bookmarksEnabled) return;
    service.bookmarkQuestion(currentAttempt);
    if (currentAttempt.bookmarked) {
      unawaited(
        BookmarkService.instance.addBookmark(
          questionId: currentAttempt.questionId,
          courseId: test.courseId,
          paperId: currentQuestion.paperId ?? test.paperId,
          partId: currentQuestion.sectionId ?? test.sectionId,
          chapterId: currentQuestion.topicId ?? test.topicId,
          questionType: test.mode.name,
          questionTitle: currentQuestion.text,
        ),
      );
    } else {
      unawaited(
        BookmarkService.instance.removeBookmark(currentAttempt.questionId),
      );
    }
    _persist();
    notifyListeners();
  }

  void toggleMarkForReview() {
    if (submitted) return;
    service.markReview(currentAttempt);
    _persist();
    notifyListeners();
  }

  void goNext() {
    if (submitted || isLast) return;
    _leaveCurrentQuestion();
    currentIndex = service.navigateNext(currentIndex, test.questions.length);
    _enterCurrentQuestion();
    notifyListeners();
  }

  void goPrevious() {
    if (submitted || isFirst) return;
    _leaveCurrentQuestion();
    currentIndex = service.navigatePrevious(currentIndex);
    _enterCurrentQuestion();
    notifyListeners();
  }

  void goTo(int index) {
    if (submitted) return;
    _leaveCurrentQuestion();
    currentIndex = service.navigateTo(index, test.questions.length);
    _enterCurrentQuestion();
    notifyListeners();
  }

  Future<TestResult> submit() async {
    if (submitted && result != null) return result!;
    if (_submitting) {
      while (_submitting && result == null) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return result!;
    }
    _submitting = true;
    _leaveCurrentQuestion();
    _timer?.cancel();

    final elapsed = test.duration - _remaining;
    final timeTaken = elapsed.isNegative ? Duration.zero : elapsed;

    try {
      result = await service.submitTest(
        test: test,
        attempts: attempts,
        timeTaken: timeTaken,
      );
      analysis = service.generateAnalysis(test: test, attempts: attempts);
      submitted = true;
      notifyListeners();
      return result!;
    } finally {
      _submitting = false;
    }
  }

  String formatRemaining() {
    final total = _remaining.inSeconds.clamp(0, 24 * 3600);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    final seconds = total % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds <= 1) {
        _remaining = Duration.zero;
        notifyListeners();
        unawaited(submit());
        return;
      }
      _remaining -= const Duration(seconds: 1);
      notifyListeners();
    });
  }

  void _markCurrentVisited() {
    service.markVisited(currentAttempt);
  }

  void _enterCurrentQuestion() {
    _markCurrentVisited();
    _questionEnteredAt = DateTime.now();
    _persist();
  }

  void _leaveCurrentQuestion() {
    final entered = _questionEnteredAt;
    if (entered == null) return;
    final spent = DateTime.now().difference(entered).inSeconds;
    service.addTimeSpent(currentAttempt, spent);
    _questionEnteredAt = null;
  }

  void _persist() {
    unawaited(
      service.saveProgress(testId: test.id, attempts: attempts),
    );
  }
}
