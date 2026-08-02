/// Dummy syllabus data for the Chapters module.
abstract final class ChaptersData {
  static const groupII = 'Group-II';
  static const groupIII = 'Group-III';

  static const parts = ['Part I', 'Part II', 'Part III'];

  static const chaptersPerPart = 5;

  static List<String> chapterLabels(int count) =>
      List.generate(count, (i) => 'Chapter ${i + 1}');
}
