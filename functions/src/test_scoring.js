/**
 * Server scoring v1 — mirrors Flutter TestService.calculateScore().
 *
 * marksPerQuestion = totalMarks / totalQuestions
 * score = correct * marksPerQuestion - wrong * negativeMarks
 * score clamped at 0
 * accuracy = correct / attempted * 100
 * percentage = score / totalMarks * 100
 * passed = percentage >= 40
 *
 * Do not change semantics without bumping scoringVersion.
 */
export const SCORING_VERSION_V1 = 'v1';
export const PASS_PERCENTAGE_V1 = 40;

/**
 * @param {object} input
 * @param {number} input.totalQuestions
 * @param {number} input.totalMarks
 * @param {number} input.negativeMarks
 * @param {Array<{ questionId: string, selectedOption: string|null|undefined }>} input.answers
 * @param {Record<string, string>} input.correctByQuestionId questionId → correctOption
 */
export function calculateScoreV1(input) {
  const totalQuestions = Number(input.totalQuestions) || 0;
  const totalMarks = Number(input.totalMarks) || 0;
  const negativeMarks = Number(input.negativeMarks) || 0;
  const correctByQuestionId = input.correctByQuestionId || {};
  const answers = Array.isArray(input.answers) ? input.answers : [];

  let correct = 0;
  let wrong = 0;
  let attempted = 0;

  for (const answer of answers) {
    const questionId = String(answer?.questionId || '').trim();
    if (!questionId) continue;
    const selected =
      answer?.selectedOption == null
        ? null
        : String(answer.selectedOption).trim();
    if (!selected) continue;
    if (!(questionId in correctByQuestionId)) continue;

    attempted += 1;
    if (selected === String(correctByQuestionId[questionId])) {
      correct += 1;
    } else {
      wrong += 1;
    }
  }

  const skipped = totalQuestions - attempted;
  const marksPerQuestion =
    totalQuestions === 0 ? 0 : totalMarks / totalQuestions;
  const rawScore = correct * marksPerQuestion - wrong * negativeMarks;
  const score = rawScore < 0 ? 0 : rawScore;
  const accuracy = attempted === 0 ? 0 : (correct / attempted) * 100;
  const percentage = totalMarks === 0 ? 0 : (score / totalMarks) * 100;
  const passed = percentage >= PASS_PERCENTAGE_V1;

  return {
    totalQuestions,
    attempted,
    correct,
    wrong,
    skipped,
    score: Number(score.toFixed(2)),
    accuracy: Number(accuracy.toFixed(1)),
    percentage: Number(percentage.toFixed(1)),
    passed,
    scoringVersion: SCORING_VERSION_V1,
  };
}
