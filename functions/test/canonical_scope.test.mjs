import assert from 'node:assert/strict';
import test from 'node:test';

import {
  buildScopeKey,
  tryResolveCanonicalScope,
  validateCanonicalScope,
  CanonicalScopeShape,
  buildSnapshotAttribution,
} from '../src/canonical_scope.js';
import {
  buildQuestionSnapshot,
  buildTestSnapshot,
  toStudentSafeQuestion,
} from '../src/attempt_snapshot.js';

test('A: valid Group-II Paper-I scope', () => {
  const scope = validateCanonicalScope({
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    syllabusUnitId: 'group-ii-paper-i-area-01',
    shape: CanonicalScopeShape.groupIiPaperI,
    majorStudyAreaId: 'group-ii-paper-i-area-01',
    contentTopicId: 'group-ii-paper-i-area-01-topic-01',
  });
  assert.equal(scope.partId, null);
  assert.equal(scope.syllabusUnitId, scope.majorStudyAreaId);
  assert.equal(
    scope.scopeKey,
    'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
  );
});

test('B/C/D: valid Group-II part + Group-III scopes', () => {
  const gii = validateCanonicalScope({
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    syllabusUnitId: 'group-ii-paper-ii-part-01-topic-04',
    shape: CanonicalScopeShape.groupIiPartUnit,
    canonicalTopicId: 'group-ii-paper-ii-part-01-topic-04',
  });
  assert.equal(gii.majorStudyAreaId, null);

  const giiiPaper = validateCanonicalScope({
    courseId: 'group-iii',
    paperId: 'group-iii-paper-i',
    syllabusUnitId: 'group-iii-paper-i-unit-01',
    shape: CanonicalScopeShape.groupIiiPaperUnit,
  });
  assert.equal(giiiPaper.partId, null);

  const giiiPart = validateCanonicalScope({
    courseId: 'group-iii',
    paperId: 'group-iii-paper-iii',
    partId: 'group-iii-paper-iii-part-i',
    syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
    shape: CanonicalScopeShape.groupIiiPartUnit,
  });
  assert.equal(giiiPart.lessonId, null);
});

test('E: invalid shape combinations are rejected', () => {
  assert.throws(() =>
    validateCanonicalScope({
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      syllabusUnitId: 'group-ii-paper-i-area-01',
      shape: CanonicalScopeShape.groupIiPaperI,
      majorStudyAreaId: 'group-ii-paper-i-area-01',
      partId: 'nope',
    }),
  );
});

test('F/G/H: scopeKey deterministic without display/legacy ids', () => {
  const key = buildScopeKey({
    courseId: 'group-ii',
    paperId: 'group-ii-paper-i',
    partId: null,
    syllabusUnitId: 'group-ii-paper-i-area-01',
  });
  assert.equal(key, 'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01');
  assert.equal(key.includes('Current Affairs'), false);
  assert.equal(key.includes('topic-1'), false);
});

test('M: snapshot preserves separate canonical fields', () => {
  const snap = buildQuestionSnapshot(
    'q17',
    {
      courseId: 'group-ii',
      paperId: 'group-ii-paper-i',
      majorStudyAreaId: 'group-ii-paper-i-area-01',
      contentTopicId: 'group-ii-paper-i-area-01-topic-01',
      question: 'Text',
      explanation: 'Why',
      correctOption: 'B',
      options: [
        { label: 'A', text: 'A' },
        { label: 'B', text: 'B' },
        { label: 'C', text: 'C' },
        { label: 'D', text: 'D' },
      ],
    },
    0,
    'group-ii',
  );

  assert.equal(snap.syllabusUnitId, 'group-ii-paper-i-area-01');
  assert.equal(snap.majorStudyAreaId, 'group-ii-paper-i-area-01');
  assert.equal(snap.contentTopicId, 'group-ii-paper-i-area-01-topic-01');
  assert.equal(snap.scopeShape, CanonicalScopeShape.groupIiPaperI);
  assert.equal(
    snap.scopeKey,
    'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
  );
  assert.equal(snap.correctOption, 'B');

  const safe = toStudentSafeQuestion(snap);
  assert.equal(safe.correctOption, undefined);
  assert.equal(safe.explanation, undefined);
  assert.equal(safe.scopeKey, snap.scopeKey);
  assert.equal(safe.majorStudyAreaId, snap.majorStudyAreaId);
  // Paper-I: omit absent part/topic/lesson — never undefined Firestore fields.
  assert.ok(!('partId' in safe));
  assert.ok(!('canonicalTopicId' in safe));
  assert.ok(!('lessonId' in safe));
  assert.ok(
    Object.values(safe).every((value) => value !== undefined),
    'student-safe payload must not contain undefined values',
  );
});

test('N: snapshot does NOT collapse topicId into syllabusUnitId via ??', () => {
  const attribution = buildSnapshotAttribution(
    {
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      // Ambiguous/incomplete: topic only, no part → unresolved.
      topicId: 'topic-1',
    },
    'group-ii',
  );
  assert.equal(attribution.syllabusUnitId, null);
  assert.equal(attribution.scopeKey, null);
  assert.equal(attribution.topicId, 'topic-1');

  // Valid Group-II part unit resolves via validated scope (not ?? collapse).
  const resolved = tryResolveCanonicalScope({
    courseId: 'group-ii',
    paperId: 'group-ii-paper-ii',
    partId: 'group-ii-paper-ii-part-01',
    topicId: 'group-ii-paper-ii-part-01-topic-04',
  });
  assert.ok(resolved);
  assert.equal(resolved.syllabusUnitId, 'group-ii-paper-ii-part-01-topic-04');
  assert.equal(
    resolved.canonicalTopicId,
    'group-ii-paper-ii-part-01-topic-04',
  );

  const snap = buildQuestionSnapshot(
    'q18',
    {
      courseId: 'group-ii',
      paperId: 'group-ii-paper-ii',
      partId: 'group-ii-paper-ii-part-01',
      topicId: 'group-ii-paper-ii-part-01-topic-04',
      question: 'Text',
      explanation: 'Why',
      correctOption: 'A',
      options: [
        { label: 'A', text: 'A' },
        { label: 'B', text: 'B' },
        { label: 'C', text: 'C' },
        { label: 'D', text: 'D' },
      ],
    },
    0,
    'group-ii',
  );
  assert.equal(snap.syllabusUnitId, 'group-ii-paper-ii-part-01-topic-04');
  assert.equal(snap.canonicalTopicId, 'group-ii-paper-ii-part-01-topic-04');
  assert.equal(snap.scopeShape, CanonicalScopeShape.groupIiPartUnit);
});

test('test snapshot preserves Group-III part/unit fields', () => {
  const snap = buildTestSnapshot(
    {
      id: 't1',
      courseId: 'group-iii',
      title: 'Agri',
      paperId: 'group-iii-paper-iii',
      partId: 'group-iii-paper-iii-part-i',
      syllabusUnitId: 'group-iii-paper-iii-part-i-unit-03',
      category: 'chapter',
    },
    {
      questionCount: 1,
      totalMarks: 1,
      durationSeconds: 60,
      negativeMarks: 0,
      scoringVersion: 'v1',
    },
  );
  assert.equal(snap.syllabusUnitId, 'group-iii-paper-iii-part-i-unit-03');
  assert.equal(snap.scopeShape, CanonicalScopeShape.groupIiiPartUnit);
  assert.equal(
    snap.scopeKey,
    'v1|group-iii|group-iii-paper-iii|group-iii-paper-iii-part-i|'
      + 'group-iii-paper-iii-part-i-unit-03',
  );
});
