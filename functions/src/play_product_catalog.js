/**
 * Server-side Google Play product → course entitlement mapping.
 *
 * Access duration is defined here (approved product configuration),
 * not claimed from Google Play itself.
 *
 * Play Console product IDs must match exactly.
 */
export const PLAY_PACKAGE_NAME = 'com.prashna.app';

export const PLAY_PROVIDER = 'google_play';

/** @type {Record<string, { courseId: string, accessDurationDays: number, planId: string, title: string }>} */
export const PLAY_PRODUCT_CATALOG = Object.freeze({
  group2_12m: Object.freeze({
    courseId: 'group-ii',
    accessDurationDays: 365,
    planId: 'group2_12m',
    title: 'Group II 12-Month Access',
  }),
});

export function resolvePlayProduct(productId) {
  const id = String(productId || '').trim();
  const mapping = PLAY_PRODUCT_CATALOG[id];
  if (!mapping) return null;
  return { productId: id, ...mapping };
}

export function computeExpiresAt(accessDurationDays, { from = new Date() } = {}) {
  const days = Number(accessDurationDays);
  if (!Number.isFinite(days) || days <= 0) {
    throw new Error('accessDurationDays must be a positive number');
  }
  return new Date(from.getTime() + days * 24 * 60 * 60 * 1000);
}
