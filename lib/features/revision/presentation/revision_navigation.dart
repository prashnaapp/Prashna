import 'package:flutter/material.dart';

import '../presentation/screens/revision_center_screen.dart';

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
}
