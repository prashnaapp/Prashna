import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../data/models/question_activity_models.dart';

/// Thin callable client for verified non-catalog question activity (asia-south1).
class QuestionActivityApi {
  QuestionActivityApi({
    this.functions,
    this.callOverride,
  });

  FirebaseFunctions? functions;

  /// Test hook — when set, no Firebase initialization occurs.
  final Future<Map<String, dynamic>> Function(
    String name,
    Map<String, dynamic> data,
  )? callOverride;

  Future<Map<String, dynamic>> reportQuestionActivity({
    required String activityEventId,
    required String questionId,
    required String selectedOption,
    required QuestionActivityContext context,
  }) {
    return _call('reportQuestionActivity', <String, dynamic>{
      'activityEventId': activityEventId,
      'questionId': questionId,
      'selectedOption': selectedOption,
      'sourceModule': context.sourceModule.name,
      'sourceType': context.sourceType.name,
      if (context.encounterId != null) 'encounterId': context.encounterId,
      'context': <String, dynamic>{
        if (context.courseId != null) 'courseId': context.courseId,
        if (context.testId != null) 'testId': context.testId,
        if (context.testTitle != null) 'testTitle': context.testTitle,
        if (context.paperId != null) 'paperId': context.paperId,
        if (context.sectionId != null) 'sectionId': context.sectionId,
        if (context.partId != null) 'partId': context.partId,
        if (context.topicId != null) 'topicId': context.topicId,
        if (context.lessonId != null) 'lessonId': context.lessonId,
        if (context.majorStudyAreaId != null)
          'majorStudyAreaId': context.majorStudyAreaId,
        if (context.contentTopicId != null)
          'contentTopicId': context.contentTopicId,
        if (context.syllabusUnitId != null)
          'syllabusUnitId': context.syllabusUnitId,
        if (context.seriesId != null) 'seriesId': context.seriesId,
        if (context.year != null) 'year': context.year,
        if (context.currentAffairsSetId != null)
          'currentAffairsSetId': context.currentAffairsSetId,
      },
    });
  }

  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    final override = callOverride;
    if (override != null) {
      return override(name, data);
    }
    try {
      final resolved = functions ??=
          FirebaseFunctions.instanceFor(region: 'asia-south1');
      final callable = resolved.httpsCallable(name);
      final result = await callable.call(data);
      final payload = result.data;
      if (payload is Map) {
        return Map<String, dynamic>.from(payload);
      }
      throw StateError('Invalid $name response');
    } on FirebaseFunctionsException catch (error) {
      debugPrint(
        'QuestionActivityApi.$name failed: ${error.code} ${error.message}',
      );
      rethrow;
    }
  }
}
