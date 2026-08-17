import 'package:flutter/material.dart';

import 'syllabus_browser_screen.dart';

/// Compatibility entry for existing callers.
///
/// Paper / part / unit browsing now happens on [SyllabusBrowserScreen].
class SyllabusPapersScreen extends StatelessWidget {
  const SyllabusPapersScreen({
    super.key,
    required this.courseId,
    this.initialPaperId,
    this.initialPartId,
  });

  final String courseId;
  final String? initialPaperId;
  final String? initialPartId;

  @override
  Widget build(BuildContext context) {
    return SyllabusBrowserScreen(
      courseId: courseId,
      initialPaperId: initialPaperId,
      initialPartId: initialPartId,
    );
  }
}
