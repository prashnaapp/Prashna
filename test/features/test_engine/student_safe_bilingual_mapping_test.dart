import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/test_engine/data/models/test_engine_models.dart';
import 'package:telangana_prep/features/test_engine/services/test_service.dart';

void main() {
  group('createTestFromStudentSafeQuestions bilingual mapping', () {
    test('maps Telugu question and options from snapshot content', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'snap-test',
        title: 'Home',
        courseId: 'group-ii',
        studentQuestions: [
          <String, dynamic>{
            'questionId': 'ndrf-q',
            'position': 0,
            'text':
                'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
            'options': [
              <String, dynamic>{
                'label': 'A',
                'text': 'Ministry of Urban Development',
                'teluguText': 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ',
              },
              <String, dynamic>{
                'label': 'B',
                'text': 'Ministry of Home Affairs',
                'teluguText': 'హోం వ్యవహారాల మంత్రిత్వ శాఖ',
              },
              <String, dynamic>{
                'label': 'C',
                'text': 'Ministry of Defence',
                'teluguText': 'రక్షణ మంత్రిత్వ శాఖ',
              },
              <String, dynamic>{
                'label': 'D',
                'text':
                    'Ministry of Environment, Forest and Climate Change',
                'teluguText':
                    'పర్యావరణ, అటవీ మరియు వాతావరణ మార్పుల మంత్రిత్వ శాఖ',
              },
            ],
            'content': <String, dynamic>{
              'en': <String, dynamic>{
                'question':
                    'National Disaster Response Force (NDRF) is a specialized disaster response force under which ministry?',
                'options': [
                  <String, dynamic>{'text': 'Ministry of Urban Development'},
                  <String, dynamic>{'text': 'Ministry of Home Affairs'},
                  <String, dynamic>{'text': 'Ministry of Defence'},
                  <String, dynamic>{
                    'text':
                        'Ministry of Environment, Forest and Climate Change',
                  },
                ],
              },
              'te': <String, dynamic>{
                'question':
                    'నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్ (NDRF) అనేది ఏ మంత్రిత్వ శాఖ పరిధిలోని ప్రత్యేక విపత్తు ప్రతిస్పందన దళం?',
                'options': [
                  <String, dynamic>{'text': 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ'},
                  <String, dynamic>{'text': 'హోం వ్యవహారాల మంత్రిత్వ శాఖ'},
                  <String, dynamic>{'text': 'రక్షణ మంత్రిత్వ శాఖ'},
                  <String, dynamic>{
                    'text':
                        'పర్యావరణ, అటవీ మరియు వాతావరణ మార్పుల మంత్రిత్వ శాఖ',
                  },
                ],
              },
            },
            'courseId': 'group-ii',
            'paperId': 'group-ii-paper-i',
            'syllabusUnitId': 'group-ii-paper-i-area-01',
            'majorStudyAreaId': 'group-ii-paper-i-area-01',
            'scopeKey':
                'v1|group-ii|group-ii-paper-i||group-ii-paper-i-area-01',
          },
        ],
      );

      final question = test.questions.single;
      expect(
        question.text,
        contains('National Disaster Response Force'),
      );
      expect(
        question.teluguText,
        'నేషనల్ డిజాస్టర్ రెస్పాన్స్ ఫోర్స్ (NDRF) అనేది ఏ మంత్రిత్వ శాఖ పరిధిలోని ప్రత్యేక విపత్తు ప్రతిస్పందన దళం?',
      );
      expect(question.options[0].text, 'Ministry of Urban Development');
      expect(question.options[0].teluguText, 'పట్టణాభివృద్ధి మంత్రిత్వ శాఖ');
      expect(question.options[1].teluguText, 'హోం వ్యవహారాల మంత్రిత్వ శాఖ');
      expect(question.correctOption, isEmpty);
      expect(question.explanation, isEmpty);
    });

    test('English-only snapshot still maps without Telugu', () async {
      final service = TestService();
      final test = await service.createTestFromStudentSafeQuestions(
        id: 'en-only-test',
        title: 'English',
        courseId: 'group-ii',
        studentQuestions: [
          <String, dynamic>{
            'questionId': 'en-q',
            'position': 0,
            'text': 'English only question?',
            'options': [
              <String, dynamic>{'label': 'A', 'text': 'One'},
              <String, dynamic>{'label': 'B', 'text': 'Two'},
              <String, dynamic>{'label': 'C', 'text': 'Three'},
              <String, dynamic>{'label': 'D', 'text': 'Four'},
            ],
            'courseId': 'group-ii',
            'paperId': 'group-ii-paper-i',
          },
        ],
      );

      final question = test.questions.single;
      expect(question.text, 'English only question?');
      expect(question.teluguText, isNull);
      expect(question.options.every((o) => o.teluguText == null), isTrue);
      expect(question.options.length, 4);
    });
  });
}
