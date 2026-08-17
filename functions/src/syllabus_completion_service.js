/**
 * Trusted syllabus-completion mutations.
 *
 * Path: user_progress/{uid}/syllabus_completion/{scopeKey}
 *
 * Completion is student-controlled and independent of UnitPerformance /
 * legacy progress / test scoring.
 */
import { FieldValue } from 'firebase-admin/firestore';

import {
  buildScopeKey,
  CanonicalScopeShape,
  validateCanonicalScope,
} from './canonical_scope.js';
import { findCanonicalSyllabusUnit } from './canonical_syllabus_catalog.js';
import { assertCourseAccess } from './course_access.js';

export const SyllabusCompletionStatus = Object.freeze({
  notStarted: 'not_started',
  inProgress: 'in_progress',
  completed: 'completed',
});

export function syllabusCompletionRef(db, uid, scopeKey) {
  return db
    .collection('user_progress')
    .doc(uid)
    .collection('syllabus_completion')
    .doc(scopeKey);
}

function trimString(value) {
  if (value == null) return '';
  return String(value).trim();
}

function optionalId(value) {
  const trimmed = trimString(value);
  return trimmed || null;
}

function requireId(value, field) {
  const trimmed = trimString(value);
  if (!trimmed) {
    const error = new Error(`${field} is required.`);
    error.code = 'invalid-argument';
    throw error;
  }
  return trimmed;
}

function parseStatus(raw) {
  const status = trimString(raw);
  if (
    status !== SyllabusCompletionStatus.notStarted &&
    status !== SyllabusCompletionStatus.inProgress &&
    status !== SyllabusCompletionStatus.completed
  ) {
    const error = new Error(
      'status must be not_started, in_progress, or completed.',
    );
    error.code = 'invalid-argument';
    throw error;
  }
  return status;
}

/**
 * Resolve + validate a scope from client hierarchy fields.
 * Never trusts a client-supplied uid or scopeKey as identity.
 */
export function resolveValidatedCompletionScope(input = {}) {
  const courseId = requireId(input.courseId, 'courseId');
  const paperId = requireId(input.paperId, 'paperId');
  const syllabusUnitId = requireId(input.syllabusUnitId, 'syllabusUnitId');
  const partId = optionalId(input.partId);

  const catalogEntry = findCanonicalSyllabusUnit({
    courseId,
    paperId,
    partId,
    syllabusUnitId,
  });
  if (!catalogEntry) {
    const error = new Error(
      'Unknown or invalid canonical syllabus unit for the given hierarchy.',
    );
    error.code = 'not-found';
    throw error;
  }

  const shape = catalogEntry.shape;
  const scopeInput = {
    courseId,
    paperId,
    partId,
    syllabusUnitId,
    shape,
  };

  if (shape === CanonicalScopeShape.groupIiPaperI) {
    scopeInput.majorStudyAreaId = syllabusUnitId;
  } else if (shape === CanonicalScopeShape.groupIiPartUnit) {
    scopeInput.canonicalTopicId = syllabusUnitId;
  }

  const scope = validateCanonicalScope(scopeInput);

  // Reject spoofed scopeKey if the client sent one.
  const clientScopeKey = optionalId(input.scopeKey);
  if (clientScopeKey != null && clientScopeKey !== scope.scopeKey) {
    const error = new Error('scopeKey does not match canonical identity.');
    error.code = 'invalid-argument';
    throw error;
  }

  return scope;
}

export function createSyllabusCompletionService(db, { now = () => new Date() } = {}) {
  async function setCompletionStatus({
    uid,
    courseId,
    paperId,
    partId = null,
    syllabusUnitId,
    status,
    scopeKey: clientScopeKey = null,
  }) {
    const authUid = requireId(uid, 'uid');
    const parsedStatus = parseStatus(status);
    const scope = resolveValidatedCompletionScope({
      courseId,
      paperId,
      partId,
      syllabusUnitId,
      scopeKey: clientScopeKey,
    });

    // Course access for the scope's course — never trust client uid/course alone.
    await assertCourseAccess(db, authUid, scope.courseId, { now });

    const ref = syllabusCompletionRef(db, authUid, scope.scopeKey);

    if (parsedStatus === SyllabusCompletionStatus.notStarted) {
      await ref.delete();
      return {
        status: SyllabusCompletionStatus.notStarted,
        scopeKey: scope.scopeKey,
        courseId: scope.courseId,
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
        scopeShape: scope.shape,
        completion: null,
      };
    }

    const payload = {
      uid: authUid,
      scopeKey: scope.scopeKey,
      courseId: scope.courseId,
      paperId: scope.paperId,
      partId: scope.partId,
      syllabusUnitId: scope.syllabusUnitId,
      scopeShape: scope.shape,
      status: parsedStatus,
      updatedAt: FieldValue.serverTimestamp(),
      schemaVersion: 1,
    };

    if (parsedStatus === SyllabusCompletionStatus.completed) {
      payload.completedAt = FieldValue.serverTimestamp();
    } else {
      payload.completedAt = null;
    }

    await ref.set(payload, { merge: false });

    const snap = await ref.get();
    const data = snap.data() || payload;

    return {
      status: parsedStatus,
      scopeKey: scope.scopeKey,
      courseId: scope.courseId,
      paperId: scope.paperId,
      partId: scope.partId,
      syllabusUnitId: scope.syllabusUnitId,
      scopeShape: scope.shape,
      completion: {
        uid: authUid,
        scopeKey: scope.scopeKey,
        courseId: scope.courseId,
        paperId: scope.paperId,
        partId: scope.partId,
        syllabusUnitId: scope.syllabusUnitId,
        scopeShape: scope.shape,
        status: parsedStatus,
        updatedAt: data.updatedAt ?? null,
        completedAt:
          parsedStatus === SyllabusCompletionStatus.completed
            ? data.completedAt ?? null
            : null,
        schemaVersion: 1,
      },
    };
  }

  return {
    setCompletionStatus,
    buildScopeKey,
  };
}
