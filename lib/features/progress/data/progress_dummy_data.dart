import 'models/progress_seed_models.dart';

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
          _part('part-i', 'Part I', 50, [78, 52, 40, 30, 36]),
          _part('part-ii', 'Part II', 50, [60, 48, 35, 25, 20]),
          _part('part-iii', 'Part III', 50, [40, 30, 25, 20, 15]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-ii',
        label: 'Paper II',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, [90, 60, 20, 0, 0]),
          _part('part-ii', 'Part II', 50, [30, 25, 20, 15, 10]),
          _part('part-iii', 'Part III', 50, [20, 15, 12, 8, 5]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iii',
        label: 'Paper III',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, [15, 12, 10, 8, 5]),
          _part('part-ii', 'Part II', 50, [10, 8, 6, 5, 4]),
          _part('part-iii', 'Part III', 50, [8, 6, 5, 4, 3]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iv',
        label: 'Paper IV',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, [95, 85, 70, 60, 55]),
          _part('part-ii', 'Part II', 50, [50, 45, 40, 35, 30]),
          _part('part-iii', 'Part III', 50, [40, 35, 30, 25, 20]),
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
          _part('part-i', 'Part I', 50, [50, 40, 30, 25, 20]),
          _part('part-ii', 'Part II', 50, [35, 30, 25, 20, 15]),
          _part('part-iii', 'Part III', 50, [25, 20, 15, 12, 10]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-ii',
        label: 'Paper II',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, [45, 35, 30, 25, 20]),
          _part('part-ii', 'Part II', 50, [30, 25, 20, 18, 15]),
          _part('part-iii', 'Part III', 50, [20, 18, 15, 12, 10]),
        ],
      ),
      PaperScoreSeed(
        id: 'paper-iii',
        label: 'Paper III',
        maxMarks: 150,
        parts: [
          _part('part-i', 'Part I', 50, [40, 30, 25, 20, 15]),
          _part('part-ii', 'Part II', 50, [28, 22, 18, 15, 12]),
          _part('part-iii', 'Part III', 50, [18, 15, 12, 10, 8]),
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
