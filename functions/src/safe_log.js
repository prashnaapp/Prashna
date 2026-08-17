/**
 * Safe diagnostic helpers for payment ops logs.
 * Never log purchase tokens or credentials in plaintext.
 */
import { createHash } from 'node:crypto';

export function fingerprintSecret(value) {
  const raw = String(value || '');
  if (!raw) return null;
  return createHash('sha256').update(raw).digest('hex').slice(0, 16);
}

export function sanitizeErrorMessage(error) {
  const message = String(error?.message || error || 'unknown');
  // Strip anything that looks like a bearer token / JSON private key fragment.
  return message
    .replace(/Bearer\s+[A-Za-z0-9._\-]+/gi, 'Bearer [REDACTED]')
    .replace(/-----BEGIN[^-]+-----[\s\S]*?-----END[^-]+-----/g, '[REDACTED_PEM]')
    .replace(/"private_key"\s*:\s*"[^"]*"/gi, '"private_key":"[REDACTED]"')
    .slice(0, 500);
}

export function createSafeLogger(sink = console) {
  return {
    info(event, payload = {}) {
      sink.info(JSON.stringify({ level: 'info', event, ...payload }));
    },
    warn(event, payload = {}) {
      sink.warn(JSON.stringify({ level: 'warn', event, ...payload }));
    },
    error(event, payload = {}) {
      sink.error(JSON.stringify({ level: 'error', event, ...payload }));
    },
  };
}
