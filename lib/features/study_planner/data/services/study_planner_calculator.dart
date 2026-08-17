import '../../../progress/data/models/progress_models.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';

/// Flattened chapter ref for planner sequencing (no syllabus duplication).
class PlannerChapterRef {
  const PlannerChapterRef({
    required this.paperId,
    required this.paperLabel,
    this.partId,
    this.partLabel,
    this.majorStudyAreaId,
    this.majorStudyAreaLabel,
    this.contentTopicId,
    this.contentTopicLabel,
    this.topicId,
    this.lessonId,
    this.lessonLabel,
    required this.chapter,
  });

  final String paperId;
  final String paperLabel;
  final String? partId;
  final String? partLabel;
  final String? majorStudyAreaId;
  final String? majorStudyAreaLabel;
  final String? contentTopicId;
  final String? contentTopicLabel;
  final String? topicId;
  final String? lessonId;
  final String? lessonLabel;
  final ChapterProgress chapter;

  String get chapterLabel => chapter.label;
  String get parentLabel => majorStudyAreaLabel ?? partLabel ?? '';
  String get unitLabel => lessonLabel ?? contentTopicLabel ?? chapterLabel;

  bool get isComplete => chapter.progressPercent >= 75;
}

/// Builds planner chapter sequence from [OverallProgress].
abstract final class StudyPlannerCalculator {
  /// Mastery threshold — matches Progress "Excellent" band.
  static const double completeThreshold = 75;

  static List<PlannerChapterRef> flattenChapters(OverallProgress overall) {
    final result = <PlannerChapterRef>[];
    for (final paper in overall.papers) {
      for (final part in paper.parts) {
        for (final chapter in part.chapters) {
          result.add(
            PlannerChapterRef(
              paperId: paper.id,
              paperLabel: paper.label,
              partId: part.id,
              partLabel: part.label,
              chapter: chapter,
            ),
          );
        }
      }
    }
    return result;
  }

  /// Traverses the canonical syllabus and matches progress only by canonical
  /// IDs. Legacy section/chapter IDs are intentionally not converted.
  static List<PlannerChapterRef> flattenCanonical(
    OverallProgress overall, {
    SyllabusService? syllabusService,
  }) {
    final syllabus = syllabusService ?? SyllabusService.instance;
    final course = syllabus.getCourseById(overall.examId);
    if (course == null) return flattenChapters(overall);

    final result = <PlannerChapterRef>[];
    for (final paper in course.papers) {
      final paperProgress = _paperProgress(overall, paper.id);
      if (paper.majorStudyAreas.isNotEmpty) {
        for (final area in paper.majorStudyAreas) {
          for (final content in area.contentTopics) {
            final progress = _chapterProgress(paperProgress, content.id);
            result.add(
              PlannerChapterRef(
                paperId: paper.id,
                paperLabel: paper.title,
                majorStudyAreaId: area.id,
                majorStudyAreaLabel: area.displayName,
                contentTopicId: content.id,
                contentTopicLabel: content.displayName,
                chapter:
                    progress ??
                    _emptyChapter(id: content.id, label: content.displayName),
              ),
            );
          }
        }
        continue;
      }

      for (final part in paper.parts) {
        for (final topic in part.topics) {
          for (final lesson in topic.lessons) {
            final progress = _chapterProgress(paperProgress, lesson.id);
            result.add(
              PlannerChapterRef(
                paperId: paper.id,
                paperLabel: paper.title,
                partId: part.id,
                partLabel: part.displayName,
                topicId: topic.id,
                contentTopicLabel: topic.displayName,
                lessonId: lesson.id,
                lessonLabel: lesson.displayName,
                chapter:
                    progress ??
                    _emptyChapter(id: lesson.id, label: lesson.displayName),
              ),
            );
          }
        }
      }
    }
    return result;
  }

  static CanonicalProgressAggregation aggregateByTopic(
    List<PlannerChapterRef> units,
  ) {
    return _aggregate(units, (unit) => unit.topicId ?? unit.contentTopicId);
  }

  static CanonicalProgressAggregation aggregateByPart(
    List<PlannerChapterRef> units,
  ) {
    return _aggregate(units, (unit) => unit.partId ?? unit.majorStudyAreaId);
  }

  static CanonicalProgressAggregation aggregateByPaper(
    List<PlannerChapterRef> units,
  ) {
    return _aggregate(units, (unit) => unit.paperId);
  }

  static CanonicalProgressAggregation aggregateCourse(
    List<PlannerChapterRef> units,
  ) {
    return _aggregate(units, (_) => 'course');
  }

  /// Internal study-tracker weighting, not official examination marks.
  static double partStudyWeight(SyllabusPart part) => 50;

  /// Dynamic per-topic weighting within a Part.
  static double topicStudyWeight(SyllabusPart part) {
    if (part.topics.isEmpty) return 0;
    return partStudyWeight(part) / part.topics.length;
  }

  static PaperProgress? _paperProgress(
    OverallProgress overall,
    String paperId,
  ) {
    for (final paper in overall.papers) {
      if (paper.id == paperId) return paper;
    }
    return null;
  }

  static ChapterProgress? _chapterProgress(
    PaperProgress? paper,
    String canonicalId,
  ) {
    if (paper == null) return null;
    for (final part in paper.parts) {
      for (final chapter in part.chapters) {
        if (chapter.id == canonicalId) return chapter;
      }
    }
    return null;
  }

  static ChapterProgress _emptyChapter({
    required String id,
    required String label,
  }) {
    return ChapterProgress(
      id: id,
      label: label,
      maxMarks: 0,
      coveredMarks: 0,
      progressPercent: 0,
      remainingMarks: 0,
      status: 'Not Started',
    );
  }

  static CanonicalProgressAggregation _aggregate(
    List<PlannerChapterRef> units,
    String? Function(PlannerChapterRef unit) keyOf,
  ) {
    final totals = <String, int>{};
    final completed = <String, int>{};
    for (final unit in units) {
      final key = keyOf(unit);
      if (key == null || key.isEmpty) continue;
      totals[key] = (totals[key] ?? 0) + 1;
      if (unit.isComplete) {
        completed[key] = (completed[key] ?? 0) + 1;
      }
    }
    return CanonicalProgressAggregation(
      total: totals.values.fold(0, (sum, value) => sum + value),
      completed: completed.values.fold(0, (sum, value) => sum + value),
    );
  }

  static List<PlannerChapterRef> incompleteChapters(
    List<PlannerChapterRef> all,
  ) {
    return all.where((item) => !item.isComplete).toList(growable: false);
  }

  static int completedCount(List<PlannerChapterRef> all) =>
      all.where((item) => item.isComplete).length;
}

class CanonicalProgressAggregation {
  const CanonicalProgressAggregation({
    required this.completed,
    required this.total,
  });

  final int completed;
  final int total;

  int get percent => total == 0 ? 0 : ((completed / total) * 100).round();
}
