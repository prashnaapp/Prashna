/**
 * Admin-only HTTPS callables for entitlement / verified-payment processing.
 *
 * Auth: request.auth.token.admin === true (Firebase Auth custom claim).
 * Never trusts a client-supplied isAdmin field.
 */
import { HttpsError, onCall } from 'firebase-functions/v2/https';

import { createAdminContentService } from './admin_content_service.js';
import { createEntitlementService } from './entitlement_service.js';
import { getDb } from './firebase.js';
import { createPaymentProcessingService } from './payment_processing_service.js';
import { createPlayPurchaseService } from './play_purchase_service.js';
import { createQuestionActivityService } from './question_activity_service.js';
import { createSyllabusCompletionService } from './syllabus_completion_service.js';
import { createTestAttemptService } from './test_attempt_service.js';
import { createTransactionService } from './transaction_service.js';

function mapServiceError(error) {
  const code = error?.code || 'internal';
  const message = error?.message || 'Internal error';
  const allowed = new Set([
    'unauthenticated',
    'permission-denied',
    'invalid-argument',
    'failed-precondition',
    'not-found',
    'already-exists',
    'resource-exhausted',
    'aborted',
    'internal',
  ]);
  throw new HttpsError(allowed.has(code) ? code : 'internal', message);
}

export function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  if (request.auth.token?.admin !== true) {
    throw new HttpsError(
      'permission-denied',
      'Admin claim required. Client isAdmin fields are ignored.',
    );
  }
}

export function assertAuthenticated(request) {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }
  return request.auth.uid;
}

function services() {
  const db = getDb();
  return {
    entitlements: createEntitlementService(db),
    transactions: createTransactionService(db),
    payments: createPaymentProcessingService(db),
    playPurchases: createPlayPurchaseService({ db }),
    testAttempts: createTestAttemptService({ db }),
    questionActivity: createQuestionActivityService({ db }),
    syllabusCompletion: createSyllabusCompletionService(db),
    content: createAdminContentService(db),
  };
}

async function withAdminContent(request, run) {
  assertAdmin(request);
  try {
    return await run(services().content, request.data || {});
  } catch (error) {
    mapServiceError(error);
  }
}

export const adminGrantEntitlement = onCall(
  { region: 'asia-south1' },
  async (request) => {
  assertAdmin(request);
  const { uid, courseId, source = 'admin', expiresAt = null } = request.data || {};
  const { entitlements } = services();
  const result = await entitlements.grant({
    uid,
    courseId,
    source,
    expiresAt: expiresAt ? new Date(expiresAt) : null,
  });
  return { entitlement: result };
  },
);

export const adminRevokeEntitlement = onCall(
  { region: 'asia-south1' },
  async (request) => {
  assertAdmin(request);
  const { uid, courseId } = request.data || {};
  const { entitlements } = services();
  const result = await entitlements.revoke(uid, courseId);
  return { entitlement: result };
  },
);

export const adminExtendEntitlement = onCall(async (request) => {
  assertAdmin(request);
  const { uid, courseId, expiresAt } = request.data || {};
  if (!expiresAt) {
    throw new HttpsError('invalid-argument', 'expiresAt is required');
  }
  const { entitlements } = services();
  const result = await entitlements.extend(uid, courseId, new Date(expiresAt));
  return { entitlement: result };
});

export const adminGetEntitlement = onCall(async (request) => {
  assertAdmin(request);
  const { uid, courseId } = request.data || {};
  const { entitlements } = services();
  const result = await entitlements.get(uid, courseId);
  return { entitlement: result };
});

/**
 * Closed: this callable previously accepted admin-supplied payment facts
 * (success, amount, expiry, courseId, providerTransactionId) and wrote
 * payment_transactions + entitlements with no Google Play verification.
 *
 * Trusted payment grants must go through verifyPlayPurchase / RTDN after
 * the Android Publisher API confirms PURCHASED. processVerifiedPayment()
 * remains an internal service for those verified callers only.
 */
export function rejectUnverifiedAdminPayment(request) {
  assertAdmin(request);
  throw new HttpsError(
    'failed-precondition',
    'Unverified admin payment processing is disabled. '
      + 'Successful payment records, entitlements, amounts, and expiry '
      + 'must be derived from Google Play verification '
      + '(verifyPlayPurchase or RTDN), not from client- or admin-supplied fields.',
  );
}

export const adminProcessVerifiedPayment = onCall(async (request) => {
  rejectUnverifiedAdminPayment(request);
});

export const adminGetTransaction = onCall(async (request) => {
  assertAdmin(request);
  const { transactionId } = request.data || {};
  const { transactions } = services();
  const result = await transactions.get(transactionId);
  return { transaction: result };
});

/**
 * Authenticated student callable: verify a Google Play purchase token and
 * grant entitlement. UID always comes from request.auth — never from client body.
 *
 * Client may send: purchaseToken, productId, packageName.
 * Client must NOT send courseId / expiresAt / uid for trust decisions.
 */
export const verifyPlayPurchase = onCall(async (request) => {
  const uid = assertAuthenticated(request);
  const data = request.data || {};

  // Reject spoofed uid / courseId attempts explicitly.
  if (data.uid && String(data.uid) !== uid) {
    throw new HttpsError(
      'permission-denied',
      'uid must match the authenticated user.',
    );
  }

  const { playPurchases } = services();
  return playPurchases.verifyAndGrant({
    uid,
    productId: data.productId,
    purchaseToken: data.purchaseToken,
    packageName: data.packageName,
  });
});

