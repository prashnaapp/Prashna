/**
 * Course access for server-side test attempts.
 * Mirrors Flutter SubscriptionAccessService / firestore.rules canAccessCourse:
 * free course OR active (non-expired, non-revoked) entitlement.
 */
import { resolveEffectiveStatus } from './entitlement_service.js';
import { entitlementDoc } from './ids.js';

export async function assertCourseAccess(db, uid, courseId, { now = () => new Date() } = {}) {
  const courseSnap = await db.collection('courses').doc(courseId).get();
  if (courseSnap.exists) {
    const course = courseSnap.data() || {};
    if (course.isFree === true) {
      return { allowed: true, reason: 'free_course' };
    }
  }

  const entSnap = await entitlementDoc(db, uid, courseId).get();
  if (!entSnap.exists) {
    const error = new Error('Course access denied.');
    error.code = 'permission-denied';
    throw error;
  }

  const effective = resolveEffectiveStatus(entSnap.data(), { now });
  if (effective !== 'active') {
    const error = new Error(
      `Course access denied (entitlement status: ${effective || 'missing'}).`,
    );
    error.code = 'permission-denied';
    throw error;
  }

  return { allowed: true, reason: 'active_entitlement' };
}
