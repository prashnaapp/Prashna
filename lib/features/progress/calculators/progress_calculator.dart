import '../data/models/progress_models.dart';
import '../data/models/progress_seed_models.dart';

/// Aggregates chapter → part → paper → overall progress.
class ProgressCalculator {
  ChapterProgress calculateChapter(ChapterScoreSeed seed) {
    final covered = _coveredMarks(seed.maxMarks, seed.scorePercent);
    final remaining =
        (seed.maxMarks - covered).clamp(0.0, seed.maxMarks).toDouble();
    final percent = _percent(covered, seed.maxMarks);

    return ChapterProgress(
      id: seed.id,
      label: seed.label,
      maxMarks: seed.maxMarks,
      coveredMarks: covered,
      progressPercent: percent,
      remainingMarks: remaining,
      status: _statusFor(percent),
    );
  }

  PartProgress calculatePart(PartScoreSeed seed) {
    final chapters = seed.chapters.map(calculateChapter).toList();
    final chapterMaxSum =
        chapters.fold<double>(0, (sum, item) => sum + item.maxMarks);
    final chapterCoveredSum =
        chapters.fold<double>(0, (sum, item) => sum + item.coveredMarks);

    final max = seed.maxMarks;
    final covered = chapterMaxSum > 0
        ? double.parse(
            (chapterCoveredSum / chapterMaxSum * max).toStringAsFixed(1),
          )
        : 0.0;
    final remaining = (max - covered).clamp(0.0, max).toDouble();

    return PartProgress(
      id: seed.id,
      label: seed.label,
      maxMarks: max,
      coveredMarks: covered,
      progressPercent: _percent(covered, max),
      remainingMarks: remaining,
      chapters: chapters,
    );
  }

  PaperProgress calculatePaper(PaperScoreSeed seed) {
    final parts = seed.parts.map(calculatePart).toList();
    final covered = parts.fold<double>(0, (s, p) => s + p.coveredMarks);
    final max = seed.maxMarks;
    final remaining = (max - covered).clamp(0.0, max).toDouble();

    return PaperProgress(
      id: seed.id,
      label: seed.label,
      maxMarks: max,
      coveredMarks: covered,
      progressPercent: _percent(covered, max),
      remainingMarks: remaining,
      parts: parts,
    );
  }

  OverallProgress calculateOverall(ExamScoreSeed seed) {
    final papers = seed.papers.map(calculatePaper).toList();
    final covered = papers.fold<double>(0, (s, p) => s + p.coveredMarks);
    final max = seed.maxMarks;
    final remaining = (max - covered).clamp(0.0, max).toDouble();

    return OverallProgress(
      examId: seed.examId,
      examTitle: seed.title,
      maxMarks: max,
      coveredMarks: covered,
      progressPercent: _percent(covered, max),
      remainingMarks: remaining,
      papers: papers,
    );
  }

  double _coveredMarks(double maxMarks, double scorePercent) {
    return double.parse(
      (maxMarks * (scorePercent / 100)).toStringAsFixed(1),
    );
  }

  double _percent(double covered, double max) {
    if (max <= 0) return 0;
    return double.parse(((covered / max) * 100).toStringAsFixed(0));
  }

  String _statusFor(double percent) {
    if (percent >= 75) return 'Excellent';
    if (percent >= 50) return 'Good';
    if (percent >= 25) return 'Needs Focus';
    return 'Not Started';
  }
}
