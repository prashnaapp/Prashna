import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/study_planner/data/services/canonical_planner_service.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';
import 'package:telangana_prep/features/syllabus/data/models/syllabus_models.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

void main() {
  final service = CanonicalPlannerService();

  test('1/14: Group-II Paper-I returns 11 area-based units', () {
    final items = service.getCanonicalPlannerItemsForPaper(
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
    );

    expect(items, hasLength(11));
    expect(
      items.every(
        (item) =>
            item.scope.shape == CanonicalScopeShape.groupIiPaperI &&
            item.partId == null &&
            item.syllabusUnitId.startsWith('group-ii-paper-i-area-') &&
            item.scope.contentTopicId == null &&
            item.scope.canonicalTopicId == null &&
            item.scope.lessonId == null,
      ),
      isTrue,
    );
    expect(
      items.first.scopeKey,
      'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
    );
  });

  test('2/3/15: Group-II Papers II-IV return 20, 15, and 15 units', () {
    expect(
      service
          .getCanonicalPlannerItemsForPaper(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-ii',
          )
          .length,
      20,
    );
    expect(
      service
          .getCanonicalPlannerItemsForPaper(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-iii',
          )
          .length,
      15,
    );
    expect(
      service
          .getCanonicalPlannerItemsForPaper(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-iv',
          )
          .length,
      15,
    );
  });

  test('3/9/10: Group-II total is 61 with unique scopeKeys', () {
    final items = service.getCanonicalPlannerItems('group-ii');
    final keys = items.map((item) => item.scopeKey).toSet();

    expect(items, hasLength(61));
    expect(keys, hasLength(61));
    expect(items.every((item) => item.scope.courseId == 'group-ii'), isTrue);
  });

  test('5/6: Group-III Paper-I returns 11 direct units', () {
    final items = service.getCanonicalPlannerItemsForPaper(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-i',
    );

    expect(items, hasLength(11));
    expect(
      items.every(
        (item) =>
            item.scope.shape == CanonicalScopeShape.groupIiiPaperUnit &&
            item.partId == null,
      ),
      isTrue,
    );
  });

  test('6: Group-III Paper-II returns 5, 10, and 5 units by part', () {
    expect(
      service
          .getCanonicalPlannerItemsForPart(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-i',
          )
          .length,
      5,
    );
    expect(
      service
          .getCanonicalPlannerItemsForPart(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-ii',
          )
          .length,
      10,
    );
    expect(
      service
          .getCanonicalPlannerItemsForPart(
            courseId: 'group-iii',
            paperId: 'group-iii-paper-ii',
            partId: 'group-iii-paper-ii-part-iii',
          )
          .length,
      5,
    );
  });

  test('7: Group-III Paper-III returns 15 units', () {
    final items = service.getCanonicalPlannerItemsForPaper(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-iii',
    );

    expect(items, hasLength(15));
    expect(
      items.every(
        (item) =>
            item.scope.shape == CanonicalScopeShape.groupIiiPartUnit &&
            item.partId != null,
      ),
      isTrue,
    );
  });

  test('7/9/10/13/16/17: Group-III total and scope shapes are valid', () {
    final items = service.getCanonicalPlannerItems('group-iii');
    final keys = items.map((item) => item.scopeKey).toSet();

    expect(items, hasLength(46));
    expect(keys, hasLength(46));
    for (final item in items) {
      item.scope.validate();
      expect(item.scope.courseId, 'group-iii');
      expect(item.scope.majorStudyAreaId, isNull);
      expect(item.scope.contentTopicId, isNull);
      expect(item.scope.canonicalTopicId, isNull);
      expect(item.scope.lessonId, isNull);
      if (item.paperId == 'group-iii-paper-i') {
        expect(item.partId, isNull);
        expect(item.scope.shape, CanonicalScopeShape.groupIiiPaperUnit);
      } else {
        expect(item.partId, isNotNull);
        expect(item.scope.shape, CanonicalScopeShape.groupIiiPartUnit);
      }
    }
  });

  test('8/18: canonical order is preserved', () {
    final syllabus = SyllabusService.instance;
    final course = syllabus.getCourseById('group-iii')!;
    final expected = <String>[
      for (final paper in course.papers)
        if (paper.syllabusUnits.isNotEmpty)
          for (final unit in paper.syllabusUnits) unit.id
        else
          for (final part in paper.parts)
            for (final unit in part.syllabusUnits) unit.id,
    ];
    final actual = service
        .getCanonicalPlannerItems('group-iii')
        .map((item) => item.syllabusUnitId)
        .toList();

    expect(actual, expected);
  });

  test('11/12: canonical items never use topic or lesson identity', () {
    final items = [
      ...service.getCanonicalPlannerItems('group-ii'),
      ...service.getCanonicalPlannerItems('group-iii'),
    ];

    expect(
      items.every(
        (item) =>
            !item.syllabusUnitId.contains('-lesson-') &&
            item.syllabusUnitId.isNotEmpty,
      ),
      isTrue,
    );
    expect(items.every((item) => item.scopeKey == item.scope.scopeKey), isTrue);
  });

  test('15/17: Group-II parts and Group-III part units retain partId', () {
    final groupIiParts = service
        .getCanonicalPlannerItems('group-ii')
        .where((item) => item.paperId != 'group-ii-paper-i');
    final groupIiiParts = service
        .getCanonicalPlannerItems('group-iii')
        .where((item) => item.paperId != 'group-iii-paper-i');

    expect(groupIiParts.every((item) => item.partId != null), isTrue);
    expect(groupIiiParts.every((item) => item.partId != null), isTrue);
  });

  test('19: malformed canonical data is rejected', () {
    final malformed = SyllabusCourse(
      id: 'group-iii',
      name: 'Malformed',
      subtitle: '',
      totalMarks: 1,
      isEnrolled: true,
      isAvailable: true,
      icon: '',
      papers: [
        SyllabusPaper(
          id: 'group-iii-paper-i',
          title: 'Paper I',
          syllabusUnits: const [
            SyllabusUnit(id: '', officialName: 'Bad', displayName: 'Bad'),
          ],
        ),
      ],
    );
    final malformedService = CanonicalPlannerService(
      courseLoader: (_) => malformed,
    );

    expect(
      () => malformedService.getCanonicalPlannerItems('group-iii'),
      throwsA(isA<CanonicalPlannerValidationException>()),
    );
  });

  test('19: missing course, paper, and part are rejected', () {
    expect(
      () => service.getCanonicalPlannerItems(''),
      throwsA(isA<CanonicalPlannerValidationException>()),
    );
    expect(
      () => service.getCanonicalPlannerItemsForPaper(
        courseId: 'group-iii',
        paperId: 'missing',
      ),
      throwsA(isA<CanonicalPlannerValidationException>()),
    );
    expect(
      () => service.getCanonicalPlannerItemsForPart(
        courseId: 'group-iii',
        paperId: 'group-iii-paper-i',
        partId: 'missing',
      ),
      throwsA(isA<CanonicalPlannerValidationException>()),
    );
  });

  test('19: a paper cannot mix direct units and parts', () {
    final malformed = SyllabusCourse(
      id: 'group-iii',
      name: 'Malformed',
      subtitle: '',
      totalMarks: 1,
      isEnrolled: true,
      isAvailable: true,
      icon: '',
      papers: [
        SyllabusPaper(
          id: 'group-iii-paper-i',
          title: 'Paper I',
          syllabusUnits: const [
            SyllabusUnit(id: 'group-iii-paper-i-unit-01', officialName: 'A', displayName: 'A'),
          ],
          parts: const [
            SyllabusPart(
              id: 'group-iii-paper-i-part-i',
              officialName: 'Part',
              displayName: 'Part',
              syllabusUnits: [
                SyllabusUnit(
                  id: 'group-iii-paper-i-part-i-unit-01',
                  officialName: 'B',
                  displayName: 'B',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(
      () => CanonicalPlannerService(courseLoader: (_) => malformed)
          .getCanonicalPlannerItems('group-iii'),
      throwsA(isA<CanonicalPlannerValidationException>()),
    );
  });
}
