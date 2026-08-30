import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_papers_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_parts_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_unit_tests_screen.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_units_screen.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';
import 'package:telangana_prep/features/tests/services/test_service.dart';

void main() {
  const kakatiyaTopicId = 'group-ii-paper-ii-part-01-topic-04';

  TestModel groupIiUnitTest({
    String id = 'gii-unit-1',
    String syllabusUnitId = kakatiyaTopicId,
    TestPublicationStatus status = TestPublicationStatus.published,
  }) {
    return TestModel(
      id: id,
      examId: 'group-ii',
      category: TestCategoryType.chapterTests,
      title: 'Ancient and Medieval Telangana Test',
      questionCount: 10,
      marks: 10,
      durationMinutes: 20,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: status,
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      syllabusUnitId: syllabusUnitId,
    );
  }

  testWidgets(
    '9: Group-II student navigation is Paper → Part → Syllabus Unit on one screen',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SyllabusPapersScreen(courseId: 'group-ii')),
      );
      await tester.pump();

      expect(find.text('Paper II'), findsOneWidget);
      expect(find.textContaining('Sections'), findsNothing);
      expect(find.byType(SyllabusPartsScreen), findsNothing);
      expect(find.byType(SyllabusUnitsScreen), findsNothing);

      await tester.tap(find.text('Paper II'));
      await tester.pump();

      expect(find.byType(SyllabusPapersScreen), findsOneWidget);
      expect(find.byType(SyllabusPartsScreen), findsNothing);
      expect(find.text('Select Part'), findsOneWidget);
      expect(find.text('Part - I'), findsOneWidget);
      expect(find.text('Ancient and Medieval Telangana'), findsOneWidget);
      expect(find.text('Topic *'), findsNothing);
      expect(find.text('Lesson'), findsNothing);
    },
  );

  testWidgets('Paper-I navigation is Paper → Syllabus Unit (no Parts)', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SyllabusPapersScreen(courseId: 'group-ii')),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('syllabus-paper-group-ii-paper-i')),
    );
    await tester.pump();

    expect(find.byType(SyllabusPapersScreen), findsOneWidget);
    expect(find.byType(SyllabusUnitsScreen), findsNothing);
    expect(find.byType(SyllabusPartsScreen), findsNothing);
    expect(find.text('Select Part'), findsNothing);
    expect(find.text('Current Affairs'), findsOneWidget);
  });

  testWidgets(
    'syllabus-unit tests screen looks up Group-II tests by syllabusUnitId',
    (tester) async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((courseId) async {
          expect(courseId, 'group-ii');
          return [groupIiUnitTest()];
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SyllabusUnitTestsScreen(
            courseId: 'group-ii',
            paperId: 'group-ii-paper-ii',
            partId: 'group-ii-paper-ii-part-01',
            unitId: kakatiyaTopicId,
            testService: service,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ancient and Medieval Telangana'), findsWidgets);
      expect(find.text('Ancient and Medieval Telangana Test'), findsOneWidget);
      expect(find.text('No tests available'), findsNothing);
    },
  );

  test(
    '10: Group-II unit lookup uses syllabusUnitId, not Topic/Lesson folders',
    () async {
      final service = TestService(
        cloudRepository: TestCloudRepository.withLoader((courseId) async {
          expect(courseId, 'group-ii');
          return [
            groupIiUnitTest(),
            groupIiUnitTest(
              id: 'other-unit',
              syllabusUnitId: 'group-ii-paper-ii-part-01-topic-01',
            ),
          ];
        }),
      );

      final tests = await service.getTestsForSyllabusUnit(
        courseId: 'group-ii',
        paperId: 'group-ii-paper-ii',
        partId: 'group-ii-paper-ii-part-01',
        syllabusUnitId: kakatiyaTopicId,
      );

      expect(tests, hasLength(1));
      expect(tests.single.id, 'gii-unit-1');
      expect(tests.single.syllabusUnitId, kakatiyaTopicId);
    },
  );
}