/**
 * Authenticated student callable: start a server-authored test attempt.
 * UID always from request.auth. Client may only send testId + startRequestId.
 */
export const startTestAttempt = onCall(
  { region: 'asia-south1' },
  async (request) => {
  const uid = assertAuthenticated(request);
  const data = request.data || {};
  if (data.uid && String(data.uid) !== uid) {
    throw new HttpsError(
      'permission-denied',
      'uid must match the authenticated user.',
    );
  }
  if (data.courseId || data.questionIds || data.score) {
    throw new HttpsError(
      'invalid-argument',
      'Client must not supply courseId, questionIds, or score.',
    );
  }
  try {
    const { testAttempts } = services();
    return await testAttempts.startAttempt({
      uid,
      testId: data.testId,
      startRequestId: data.startRequestId,
    });
  } catch (error) {
    mapServiceError(error);
  }
  },
);

/**
 * Authenticated student callable: submit answers for server scoring.
 * Accepts only attemptId + selectedAnswers[{questionId, selectedOption}].
 */
export const submitTestAttempt = onCall(
  { region: 'asia-south1' },
  async (request) => {
  const uid = assertAuthenticated(request);
  const data = request.data || {};
  if (data.uid && String(data.uid) !== uid) {
    throw new HttpsError(
      'permission-denied',
      'uid must match the authenticated user.',
    );
  }
  if (
    data.score != null
    || data.correctOption != null
    || data.courseId != null
    || data.questionIds != null
    || data.passed != null
    || data.percentage != null
    || data.durationSeconds != null
    || data.durationMinutes != null
    || data.startedAt != null
  ) {
    throw new HttpsError(
      'invalid-argument',
      'Client must not supply authoritative scoring fields.',
    );
  }
  try {
    const { testAttempts } = services();
    return await testAttempts.submitAttempt({
      uid,
      attemptId: data.attemptId,
      selectedAnswers: data.selectedAnswers,
    });
  } catch (error) {
    mapServiceError(error);
  }
  },
);

/**
 * Authenticated student callable: verified non-catalog question activity.
 *
 * Client may send activityEventId + questionId + selectedOption + source
 * context. Server loads the question and decides wrongness. Does not accept
 * isWrong / correctOption / mistakeCounts from the client.
 *
 * Catalog tests must continue to use submitTestAttempt — not this callable.
 */
export const reportQuestionActivity = onCall(
  { region: 'asia-south1' },
  async (request) => {
    const uid = assertAuthenticated(request);
    const data = request.data || {};
    if (data.uid && String(data.uid) !== uid) {
      throw new HttpsError(
        'permission-denied',
        'uid must match the authenticated user.',
      );
    }
    if (
      data.isWrong != null
      || data.correctOption != null
      || data.mistakeCounts != null
      || data.wrongQuestions != null
      || data.score != null
    ) {
      throw new HttpsError(
        'invalid-argument',
        'Client must not supply revision authority fields.',
      );
    }
    try {
      const { questionActivity } = services();
      return await questionActivity.reportQuestionActivity({
        uid,
        activityEventId: data.activityEventId,
        questionId: data.questionId,
        selectedOption: data.selectedOption,
        sourceModule: data.sourceModule,
        sourceType: data.sourceType,
        encounterId: data.encounterId,
        context: data.context,
      });
    } catch (error) {
      mapServiceError(error);
    }
  },
);

/**
 * Authenticated student callable: set syllabus-unit completion status.
 * UID always from request.auth. Client may send hierarchy fields + status.
 * Client must NOT supply a trusted uid; spoofed uid is rejected.
 */
export const setSyllabusCompletion = onCall(
  { region: 'asia-south1' },
  async (request) => {
    const uid = assertAuthenticated(request);
    const data = request.data || {};
    if (data.uid && String(data.uid) !== uid) {
      throw new HttpsError(
        'permission-denied',
        'uid must match the authenticated user.',
      );
    }
    try {
      const { syllabusCompletion } = services();
      return await syllabusCompletion.setCompletionStatus({
        uid,
        courseId: data.courseId,
        paperId: data.paperId,
        partId: data.partId,
        syllabusUnitId: data.syllabusUnitId,
        status: data.status,
        scopeKey: data.scopeKey,
      });
    } catch (error) {
      mapServiceError(error);
    }
  },
);

export const adminCreateQuestion = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.createQuestion(data)),
);

export const adminUpdateQuestion = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.updateQuestion(data)),
);

export const adminCreateQuestionsBatch = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.createQuestionsBatch(data)),
);

export const adminSetQuestionStatus = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.setQuestionStatus(data)),
);

export const adminSetQuestionActive = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.setQuestionActive(data)),
);

export const adminCreateTest = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.createTest(data)),
);

export const adminUpdateTest = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.updateTest(data)),
);

export const adminPublishTest = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.publishTest(data)),
);

export const adminSetTestStatus = onCall(
  { region: 'asia-south1' },
  (request) => withAdminContent(request, (content, data) => content.setTestStatus(data)),
);
