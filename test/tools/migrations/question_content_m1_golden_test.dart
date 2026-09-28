import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';
import 'package:telangana_prep/features/question_bank/data/question_content_fingerprint.dart';
import 'package:telangana_prep/features/question_bank/data/question_search_text.dart';

void main() {
  final fixture =
      jsonDecode(
            File(
              'scripts/migrations/fixtures/question_content_m1_golden.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  for (final rawCase in fixture['cases'] as List<dynamic>) {
    final goldenCase = rawCase as Map<String, dynamic>;
    test('M1 golden parity: ${goldenCase['name']}', () {
      final rawQuestion = goldenCase['question'] as Map<String, dynamic>;
      final question = _questionFromMap(rawQuestion);
      final content = rawQuestion['content'] as Map<String, dynamic>;
      final englishQuestion =
          ((content['en'] as Map<String, dynamic>)['question'] as String);

      expect(
        QuestionContentFingerprint.fromQuestion(question),
        goldenCase['expectedFingerprint'],
      );
      expect(
        QuestionSearchText.normalize(englishQuestion),
        goldenCase['expectedSearchText'],
      );
    });
  }
}

Question _questionFromMap(Map<String, dynamic> raw) {
  final content = raw['content'] as Map<String, dynamic>;
  final en = content['en'] as Map<String, dynamic>;
  final te = content['te'] as Map<String, dynamic>?;

  QuestionLocalizedContent localized(Map<String, dynamic> value) {
    return QuestionLocalizedContent(
      question: value['question'] as String,
      options: [
        for (final option in value['options'] as List<dynamic>)
          QuestionOption(
            text: (option as Map<String, dynamic>)['text'] as String,
          ),
      ],
      explanation: '',
      statements: [
        for (final statement in value['statements'] as List<dynamic>)
          statement as String,
      ],
    );
  }

  return Question(
    id: 'm1-golden',
    courseId: raw['courseId'] as String,
    paperId: raw['paperId'] as String,
    question: raw['question'] as String? ?? '',
    options: [
      for (final option in (raw['options'] as List<dynamic>? ?? const []))
        option as String,
    ],
    correctOption: raw['correctOption'] as String,
    explanation: '',
    difficulty: QuestionDifficulty.medium,
    questionType: QuestionType.practice,
    marks: 1,
    negativeMarks: 0,
    tags: const [],
    estimatedTime: const Duration(seconds: 60),
    createdAt: DateTime(2026, 9, 28),
    updatedAt: DateTime(2026, 9, 28),
    content: QuestionContent(
      en: localized(en),
      te: te == null ? null : localized(te),
    ),
    itemFormat: raw['itemFormat'] == 'statement_mcq'
        ? QuestionItemFormat.statementMcq
        : null,
  );
}
