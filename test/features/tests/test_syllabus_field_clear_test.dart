import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/data/models/canonical_scope.dart';
import 'package:telangana_prep/features/tests/data/models/test_models.dart';
import 'package:telangana_prep/features/tests/data/test_cloud_mapper.dart';
import 'package:telangana_prep/features/tests/repository/test_cloud_repository.dart';

void main() {
  TestModel testModel({
    String? syllabusUnitId = 'unit-a',
    String? canonicalTopicId = 'topic-a',
    CanonicalScopeShape? scopeShape = CanonicalScopeShape.groupIiiPartUnit,
    String? paperId = 'group-iii-paper-ii',
  }) {
    return TestModel(
      id: 't-stale',
      examId: 'group-iii',
      category: TestCategoryType.partTests,
      title: 'Group-III Practice Test',
      questionCount: 10,
      marks: 10,
      durationMinutes: 30,
      negativeMarking: '0',
      difficulty: 'Medium',
      status: TestPublicationStatus.draft,
      paperId: paperId,
      partId: 'group-iii-paper-ii-part-i',
      syllabusUnitId: syllabusUnitId,
      canonicalTopicId: canonicalTopicId,
      scopeShape: scopeShape,
    );
  }

  Map<String, dynamic> applyUpdate(
    Map<String, dynamic> existing,
    Map<String, dynamic> update,
  ) {
    final next = Map<String, dynamic>.from(existing);
    update.forEach((key, value) {
      if (_isDelete(value)) {
        next.remove(key);
      } else if (value is! FieldValue) {
        next[key] = value;
      }
    });
    return next;
  }

  test('6: existing syllabusUnitId is replaced on update', () {
    final data = TestCloudMapper.toFirestore(
      testModel(syllabusUnitId: 'unit-b'),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(data['syllabusUnitId'], 'unit-b');
    expect(_isDelete(data['syllabusUnitId']), isFalse);
  });

  test('7: existing syllabusUnitId is deleted when explicitly cleared', () {
    final data = TestCloudMapper.toFirestore(
      testModel(syllabusUnitId: null),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['syllabusUnitId']), isTrue);

    final stored = applyUpdate({
      'syllabusUnitId': 'unit-a',
      'courseId': 'group-iii',
      'title': 'Group-III Practice Test',
    }, data);
    expect(stored.containsKey('syllabusUnitId'), isFalse);
    expect(stored['courseId'], 'group-iii');
    expect(stored['title'], 'Group-III Practice Test');
  });

  test('8: existing canonicalTopicId is deleted when explicitly cleared', () {
    final data = TestCloudMapper.toFirestore(
      testModel(canonicalTopicId: null),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['canonicalTopicId']), isTrue);
  });

  test('9: existing scopeShape is deleted when explicitly cleared', () {
    final data = TestCloudMapper.toFirestore(
      testModel(scopeShape: null),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(_isDelete(data['scopeShape']), isTrue);
  });

  test('10: required fields remain intact on update', () {
    final data = TestCloudMapper.toFirestore(
      testModel(syllabusUnitId: null, canonicalTopicId: null, scopeShape: null),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(data['id'], 't-stale');
    expect(data['courseId'], 'group-iii');
    expect(data['title'], 'Group-III Practice Test');
    expect(data['category'], 'part');
    expect(data['questionCount'], 10);
    expect(data['isPublished'], isFalse);
    expect(_isDelete(data['id']), isFalse);
    expect(_isDelete(data['courseId']), isFalse);
    expect(_isDelete(data['title']), isFalse);
  });

  test('create omits empty optional fields instead of deleting them', () {
    final data = TestCloudMapper.toFirestore(
      testModel(syllabusUnitId: null, canonicalTopicId: null, scopeShape: null),
      documentId: 't-stale',
    );
    expect(data.containsKey('syllabusUnitId'), isFalse);
    expect(data.containsKey('canonicalTopicId'), isFalse);
    expect(data.containsKey('scopeShape'), isFalse);
  });

  test('repository updateTest sends delete sentinels', () async {
    Map<String, dynamic>? updated;
    final repo = TestCloudRepository.withLoader(
      (_) async => const [],
      update: ({required testId, required data}) async {
        updated = data;
      },
    );
    await repo.updateTest(testModel(syllabusUnitId: null));
    expect(updated, isNotNull);
    expect(_isDelete(updated!['syllabusUnitId']), isTrue);
    expect(updated!['courseId'], 'group-iii');
  });

  test('unrelated existing fields stay outside the update payload', () {
    final data = TestCloudMapper.toFirestore(
      testModel(syllabusUnitId: 'unit-b'),
      documentId: 't-stale',
      forUpdate: true,
    );
    expect(data.containsKey('instructions'), isFalse);
    expect(data.containsKey('legacyAnalytics'), isFalse);
  });
}

bool _isDelete(dynamic value) =>
    value is FieldValue && value == FieldValue.delete();
