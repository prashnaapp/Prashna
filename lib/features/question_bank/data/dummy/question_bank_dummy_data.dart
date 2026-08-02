import '../models/question_models.dart';

/// Local question corpus. Replace with Firebase-backed source later.
abstract final class QuestionBankDummyData {
  static final DateTime _seed = DateTime(2026, 1, 1);

  static final List<Question> all = List.unmodifiable(_buildAll());

  static List<Question> _buildAll() {
    final questions = <Question>[
      Question(
        id: 'qb-1',
        courseId: 'group-ii',
        paperId: 'paper-1',
        sectionId: 'section-1',
        topicId: 'topic-1',
        question:
            'Which Article of the Constitution guarantees Equality before Law?',
        options: const [
          'Article 12',
          'Article 14',
          'Article 19',
          'Article 21',
        ],
        correctOption: 'B',
        explanation:
            'Article 14 guarantees Equality before Law and Equal Protection of Laws.',
        difficulty: QuestionDifficulty.easy,
        questionType: QuestionType.practice,
        language: 'en',
        marks: 1,
        negativeMarks: 0.25,
        year: 2023,
        examName: 'TSPSC Group-II',
        tags: const ['constitution', 'fundamental-rights', 'article-14'],
        estimatedTime: const Duration(seconds: 45),
        hint: 'Look under Right to Equality.',
        aiExplanation:
            'Article 14 is the cornerstone of equality jurisprudence in India.',
        createdAt: _seed,
        updatedAt: _seed,
      ),
      Question(
        id: 'qb-2',
        courseId: 'group-ii',
        paperId: 'paper-1',
        sectionId: 'section-1',
        topicId: 'topic-1',
        question:
            'The Directive Principles of State Policy are contained in which part of the Constitution?',
        options: const ['Part III', 'Part IV', 'Part IVA', 'Part V'],
        correctOption: 'B',
        explanation: 'Directive Principles are in Part IV (Articles 36–51).',
        difficulty: QuestionDifficulty.medium,
        questionType: QuestionType.practice,
        language: 'en',
        marks: 1,
        negativeMarks: 0.25,
        year: 2022,
        examName: 'TSPSC Group-II',
        tags: const ['constitution', 'dpsp'],
        estimatedTime: const Duration(seconds: 50),
        createdAt: _seed.add(const Duration(days: 1)),
        updatedAt: _seed.add(const Duration(days: 1)),
      ),
      Question(
        id: 'qb-3',
        courseId: 'group-ii',
        paperId: 'paper-1',
        sectionId: 'section-2',
        topicId: 'topic-2',
        question: 'Who was the first Chief Minister of Telangana?',
        options: const [
          'K. Chandrashekar Rao',
          'N. T. Rama Rao',
          'Y. S. Rajasekhara Reddy',
          'N. Chandrababu Naidu',
        ],
        correctOption: 'A',
        explanation:
            'K. Chandrashekar Rao became the first Chief Minister after state formation in 2014.',
        difficulty: QuestionDifficulty.easy,
        questionType: QuestionType.previousYear,
        language: 'en',
        marks: 1,
        negativeMarks: 0.25,
        year: 2018,
        examName: 'TSPSC Group-II',
        tags: const ['telangana', 'polity', 'history'],
        estimatedTime: const Duration(seconds: 40),
        createdAt: _seed.add(const Duration(days: 2)),
        updatedAt: _seed.add(const Duration(days: 2)),
      ),
      Question(
        id: 'qb-4',
        courseId: 'group-iii',
        paperId: 'paper-1',
        sectionId: 'section-1',
        topicId: 'topic-1',
        question:
            'Hyderabad was founded by which dynasty ruler historically associated with the city?',
        options: const [
          'Quli Qutb Shah',
          'Aurangzeb',
          'Krishnadevaraya',
          'Alauddin Khilji',
        ],
        correctOption: 'A',
        explanation:
            'Muhammad Quli Qutb Shah is credited with founding Hyderabad.',
        difficulty: QuestionDifficulty.medium,
        questionType: QuestionType.practice,
        language: 'en',
        marks: 1,
        negativeMarks: 0.25,
        year: 2021,
        examName: 'TSPSC Group-III',
        tags: const ['telangana', 'history', 'hyderabad'],
        estimatedTime: const Duration(seconds: 55),
        createdAt: _seed.add(const Duration(days: 3)),
        updatedAt: _seed.add(const Duration(days: 3)),
      ),
      Question(
        id: 'qb-5',
        courseId: 'group-ii',
        paperId: 'paper-2',
        sectionId: 'section-1',
        topicId: 'topic-3',
        question:
            'Which of the following is a Union List subject under the Seventh Schedule?',
        options: const [
          'Police',
          'Public Health',
          'Defence',
          'Agriculture',
        ],
        correctOption: 'C',
        explanation: 'Defence is a Union List subject.',
        difficulty: QuestionDifficulty.hard,
        questionType: QuestionType.mock,
        language: 'en',
        marks: 2,
        negativeMarks: 0.5,
        year: 2024,
        examName: 'TSPSC Group-II Mock',
        tags: const ['constitution', 'federalism', 'union-list'],
        estimatedTime: const Duration(seconds: 60),
        createdAt: _seed.add(const Duration(days: 4)),
        updatedAt: _seed.add(const Duration(days: 4)),
      ),
    ];

    // Expand corpus for practice / mock volume (Firebase-ready shape).
    for (var i = 6; i <= 40; i++) {
      final bucket = i % 4;
      final difficulty = QuestionDifficulty.values[i % 3];
      final type = i % 5 == 0
          ? QuestionType.previousYear
          : i % 7 == 0
              ? QuestionType.mock
              : QuestionType.practice;

      questions.add(
        Question(
          id: 'qb-$i',
          courseId: bucket.isEven ? 'group-ii' : 'group-iii',
          paperId: 'paper-${(bucket % 2) + 1}',
          sectionId: 'section-${(bucket % 3) + 1}',
          topicId: 'topic-${(bucket % 4) + 1}',
          question:
              'Telangana exam practice question $i: Which provision relates to fundamental governance principles?',
          options: [
            'Directive Principle $i',
            'Fundamental Duty $i',
            'Fundamental Right $i',
            'Constitutional Amendment $i',
          ],
          correctOption: 'C',
          explanation:
              'Dummy explanation for question $i. Detailed reasoning will be added from the content bank.',
          difficulty: difficulty,
          questionType: type,
          language: i % 11 == 0 ? 'te' : 'en',
          marks: difficulty == QuestionDifficulty.hard ? 2 : 1,
          negativeMarks: difficulty == QuestionDifficulty.hard ? 0.5 : 0.25,
          year: 2018 + (i % 7),
          examName: bucket.isEven ? 'TSPSC Group-II' : 'TSPSC Group-III',
          tags: [
            'governance',
            if (i % 2 == 0) 'constitution',
            if (i % 3 == 0) 'polity',
            'q$i',
          ],
          estimatedTime: Duration(seconds: 40 + (i % 20)),
          hint: i % 4 == 0 ? 'Recall Part III / IV distinctions.' : null,
          createdAt: _seed.add(Duration(days: i)),
          updatedAt: _seed.add(Duration(days: i)),
        ),
      );
    }

    return questions;
  }
}
