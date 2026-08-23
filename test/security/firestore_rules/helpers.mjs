/**
 * Shared helpers for Firestore Security Rules emulator tests.
 *
 * Loads the repository-root firestore.rules file.
 * Uses local emulator project ID only — never prashna-67689.
 */
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { initializeTestEnvironment } from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));

/** Local-only emulator project — must never be the production project. */
export const PROJECT_ID = 'prashna-rules-emulator';

export const STUDENT_A = 'security-student-a';
export const STUDENT_B = 'security-student-b';
export const ADMIN_UID = 'security-admin';

export const FREE_COURSE_ID = 'free-course';
export const PAID_COURSE_ID = 'group-ii';

const REPO_ROOT = resolve(__dirname, '../../..');
export const RULES_PATH = resolve(REPO_ROOT, 'firestore.rules');

export const FIRESTORE_HOST = '127.0.0.1';
export const FIRESTORE_PORT = 8080;

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
export let testEnv;

export async function setupRulesTestEnvironment() {
  const rules = readFileSync(RULES_PATH, 'utf8');
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules,
      host: FIRESTORE_HOST,
      port: FIRESTORE_PORT,
    },
  });
  return testEnv;
}

export async function teardownRulesTestEnvironment() {
  if (testEnv) {
    await testEnv.cleanup();
    testEnv = undefined;
  }
}

export async function clearFirestore() {
  await testEnv.clearFirestore();
}

export function studentA() {
  return testEnv.authenticatedContext(STUDENT_A);
}

export function studentB() {
  return testEnv.authenticatedContext(STUDENT_B);
}

/** Admin custom claim matches firestore.rules isAdmin(): token.admin == true */
export function adminContext() {
  return testEnv.authenticatedContext(ADMIN_UID, { admin: true });
}

export function unauthenticated() {
  return testEnv.unauthenticatedContext();
}

/** Seed documents with security rules disabled (privileged emulator setup). */
export async function seed(writer) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await writer(context.firestore());
  });
}

export function enrollmentPath(uid, courseId) {
  return `user_courses/${uid}/courses/${courseId}`;
}

export function futureTimestamp(days = 30) {
  const ms = Date.now() + days * 24 * 60 * 60 * 1000;
  return Timestamp.fromMillis(ms);
}

export function pastTimestamp(days = 30) {
  const ms = Date.now() - days * 24 * 60 * 60 * 1000;
  return Timestamp.fromMillis(ms);
}

export async function seedCourse(db, courseId, { isFree, isPublished = true } = {}) {
  await setDoc(doc(db, 'courses', courseId), {
    courseId,
    title: courseId,
    shortTitle: courseId,
    description: '',
    isFree,
    isPublished,
    price: isFree ? 0 : 299,
    sortOrder: 0,
  });
}

export async function seedEnrollment(
  db,
  uid,
  courseId,
  {
    status = 'active',
    source = 'purchase',
    expiresAt = null,
  } = {},
) {
  await setDoc(doc(db, enrollmentPath(uid, courseId)), {
    uid,
    courseId,
    status,
    source,
    expiresAt,
    enrolledAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
}

export async function seedPaymentTransaction(
  db,
  transactionId,
  {
    uid,
    courseId = PAID_COURSE_ID,
    status = 'success',
  },
) {
  await setDoc(doc(db, 'payment_transactions', transactionId), {
    transactionId,
    uid,
    courseId,
    planId: 'plan-90',
    amount: 299,
    currency: 'INR',
    paymentProvider: 'debug',
    providerTransactionId: transactionId,
    status,
    purchasedAt: Timestamp.now(),
    expiresAt: futureTimestamp(90),
    metadata: {},
  });
}

export async function seedQuestion(db, questionId, courseId, { isActive = true } = {}) {
  await setDoc(doc(db, 'questions', questionId), {
    questionId,
    courseId,
    isActive,
    stem: 'Sample question',
    questionType: 'mcq',
  });
}

export async function seedTest(db, testId, courseId, { isPublished = true } = {}) {
  await setDoc(doc(db, 'tests', testId), {
    testId,
    courseId,
    isPublished,
    title: 'Sample test',
  });
}

export {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  setDoc,
  updateDoc,
};
