import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/progress/data/models/unit_performance.dart';

void main() {
  test('UnitPerformance round-trips from Firestore map', () {
    final mapped = UnitPerformance.fromFirestore(
      'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|unit-02',
      {
        'scopeKey':
            'v1|group-iii|group-iii-paper-ii|group-iii-paper-ii-part-i|unit-02',
        'courseId': 'group-iii',
        'paperId': 'group-iii-paper-ii',
        'partId': 'group-iii-paper-ii-part-i',
        'syllabusUnitId': 'unit-02',
        'testsAttempted': 2,
        'testsCompleted': 2,
        'questionsAttempted': 5,
        'correct': 3,
        'wrong': 2,
        'skipped': 1,
        'totalMarks': 6,
        'marksObtained': 3,
        'accuracy': 60,
        'percentage': 50,
        'bestMarks': 3,
        'bestPercentage': 100,
        'lastTestId': 't1',
        'lastAttemptId': 'a1',
        'authority': 'server_verified',
        'schemaVersion': 1,
        'scopeShape': 'groupIiiPartUnit',
      },
    );

    expect(mapped.scopeKey, contains('unit-02'));
    expect(mapped.courseId, 'group-iii');
    expect(mapped.partId, 'group-iii-paper-ii-part-i');
    expect(mapped.isServerVerified, isTrue);
    expect(mapped.toMap()['correct'], 3);
    expect(mapped.toMap()['scopeKey'], mapped.scopeKey);
  });

  test('doc id is used when scopeKey field is absent', () {
    final mapped = UnitPerformance.fromFirestore(
      'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
      {
        'courseId': 'group-ii',
        'paperId': 'group-ii-paper-i',
        'syllabusUnitId': 'group-ii-paper-i-area-01',
        'testsAttempted': 1,
        'testsCompleted': 1,
        'questionsAttempted': 1,
        'correct': 1,
        'wrong': 0,
        'skipped': 0,
        'totalMarks': 1,
        'marksObtained': 1,
        'accuracy': 100,
        'percentage': 100,
        'bestMarks': 1,
        'bestPercentage': 100,
      },
    );
    expect(
      mapped.scopeKey,
      'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
    );
  });
}
