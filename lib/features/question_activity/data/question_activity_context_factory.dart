import '../../test_engine/data/models/test_engine_models.dart';
import '../../tests/data/grand_test_series.dart';
import '../../tests/data/models/test_models.dart';
import 'models/question_activity_models.dart';

/// Builds [QuestionActivityContext] from existing Test Engine / catalog models.
///
/// Prefer explicit [sourceModule] / [sourceType] from navigation. Inference is
/// best-effort only and must never invent hierarchy fields that were not present.
abstract final class QuestionActivityContextFactory {
  static QuestionActivityContext forQuestion({
    required String questionId,
    String? courseId,
    QuestionActivitySourceModule sourceModule =
        QuestionActivitySourceModule.unknown,
    QuestionActivitySourceType sourceType = QuestionActivitySourceType.unknown,
    String? testId,
    String? testTitle,
    String? paperId,
    String? sectionId,
    String? partId,
    String? topicId,
    String? lessonId,
    String? majorStudyAreaId,
    String? contentTopicId,
    String? syllabusUnitId,
    String? seriesId,
    int? year,
    String? currentAffairsSetId,
    String? encounterId,
    DateTime? recordedAt,
  }) {
    final id = questionId.trim();
    assert(id.isNotEmpty, 'questionId is required');
    return QuestionActivityContext(
      questionId: id,
      courseId: _trimOrNull(courseId),
      sourceModule: sourceModule,
      sourceType: sourceType,
      testId: _trimOrNull(testId),
      testTitle: _trimOrNull(testTitle),
      paperId: _trimOrNull(paperId),
      sectionId: _trimOrNull(sectionId),
      partId: _trimOrNull(partId),
      topicId: _trimOrNull(topicId),
      lessonId: _trimOrNull(lessonId),
      majorStudyAreaId: _trimOrNull(majorStudyAreaId),
      contentTopicId: _trimOrNull(contentTopicId),
      syllabusUnitId: _trimOrNull(syllabusUnitId),
      seriesId: _trimOrNull(seriesId),
      year: year,
      currentAffairsSetId: _trimOrNull(currentAffairsSetId),
      encounterId: _trimOrNull(encounterId),
      recordedAt: recordedAt ?? DateTime.now(),
    );
  }

  /// Context template from a [Test], with optional navigation overrides.
  static QuestionActivityContext fromTest(
    Test test, {
    required String questionId,
    QuestionActivitySourceModule? sourceModule,
    QuestionActivitySourceType? sourceType,
    String? seriesId,
    int? year,
    String? syllabusUnitId,
    String? currentAffairsSetId,
    String? encounterId,
    TestCategoryType? category,
  }) {
    final resolvedModule =
        sourceModule ??
        test.activitySourceModule ??
        inferModule(
          courseId: test.courseId,
          mode: test.mode,
          testId: test.id,
          category: category,
        );
    final resolvedType =
        sourceType ??
        test.activitySourceType ??
        inferType(
          courseId: test.courseId,
          mode: test.mode,
          testId: test.id,
          category: category,
          seriesId: seriesId ?? test.seriesId,
        );

    return forQuestion(
      questionId: questionId,
      courseId: test.courseId,
      sourceModule: resolvedModule,
      sourceType: resolvedType,
      testId: test.id,
      testTitle: test.title,
      paperId: test.paperId,
      sectionId: test.sectionId,
      partId: test.partId,
      topicId: test.topicId,
      lessonId: test.lessonId,
      majorStudyAreaId: test.majorStudyAreaId,
      contentTopicId: test.contentTopicId,
      syllabusUnitId: syllabusUnitId ?? test.syllabusUnitId,
      seriesId: seriesId ?? test.seriesId,
      year: year ?? test.year,
      currentAffairsSetId: currentAffairsSetId ?? test.currentAffairsSetId,
      encounterId: encounterId,
    );
  }

  static QuestionActivitySourceModule inferModule({
    String? courseId,
    TestMode? mode,
    String? testId,
    TestCategoryType? category,
  }) {
    final course = courseId?.trim().toLowerCase();
    if (course == 'current-affairs') {
      return QuestionActivitySourceModule.currentAffairs;
    }
    final id = testId?.trim().toLowerCase() ?? '';
    if (id.startsWith('revision-')) {
      return QuestionActivitySourceModule.revision;
    }
    if (mode == TestMode.practice) {
      return QuestionActivitySourceModule.practice;
    }
    if (category != null) {
      switch (category) {
        case TestCategoryType.chapterTests:
          // Ambiguous without navigation hint (Chapters unit vs Paper-wise).
          return QuestionActivitySourceModule.unknown;
        case TestCategoryType.partTests:
        case TestCategoryType.paperTests:
        case TestCategoryType.mockTests:
        case TestCategoryType.previousYear:
          return QuestionActivitySourceModule.testSeries;
      }
    }
    if (mode == TestMode.mock ||
        mode == TestMode.previousYear ||
        mode == TestMode.grand) {
      return QuestionActivitySourceModule.testSeries;
    }
    return QuestionActivitySourceModule.unknown;
  }

  static QuestionActivitySourceType inferType({
    String? courseId,
    TestMode? mode,
    String? testId,
    TestCategoryType? category,
    String? seriesId,
  }) {
    final course = courseId?.trim().toLowerCase();
    if (course == 'current-affairs') {
      final id = testId?.trim().toLowerCase() ?? '';
      if (id.contains('week')) {
        return QuestionActivitySourceType.currentAffairsWeekly;
      }
      if (id.contains('month')) {
        return QuestionActivitySourceType.currentAffairsMonthly;
      }
      return QuestionActivitySourceType.unknown;
    }
    final tid = testId?.trim().toLowerCase() ?? '';
    if (tid.startsWith('revision-')) {
      return QuestionActivitySourceType.revisionPractice;
    }
    if (mode == TestMode.practice) {
      return QuestionActivitySourceType.topicPractice;
    }
    final series = seriesId?.trim();
    if (series == GrandTestSeries.oldGrandTests) {
      return QuestionActivitySourceType.oldGrandTest;
    }
    if (series != null &&
        series.isNotEmpty &&
        GrandTestSeries.isApproved(series)) {
      return QuestionActivitySourceType.grandTest;
    }
    if (category != null) {
      switch (category) {
        case TestCategoryType.chapterTests:
          return QuestionActivitySourceType.chapterTests;
        case TestCategoryType.partTests:
          return QuestionActivitySourceType.partTests;
        case TestCategoryType.paperTests:
          return QuestionActivitySourceType.paperTests;
        case TestCategoryType.mockTests:
          return QuestionActivitySourceType.grandTest;
        case TestCategoryType.previousYear:
          return QuestionActivitySourceType.previousPaper;
      }
    }
    switch (mode) {
      case TestMode.topic:
        return QuestionActivitySourceType.chapterTests;
      case TestMode.section:
        return QuestionActivitySourceType.partTests;
      case TestMode.paper:
        return QuestionActivitySourceType.paperTests;
      case TestMode.mock:
      case TestMode.grand:
        return QuestionActivitySourceType.grandTest;
      case TestMode.previousYear:
        return QuestionActivitySourceType.previousPaper;
      case TestMode.practice:
      case null:
        return QuestionActivitySourceType.unknown;
    }
  }

  static QuestionActivitySourceModule moduleForCatalog({
    required TestCategoryType category,
    required bool fromSyllabusUnit,
  }) {
    if (fromSyllabusUnit) return QuestionActivitySourceModule.chapters;
    return QuestionActivitySourceModule.testSeries;
  }

  static String? _trimOrNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
