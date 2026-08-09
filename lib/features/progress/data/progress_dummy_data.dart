import 'models/progress_seed_models.dart';

/// Syllabus structure (course / paper / part / chapter IDs and max marks).
///
/// Chapter score percents are intentionally zero — student progress truth comes
/// from cloud hydration + live attempt credits, not fabricated seed scores.
abstract final class ProgressDummyData {
  static const groupII = 'group-ii';
  static const groupIII = 'group-iii';

  static final Map<String, ExamScoreSeed> examSeeds = {
    groupII: _groupII,
    groupIII: _groupIII,
  };

  static final _groupII = ExamScoreSeed(
    examId: groupII,
    title: 'Group-II',
    maxMarks: 600,
    papers: [
      PaperScoreSeed(
        id: 'paper-i',
        label: 'Paper I',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-ii',
        label: 'Paper II',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iii',
        label: 'Paper III',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iv',
        label: 'Paper IV',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
    ],
  );

  static final _groupIII = ExamScoreSeed(
    examId: groupIII,
    title: 'Group-III',
    maxMarks: 450,
    papers: [
      PaperScoreSeed(
        id: 'paper-i',
        label: 'Paper I',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-ii',
        label: 'Paper II',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iii',
        label: 'Paper III',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, const [0, 0, 0, 0, 0]),
          _part('part-ii', 'Part II', 50, const [0, 0, 0, 0, 0]),
          _part('part-iii', 'Part III', 50, const [0, 0, 0, 0, 0]),
        ],
      ),
    ],
  );

  static PartScoreSeed _part(
    String id,
    String label,
    double maxMarks,
    List<double> chapterPercents,
  ) {
    return PartScoreSeed(
      id: id,
      label: label,
      maxMarks: maxMarks,
      chapters: [
        for (var i = 0; i < chapterPercents.length; i++)
          ChapterScoreSeed(
            id: 'chapter-${i + 1}',
            label: 'Chapter ${i + 1}',
            maxMarks: 5,
            scorePercent: chapterPercents[i],
          ),
      ],
    );
  }
}
