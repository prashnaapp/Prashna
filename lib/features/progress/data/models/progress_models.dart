class ChapterProgress {
  const ChapterProgress({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.coveredMarks,
    required this.progressPercent,
    required this.remainingMarks,
    required this.status,
  });

  final String id;
  final String label;
  final double maxMarks;
  final double coveredMarks;
  final double progressPercent;
  final double remainingMarks;
  final String status;
}

class PartProgress {
  const PartProgress({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.coveredMarks,
    required this.progressPercent,
    required this.remainingMarks,
    required this.chapters,
  });

  final String id;
  final String label;
  final double maxMarks;
  final double coveredMarks;
  final double progressPercent;
  final double remainingMarks;
  final List<ChapterProgress> chapters;
}

class PaperProgress {
  const PaperProgress({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.coveredMarks,
    required this.progressPercent,
    required this.remainingMarks,
    required this.parts,
  });

  final String id;
  final String label;
  final double maxMarks;
  final double coveredMarks;
  final double progressPercent;
  final double remainingMarks;
  final List<PartProgress> parts;
}

class OverallProgress {
  const OverallProgress({
    required this.examId,
    required this.examTitle,
    required this.maxMarks,
    required this.coveredMarks,
    required this.progressPercent,
    required this.remainingMarks,
    required this.papers,
  });

  final String examId;
  final String examTitle;
  final double maxMarks;
  final double coveredMarks;
  final double progressPercent;
  final double remainingMarks;
  final List<PaperProgress> papers;
}

class ExamProgressSummary {
  const ExamProgressSummary({
    required this.examId,
    required this.title,
    required this.maxMarks,
    required this.paperCount,
    required this.isEnabled,
  });

  final String examId;
  final String title;
  final double maxMarks;
  final int paperCount;
  final bool isEnabled;
}
