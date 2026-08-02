import 'package:flutter/material.dart';

import 'screens/bookmark_question_viewer_screen.dart';
import 'screens/bookmarks_screen.dart';

Future<void> openBookmarks(BuildContext context) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const BookmarksScreen()),
  );
}

Future<void> openBookmarkedQuestion(BuildContext context, String questionId) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => BookmarkQuestionViewerScreen(questionId: questionId),
    ),
  );
}
