# Admin Question Management (Phase 5.6)

The existing Admin Question Bank now has two compatible paths:

- legacy questions remain readable and editable without automatic conversion;
- new records use one bilingual `Question` document with canonical syllabus
  attribution and an explicit `draft`, `published`, or `archived` status.

New records default to `draft`. Only an explicit human status change publishes
content. The student repository continues to use its normal `isActive == true`
path, so drafts and archived records are excluded.

## Canonical editor mapping

- Paper I: Paper → Major Study Area → Content Topic.
- Papers II–IV: Paper → Part → Topic → optional Lesson.

The editor never exposes legacy `sectionId` as the canonical Part.

## Bulk import (Phase 5.7)

Use Admin → Import Questions.

Workflow:

1. Paste a JSON file with a top-level `questions` array.
2. Validate the entire batch (no Firestore writes).
3. If any record is invalid, import nothing.
4. Confirm import only after a fully valid batch.
5. All imported questions are created as `draft` / inactive.

Import format supports only bilingual content + canonical syllabus
attribution. Difficulty, source, AI metadata, and automatic publishing are
out of scope.

Writes go through `QuestionCloudRepository.createQuestionsBatch` (Firestore
`WriteBatch`, max 500). Optional IDs are preserved when supplied; otherwise
Firestore generates IDs. Existing ID collisions and within-file ID duplicates
block import. Content duplicates are reported as warnings.
