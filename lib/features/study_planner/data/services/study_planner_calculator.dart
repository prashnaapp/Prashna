import '../../../progress/data/models/progress_models.dart';

/// Flattened chapter ref for planner sequencing (no syllabus duplication).
class PlannerChapterRef {
  const PlannerChapterRef({
    required this.paperId,
    required this.paperLabel,
    required this.partId,
    required this.partLabel,
    required this.chapter,
  });

  final String paperId;
  final String paperLabel;
  final String partId;
  final String partLabel;
  final ChapterProgress chapter;

  String get chapterLabel => chapter.label;

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

  static List<PlannerChapterRef> incompleteChapters(
    List<PlannerChapterRef> all,
  ) {
    return all.where((item) => !item.isComplete).toList(growable: false);
  }

  static int completedCount(List<PlannerChapterRef> all) =>
      all.where((item) => item.isComplete).length;
}
