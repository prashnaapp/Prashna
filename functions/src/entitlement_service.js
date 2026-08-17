/**
 * Trusted server-side entitlement service.
 *
 * Writes ONLY to user_courses/{uid}/courses/{courseId}.
 * Clients must never call this — Admin SDK / Cloud Functions only.
 */
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

import { ENTITLEMENT_SOURCES, entitlementDoc } from './ids.js';

function assertUid(uid) {
  if (typeof uid !== 'string' || uid.trim().length === 0) {
    throw new Error('uid is required');
  }
}

function assertCourseId(courseId) {
  if (typeof courseId !== 'string' || courseId.trim().length === 0) {
    throw new Error('courseId is required');
  }
}

function assertSource(source) {
  if (!ENTITLEMENT_SOURCES.includes(source)) {
    throw new Error(
      `source must be one of: ${ENTITLEMENT_SOURCES.join(', ')}`,
    );
  }
}

function toTimestampOrNull(value) {
  if (value == null) return null;
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === 'string' || typeof value === 'number') {
    const date = new Date(value);
    if (Number.isNaN(date.getTime())) {
      throw new Error('expiresAt is not a valid date');
    }
    return Timestamp.fromDate(date);
  }
  throw new Error('expiresAt must be a Date, Timestamp, ISO string, or null');
}

function serializeEntitlement(uid, courseId, data) {
  if (!data) return null;
  return {
    uid: data.uid ?? uid,
    courseId: data.courseId ?? courseId,
    status: data.status ?? null,
    source: data.source ?? null,
    enrolledAt: data.enrolledAt ?? null,
    expiresAt: data.expiresAt ?? null,
    updatedAt: data.updatedAt ?? null,
  };
}

/**
 * Effective entitlement status for access decisions.
 * Matches Flutter CourseEntitlement.resolveStatus semantics.
 */
export function resolveEffectiveStatus(data, { now = () => new Date() } = {}) {
  if (!data) return null;
  const status = data.status;
  if (status === 'inactive' || status === 'revoked') return 'revoked';
  if (status !== 'active') return status ?? null;
  const expiresAt = data.expiresAt;
  if (expiresAt && typeof expiresAt.toDate === 'function') {
    if (expiresAt.toDate().getTime() <= now().getTime()) return 'expired';
  }
  return 'active';
}

export function createEntitlementService(db) {
  return {
    /**
     * Upsert an active entitlement. Does not delete prior documents.
     * Preserves enrolledAt when the document already exists.
     */
    async grant({ uid, courseId, source, expiresAt = null }) {
      assertUid(uid);
      assertCourseId(courseId);
      assertSource(source);
      const expires = toTimestampOrNull(expiresAt);
      const ref = entitlementDoc(db, uid, courseId);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        const existing = snap.exists ? snap.data() : null;
        const payload = {
          uid,
          courseId,
          status: 'active',
          source,
          expiresAt: expires,
          updatedAt: FieldValue.serverTimestamp(),
          enrolledAt:
            existing?.enrolledAt != null
              ? existing.enrolledAt
              : FieldValue.serverTimestamp(),
        };
        tx.set(ref, payload, { merge: true });
      });

      return this.get(uid, courseId);
    },

    /**
     * Soft-revoke. Document is retained with status=revoked.
     * Compatible with legacy inactive documents (does not delete them).
     */
    async revoke(uid, courseId) {
      assertUid(uid);
      assertCourseId(courseId);
      const ref = entitlementDoc(db, uid, courseId);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) {
          tx.set(
            ref,
            {
              uid,
              courseId,
              status: 'revoked',
              source: 'admin',
              expiresAt: null,
              enrolledAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          return;
        }
        tx.set(
          ref,
          {
            status: 'revoked',
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      return this.get(uid, courseId);
    },

    /**
     * Set an explicit resulting expiresAt. Does not add durations.
     * Reactivates status to active when extending a non-revoked grant;
     * revoked entitlements must be grant()'d again intentionally.
     */
    async extend(uid, courseId, expiresAt) {
      assertUid(uid);
      assertCourseId(courseId);
      if (expiresAt == null) {
        throw new Error('expiresAt is required for extend');
      }
      const expires = toTimestampOrNull(expiresAt);
      const ref = entitlementDoc(db, uid, courseId);

      await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) {
          throw new Error(
            `Cannot extend missing entitlement for ${uid}/${courseId}`,
          );
        }
        const current = snap.data() || {};
        if (current.status === 'revoked' || current.status === 'inactive') {
          throw new Error(
            'Cannot extend a revoked/inactive entitlement; grant again first',
          );
        }
        tx.set(
          ref,
          {
            status: 'active',
            expiresAt: expires,
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });

      return this.get(uid, courseId);
    },

    async get(uid, courseId) {
      assertUid(uid);
      assertCourseId(courseId);
      const snap = await entitlementDoc(db, uid, courseId).get();
      if (!snap.exists) return null;
      return serializeEntitlement(uid, courseId, snap.data());
    },
  };
}
