import 'package:flutter/material.dart';

import '../../../core/design_system/design_system.dart';
import '../../features/practice/data/practice_dummy_data.dart';
import '../../features/practice/presentation/screens/practice_session_screen.dart';

String practiceSessionHeroTag({
  required String paperTitle,
  required String partTitle,
  required int chapterNumber,
}) {
  return 'practice-$paperTitle-$partTitle-$chapterNumber';
}

void openPracticeSession(
  BuildContext context, {
  required String paperTitle,
  required String partTitle,
  required int chapterNumber,
}) {
  final session = PracticeDummyData.sessionForChapter(chapterNumber);
  final heroTag = practiceSessionHeroTag(
    paperTitle: paperTitle,
    partTitle: partTitle,
    chapterNumber: chapterNumber,
  );

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('$paperTitle · $partTitle'),
        ),
        body: PracticeSessionScreen(
          session: session,
          heroTag: heroTag,
        ),
      ),
    ),
  );
}
