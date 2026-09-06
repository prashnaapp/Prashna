import '../../question_bank/data/models/question_models.dart';
import '../../test_engine/data/models/test_engine_models.dart';
import '../data/models/question_activity_models.dart';
import '../data/question_activity_context_factory.dart';

/// Explicit bookmark eligibility for identity-safe Question Bank sources.
///
/// H2.8F-4B: eligibility is **source-aware**, not `TestMode.practice`-only.
///
/// Allowed (when course/identity safe):
/// - Chapters / syllabus unit catalog
/// - Test Series (paper-wise, grand, old grand, previous)
/// - Practice / revision practice
/// - Question viewers for durable bank questions
///
/// Blocked:
/// - Current Affairs (identity architecture not proven)
/// - Dummy / temporary / unresolved questions
/// - Unknown/other sources that are not proven safe
///
/// Bookmark identity remains global [questionId] via [BookmarkService].
abstract final class BookmarkEligibility {
  static const String currentAffairsCourseId = 'current-affairs';

  /// Courses with proven durable `questions/{id}` bank identity.
  static const Set<String> identitySafeCourseIds = {
    'group-ii',
    'group-iii',
  };

  /// Whether Test Engine may show / toggle bookmarks for [test].
  static bool forTest(Test test) {
    if (_isBlockedCourse(test.courseId)) return false;
    if (test.activitySourceModule ==
        QuestionActivitySourceModule.currentAffairs) {
      return false;
    }
    final caSet = test.currentAffairsSetId?.trim();
    if (caSet != null && caSet.isNotEmpty) return false;

    final module =
        test.activitySourceModule ??
        QuestionActivityContextFactory.inferModule(
          courseId: test.courseId,
          mode: test.mode,
          testId: test.id,
        );

    return forSourceModule(
      module,
      courseId: test.courseId,
      mode: test.mode,
    );
  }

  /// Source-module policy with course/mode fallbacks for unstamped legacy tests.
  static bool forSourceModule(
    QuestionActivitySourceModule module, {
    String? courseId,
    TestMode? mode,
  }) {
    if (_isBlockedCourse(courseId)) return false;

    switch (module) {
      case QuestionActivitySourceModule.chapters:
      case QuestionActivitySourceModule.testSeries:
        return _isIdentitySafeCourse(courseId);
      case QuestionActivitySourceModule.practice:
      case QuestionActivitySourceModule.revision:
        // Explicit practice/revision stamps are allowed when course is safe or
        // not yet resolved; Current Affairs course is already blocked above.
        if (courseId == null || courseId.trim().isEmpty) return true;
        return _isIdentitySafeCourse(courseId);
      case QuestionActivitySourceModule.currentAffairs:
        return false;
      case QuestionActivitySourceModule.other:
        return false;
      case QuestionActivitySourceModule.unknown:
        return _allowUnknownLegacy(courseId: courseId, mode: mode);
    }
  }

  /// Viewer / service guard for a resolved Question Bank document.
  ///
  /// [question] null → blocked (unresolved ID).
  static bool forQuestion(Question? question) {
    if (question == null) return false;
    final id = question.id.trim();
    if (id.isEmpty) return false;
    if (_isBlockedCourse(question.courseId)) return false;
    return _isIdentitySafeCourse(question.courseId);
  }

  /// Whether an already-bookmarked item may still be removed.
  ///
  /// Removal is always allowed so blocked sources can be cleaned up.
  static bool canRemoveBookmark({required bool isCurrentlyBookmarked}) {
    return isCurrentlyBookmarked;
  }

  /// Legacy helper — prefer [forTest].
  ///
  /// Mode alone cannot prove source safety (e.g. Current Affairs is practice).
  /// Returns true only for modes that *may* be eligible after course/source checks.
  @Deprecated('Use BookmarkEligibility.forTest / forSourceModule')
  static bool forTestMode(TestMode mode) {
    switch (mode) {
      case TestMode.practice:
      case TestMode.topic:
      case TestMode.section:
      case TestMode.paper:
      case TestMode.mock:
      case TestMode.previousYear:
      case TestMode.grand:
        return true;
    }
  }

  static bool _allowUnknownLegacy({
    String? courseId,
    TestMode? mode,
  }) {
    if (_isBlockedCourse(courseId)) return false;
    if (!_isIdentitySafeCourse(courseId)) return false;
    if (mode == null) return false;
    switch (mode) {
      case TestMode.practice:
      case TestMode.topic:
      case TestMode.section:
      case TestMode.paper:
      case TestMode.mock:
      case TestMode.previousYear:
      case TestMode.grand:
        return true;
    }
  }

  static bool _isBlockedCourse(String? courseId) {
    final value = courseId?.trim().toLowerCase() ?? '';
    return value == currentAffairsCourseId;
  }

  static bool _isIdentitySafeCourse(String? courseId) {
    final value = courseId?.trim().toLowerCase() ?? '';
    return identitySafeCourseIds.contains(value);
  }
}
