/**
 * Voided Purchases API lookback configuration.
 *
 * Google Play Voided Purchases API hard limit (current docs):
 * startTime cannot be older than 30 days. Older voids are not returned
 * regardless of the requested startTime.
 *
 * https://developers.google.com/android-publisher/voided-purchases
 *
 * VOIDED_PURCHASE_LOOKBACK_DAYS (env) selects a window within that cap.
 * Default: 30 (maximum useful daily reconciliation coverage).
 */
export const GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS = 30;

export const MS_PER_DAY = 24 * 60 * 60 * 1000;

/**
 * @param {{ env?: NodeJS.ProcessEnv, defaultDays?: number }} [options]
 * @returns {number} lookback days in [1, GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS]
 */
export function resolveVoidedLookbackDays({
  env = process.env,
  defaultDays = GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
} = {}) {
  const raw = env?.VOIDED_PURCHASE_LOOKBACK_DAYS;
  let requested = defaultDays;
  if (raw != null && String(raw).trim() !== '') {
    requested = Number(raw);
  }
  if (!Number.isFinite(requested) || requested <= 0) {
    requested = defaultDays;
  }
  return Math.min(
    Math.max(1, Math.floor(requested)),
    GOOGLE_VOIDED_API_MAX_LOOKBACK_DAYS,
  );
}

export function lookbackWindowMs(lookbackDays, { now = () => new Date() } = {}) {
  const days = resolveVoidedLookbackDays({
    env: { VOIDED_PURCHASE_LOOKBACK_DAYS: String(lookbackDays) },
  });
  const endMs = now().getTime();
  return {
    lookbackDays: days,
    endMs,
    startMs: endMs - days * MS_PER_DAY,
  };
}
