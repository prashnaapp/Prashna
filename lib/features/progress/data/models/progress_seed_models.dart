class ChapterScoreSeed {
  const ChapterScoreSeed({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.scorePercent,
  });

  final String id;
  final String label;
  final double maxMarks;
  final double scorePercent;
}

class PartScoreSeed {
  const PartScoreSeed({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.chapters,
  });

  final String id;
  final String label;
  final double maxMarks;
  final List<ChapterScoreSeed> chapters;
}

class PaperScoreSeed {
  const PaperScoreSeed({
    required this.id,
    required this.label,
    required this.maxMarks,
    required this.parts,
  });

  final String id;
  final String label;
  final double maxMarks;
  final List<PartScoreSeed> parts;
}

class ExamScoreSeed {
  const ExamScoreSeed({
    required this.examId,
    required this.title,
    required this.maxMarks,
    required this.papers,
  });

  final String examId;
  final String title;
  final double maxMarks;
  final List<PaperScoreSeed> papers;
}
