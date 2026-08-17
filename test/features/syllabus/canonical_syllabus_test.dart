import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/data/syllabus_dummy_data.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

void main() {
  final groupII = SyllabusDummyData.all.singleWhere(
    (course) => course.id == 'group-ii',
  );

  test('Paper I uses Major Study Areas and Content Topics', () {
    final paper = groupII.papers.singleWhere(
      (paper) => paper.id == 'group-ii-paper-i',
    );

    expect(paper.majorStudyAreas, isNotEmpty);
    expect(paper.parts, isEmpty);
    expect(
      paper.majorStudyAreas.every((area) => area.contentTopics.isNotEmpty),
      isTrue,
    );
    expect(
      paper.majorStudyAreas.every(
        (area) => area.contentTopics.every(
          (topic) => topic.id.startsWith('${area.id}-topic-'),
        ),
      ),
      isTrue,
    );
  });

  test('Papers II–IV use Part, Topic, and Lesson hierarchy', () {
    for (final paper in groupII.papers.skip(1)) {
      expect(paper.parts, isNotEmpty, reason: paper.id);
      expect(
        paper.parts.every(
          (part) =>
              part.topics.isNotEmpty &&
              part.topics.every((topic) => topic.lessons.isNotEmpty),
        ),
        isTrue,
        reason: paper.id,
      );
      expect(paper.majorStudyAreas, isEmpty, reason: paper.id);
    }
  });

  test('canonical IDs are stable, contextual, and unique', () {
    final ids = <String>[];
    for (final paper in groupII.papers) {
      ids.add(paper.id);
      for (final area in paper.majorStudyAreas) {
        ids.add(area.id);
        ids.addAll(area.contentTopics.map((topic) => topic.id));
      }
      for (final part in paper.parts) {
        ids.add(part.id);
        for (final topic in part.topics) {
          ids.add(topic.id);
          ids.addAll(topic.lessons.map((lesson) => lesson.id));
        }
      }
    }

    expect(ids.toSet().length, ids.length);
    expect(ids, everyElement(startsWith('group-ii-paper-')));
    expect(
      ids.where(
        (id) => RegExp(r'^(paper|section|topic|chapter)-\d+$').hasMatch(id),
      ),
      isEmpty,
    );
  });

  test('officialName is preserved separately from displayName', () {
    final area = groupII.papers
        .singleWhere((paper) => paper.id == 'group-ii-paper-i')
        .majorStudyAreas
        .first;
    final topic = groupII.papers
        .singleWhere((paper) => paper.id == 'group-ii-paper-ii')
        .parts
        .first
        .topics
        .first;

    expect(area.officialName, isNotEmpty);
    expect(area.displayName, isNotEmpty);
    expect(topic.officialName, isNotEmpty);
    expect(topic.displayName, isNotEmpty);
    expect(topic.officialName, isNot(equals(topic.displayName)));
  });

  test('approved mapping retains all 61 topics and 494 lessons', () {
    final papers = groupII.papers.skip(1);
    final topics = papers.expand(
      (paper) => paper.parts.expand((part) => part.topics),
    );
    final lessons = topics.expand((topic) => topic.lessons);

    expect(topics.length, 50);
    expect(lessons.length, 494);
  });

  test('canonical service lookup does not reinterpret legacy lookup APIs', () {
    final service = SyllabusService.instance;
    final topic = service.getCanonicalTopic(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      topicId: 'group-ii-paper-ii-part-01-topic-01',
    );
    final lesson = service.getLesson(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      topicId: 'group-ii-paper-ii-part-01-topic-01',
      lessonId: 'group-ii-paper-ii-part-01-topic-01-lesson-01',
    );

    expect(topic, isNotNull);
    expect(lesson, isNotNull);
  });

  test('1: Group-II Paper-I has exactly 11 syllabus units and no Parts', () {
    final paper = groupII.papers.singleWhere(
      (paper) => paper.id == 'group-ii-paper-i',
    );
    expect(paper.parts, isEmpty);
    expect(paper.syllabusUnits, hasLength(11));
    expect(paper.hasDirectSyllabusUnits, isTrue);
    expect(
      paper.syllabusUnits.map((unit) => unit.id),
      [
        'group-ii-paper-i-area-01',
        'group-ii-paper-i-area-02',
        'group-ii-paper-i-area-03',
        'group-ii-paper-i-area-04',
        'group-ii-paper-i-area-05',
        'group-ii-paper-i-area-06',
        'group-ii-paper-i-area-07',
        'group-ii-paper-i-area-08',
        'group-ii-paper-i-area-09',
        'group-ii-paper-i-area-10',
        'group-ii-paper-i-area-11',
      ],
    );
  });

  test('2–4: Group-II Papers II–IV have Part layers and official unit counts', () {
    final expected = <String, List<int>>{
      'group-ii-paper-ii': const [5, 10, 5],
      'group-ii-paper-iii': const [5, 5, 5],
      'group-ii-paper-iv': const [5, 5, 5],
    };
    for (final entry in expected.entries) {
      final paper = groupII.papers.singleWhere((paper) => paper.id == entry.key);
      expect(paper.syllabusUnits, isEmpty, reason: entry.key);
      expect(paper.parts, hasLength(3), reason: entry.key);
      expect(paper.hasPartSyllabusUnits, isTrue, reason: entry.key);
      expect(
        paper.parts.map((part) => part.syllabusUnits.length),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test('5: total Group-II syllabus units is 61', () {
    final paperI = groupII.papers
        .singleWhere((paper) => paper.id == 'group-ii-paper-i')
        .syllabusUnits
        .length;
    final partUnits = groupII.papers
        .skip(1)
        .expand((paper) => paper.parts)
        .expand((part) => part.syllabusUnits)
        .length;
    expect(paperI + partUnits, 61);
  });

  test('6: no Group-II syllabus unit introduces a lesson child', () {
    final paperIUnits = groupII.papers
        .singleWhere((paper) => paper.id == 'group-ii-paper-i')
        .syllabusUnits;
    final partUnits = groupII.papers
        .skip(1)
        .expand((paper) => paper.parts)
        .expand((part) => part.syllabusUnits);
    final units = [...paperIUnits, ...partUnits];
    expect(units, hasLength(61));
    expect(units.every((unit) => unit.id.isNotEmpty), isTrue);
    expect(units.every((unit) => unit.officialName.isNotEmpty), isTrue);
    expect(units.every((unit) => unit.displayName.isNotEmpty), isTrue);
  });

  test('Papers II–IV syllabusUnitId reuses canonical Topic IDs', () {
    for (final paper in groupII.papers.skip(1)) {
      for (final part in paper.parts) {
        expect(
          part.syllabusUnits.map((unit) => unit.id),
          part.topics.map((topic) => topic.id),
          reason: part.id,
        );
      }
    }
  });
}
