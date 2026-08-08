#!/usr/bin/env node
/**
 * Provision or revoke the Firebase Auth custom claim: { admin: true }.
 *
 * SECURITY
 * --------
 * - Admin privilege must NEVER be granted from Firestore users/{uid}.role.
 * - This script is the trusted path: Firebase Admin SDK + service account.
 * - Do NOT commit service-account JSON. Do NOT expose this as an HTTP endpoint.
 * - Target must be an Auth UID (never an email address).
 *
 * CREDENTIALS
 * -----------
 * Uses the normal Google Application Default Credentials chain, e.g.:
 *
 *   export GOOGLE_APPLICATION_CREDENTIALS="/absolute/path/to/service-account.json"
 *
 * Or run where ADC is already configured (gcloud auth application-default login
 * with a principal that can manage Firebase Auth — prefer a locked-down
 * service account for production).
 *
 * USAGE
 * -----
 *   cd scripts
 *   npm install
 *   export GOOGLE_APPLICATION_CREDENTIALS="..."
 *   node set_admin_claim.mjs <FIREBASE_AUTH_UID>
 *   node set_admin_claim.mjs <FIREBASE_AUTH_UID> --revoke
 *
 * After granting/revoking, the user must refresh their ID token
 * (AdminAuthService.refreshIdToken / getIdToken(true)) before rules see the change.
 */

import { initializeApp, applicationDefault, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const PROJECT_ID = process.env.GCLOUD_PROJECT
  || process.env.GOOGLE_CLOUD_PROJECT
  || process.env.FIREBASE_PROJECT_ID
  || 'prashna-67689';

function printUsageAndExit(code = 1) {
  console.error(`
Usage:
  node set_admin_claim.mjs <FIREBASE_AUTH_UID>
  node set_admin_claim.mjs <FIREBASE_AUTH_UID> --revoke

Examples:
  node set_admin_claim.mjs abc123XYZ789
  node set_admin_claim.mjs abc123XYZ789 --revoke

Environment:
  GOOGLE_APPLICATION_CREDENTIALS  Path to a service-account JSON (recommended)
  FIREBASE_PROJECT_ID             Optional override (default: ${PROJECT_ID})
`);
  process.exit(code);
}

function looksLikeEmail(value) {
  return value.includes('@');
}

/** Firebase Auth UIDs are typically 28 chars; accept a conservative range. */
function looksLikeUid(value) {
  return /^[A-Za-z0-9_-]{20,128}$/.test(value);
}

function parseArgs(argv) {
  const args = argv.slice(2).filter((a) => a.trim().length > 0);
  if (args.length === 0 || args.includes('-h') || args.includes('--help')) {
    printUsageAndExit(args.includes('-h') || args.includes('--help') ? 0 : 1);
  }

  const revoke = args.includes('--revoke');
  const positional = args.filter((a) => !a.startsWith('--'));
  if (positional.length !== 1) {
    console.error('Error: provide exactly one Firebase Auth UID.');
    printUsageAndExit(1);
  }

  const uid = positional[0];
  if (looksLikeEmail(uid)) {
    console.error(
      'Error: email addresses are not accepted. Pass the Firebase Auth UID only.',
    );
    process.exit(1);
  }
  if (!looksLikeUid(uid)) {
    console.error(
      'Error: value does not look like a Firebase Auth UID. Refusing to continue.',
    );
    process.exit(1);
  }

  return { uid, revoke };
}

async function main() {
  const { uid, revoke } = parseArgs(process.argv);

  if (getApps().length === 0) {
    initializeApp({
      credential: applicationDefault(),
      projectId: PROJECT_ID,
    });
  }

  const auth = getAuth();

  let user;
  try {
    user = await auth.getUser(uid);
  } catch (error) {
    console.error(`Error: could not load Auth user for UID "${uid}".`);
    console.error(error?.message || error);
    process.exit(1);
  }

  const existing = { ...(user.customClaims || {}) };

  if (revoke) {
    delete existing.admin;
    await auth.setCustomUserClaims(uid, existing);
    console.log('OK: admin claim revoked.');
  } else {
    existing.admin = true;
    await auth.setCustomUserClaims(uid, existing);
    console.log('OK: admin claim set (admin: true).');
  }

  console.log(`  project : ${PROJECT_ID}`);
  console.log(`  uid     : ${uid}`);
  console.log(`  email   : ${user.email || '(none)'}`);
  console.log(
    '  note    : user must force-refresh their ID token before clients/rules see this.',
  );
}

main().catch((error) => {
  console.error('Fatal error while updating custom claims:');
  console.error(error?.message || error);
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      '\nHint: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON path.',
    );
  }
  process.exit(1);
});
