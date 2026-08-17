import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/progress_models.dart';
import 'package:telangana_prep/features/study_planner/data/services/study_planner_calculator.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

const _courseId = 'group-ii';
const _paperIII = 'group-ii-paper-iii';
const _partI = 'group-ii-paper-iii-part-01';
const _topic = 'group-ii-paper-iii-part-01-topic-03';
const _lesson01 = 'group-ii-paper-iii-part-01-topic-03-lesson-01';

void main() {
  OverallProgress progressWithCanonicalLessons({
    Iterable<ChapterProgress> chapters = const [],
  }) {
    return OverallProgress(
      examId: _courseId,
      examTitle: 'Group-II',
      maxMarks: 1,
      coveredMarks: 0,
      progressPercent: 0,
      remainingMarks: 1,
      papers: [
        PaperProgress(
          id: _paperIII,
          label: 'Paper III',
          maxMarks: 1,
          coveredMarks: 0,
          progressPercent: 0,
          remainingMarks: 1,
          parts: [
            PartProgress(
              id: _partI,
              label: 'Indian Economy: Issues and Challenges',
              maxMarks: 1,
              coveredMarks: 0,
              progressPercent: 0,
              remainingMarks: 1,
              chapters: chapters.toList(),
            ),
          ],
        ),
      ],
    );
  }

  test('Paper I uses Major Study Area and Content Topic only', () {
    final overall = OverallProgress(
      examId: _courseId,
      examTitle: 'Group-II',
      maxMarks: 1,
      coveredMarks: 0,
      progressPercent: 0,
      remainingMarks: 1,
      papers: const [],
    );
    final units = StudyPlannerCalculator.flattenCanonical(overall);
    final paperIUnits = units.where(
      (unit) => unit.paperId == 'group-ii-paper-i',
    );

    expect(paperIUnits, isNotEmpty);
    expect(
      paperIUnits.every(
        (unit) =>
            unit.majorStudyAreaId != null &&
            unit.contentTopicId != null &&
            unit.partId == null &&
            unit.lessonId == null,
      ),
      isTrue,
    );
  });

  test('Papers II–IV use Part, Topic, and Lesson IDs', () {
    final overall = progressWithCanonicalLessons();
    final units = StudyPlannerCalculator.flattenCanonical(overall);
    final paperUnits = units.where((unit) => unit.paperId == _paperIII);

    expect(paperUnits, isNotEmpty);
    expect(
      paperUnits.every(
        (unit) =>
            unit.partId != null &&
            unit.topicId != null &&
            unit.lessonId != null,
      ),
      isTrue,
    );
    expect(
      paperUnits.any(
        (unit) =>
            unit.partId == _partI &&
            unit.topicId == _topic &&
            unit.lessonId == _lesson01,
      ),
      isTrue,
    );
  });

  test('lesson, topic, part, paper, and course aggregation is cumulative', () {
    final targetTopic = SyllabusService.instance.getCanonicalTopic(
      courseId: _courseId,
      paperId: _paperIII,
      partId: _partI,
      topicId: _topic,
    )!;
    final completedLessons = [
      for (final lesson in targetTopic.lessons)
        ChapterProgress(
          id: lesson.id,
          label: lesson.displayName,
          maxMarks: 1,
          coveredMarks: 1,
          progressPercent: 100,
          remainingMarks: 0,
          status: 'Complete',
        ),
    ];
    final units = StudyPlannerCalculator.flattenCanonical(
      progressWithCanonicalLessons(chapters: completedLessons),
    );
    final topicUnits = units.where((unit) => unit.topicId == _topic).toList();
    final partUnits = units.where((unit) => unit.partId == _partI).toList();
    final paperUnits = units
        .where((unit) => unit.paperId == _paperIII)
        .toList();

    final lesson = topicUnits.singleWhere((unit) => unit.lessonId == _lesson01);
    expect(lesson.isComplete, isTrue);
    expect(StudyPlannerCalculator.aggregateByTopic(topicUnits).percent, 100);
    expect(
      StudyPlannerCalculator.aggregateByPart(partUnits).completed,
      completedLessons.length,
    );
    expect(
      StudyPlannerCalculator.aggregateByPaper(paperUnits).completed,
      completedLessons.length,
    );
    expect(
      StudyPlannerCalculator.aggregateCourse(units).completed,
      completedLessons.length,
    );
  });

  test('legacy section/topic IDs do not become canonical Parts', () {
    final units = StudyPlannerCalculator.flattenCanonical(
      progressWithCanonicalLessons(
        chapters: [
          const ChapterProgress(
            id: 'topic-1',
            label: 'Legacy topic',
            maxMarks: 1,
            coveredMarks: 1,
            progressPercent: 100,
            remainingMarks: 0,
            status: 'Complete',
          ),
        ],
      ),
    );
    final lesson = units.singleWhere((unit) => unit.lessonId == _lesson01);

    expect(lesson.isComplete, isFalse);
    expect(lesson.partId, _partI);
    expect(lesson.partId, isNot('section-1'));
  });

  test('study weighting is internal and topic weighting is dynamic', () {
    final syllabus = SyllabusService.instance;
    final part = syllabus.getPart(
      courseId: _courseId,
      paperId: _paperIII,
      partId: _partI,
    )!;
    final paperI = syllabus.getPaper(
      courseId: _courseId,
      paperId: 'group-ii-paper-i',
    )!;

    expect(StudyPlannerCalculator.partStudyWeight(part), 50);
    expect(
      StudyPlannerCalculator.topicStudyWeight(part),
      50 / part.topics.length,
    );
    expect(paperI.parts, isEmpty);
  });
}
