/**
 * Firebase Admin initialization for Cloud Functions.
 *
 * Uses the default Functions/Admin credential chain.
 * When FIRESTORE_EMULATOR_HOST is set, Admin SDK targets the emulator.
 *
 * Never initialize against production from unit tests.
 */
import { getApps, initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

export function ensureAdminApp() {
  if (getApps().length === 0) {
    initializeApp();
  }
}

export function getDb() {
  ensureAdminApp();
  return getFirestore();
}
