import 'package:flutter/material.dart';

import '../../bookmarks/presentation/bookmark_navigation.dart';
import '../../bookmarks/presentation/screens/bookmark_question_viewer_screen.dart';
import '../data/models/revision_models.dart';
import 'screens/frequently_incorrect_screen.dart';
import 'screens/revision_center_screen.dart';
import 'screens/weak_topics_revision_screen.dart';
import 'screens/wrong_questions_screen.dart';

abstract final class RevisionNavigation {
  static Future<void> openRevisionCenter(
    BuildContext context, {
    String? courseId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RevisionCenterScreen(courseId: courseId),
      ),
    );
  }

  static Future<void> openHubDestination(
    BuildContext context, {
    required RevisionHubType type,
    String? courseId,
  }) {
    switch (type) {
      case RevisionHubType.wrongQuestions:
        return Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WrongQuestionsScreen(courseId: courseId),
          ),
        );
      case RevisionHubType.weakTopics:
        return Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => WeakTopicsRevisionScreen(courseId: courseId),
          ),
        );
      case RevisionHubType.bookmarked:
        return openBookmarks(context);
      case RevisionHubType.frequentlyIncorrect:
        return Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FrequentlyIncorrectScreen(courseId: courseId),
          ),
        );
    }
  }

  static Future<void> openQuestion(
    BuildContext context, {
    required String questionId,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookmarkQuestionViewerScreen(
          questionId: questionId,
          title: 'Question',
        ),
      ),
    );
  }
}
