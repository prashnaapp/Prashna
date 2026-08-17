import 'package:flutter/material.dart';

import '../../../study_planner/presentation/screens/canonical_tracker_screen.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../data/models/progress_models.dart';
import '../progress_visual.dart';
import '../screens/exam_progress_screen.dart';
import 'exam_tracker_card.dart';

/// Available courses on the Progress tab — the same MVP catalog as Chapters
/// and Test Series, which currently list Group-II and Group-III only.
class CourseProgressSection extends StatelessWidget {
  const CourseProgressSection({super.key, required this.available});

  final List<ExamProgressSummary> available;

  static const double _cardGap = 12;

  // Same accents as the Chapters / Test Series course cards.
  static const Color _darkPurple = Color(0xFF4A3AB0);
  static const Color _darkGreen = Color(0xFF167A63);

  @override
  Widget build(BuildContext context) {
    if (available.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Available', style: ProgressVisual.sectionTitle(context)),
        const SizedBox(height: 12),
        for (var i = 0; i < available.length; i++) ...[
          if (i > 0) const SizedBox(height: _cardGap),
          _buildEnabledCard(context, available[i]),
        ],
      ],
    );
  }

  void _openExam(BuildContext context, ExamProgressSummary exam) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamProgressScreen(examId: exam.examId),
      ),
    );
  }

  Widget _buildEnabledCard(BuildContext context, ExamProgressSummary exam) {
    if (_hasCanonicalSyllabus(exam.examId)) {
      final course = SyllabusService.instance.getCourseById(exam.examId)!;
      final unitCount = [
        for (final paper in course.papers)
          if (paper.syllabusUnits.isNotEmpty)
            ...paper.syllabusUnits
          else
            for (final part in paper.parts) ...part.syllabusUnits,
      ].length;
      return ExamTrackerCard(
        title: exam.title,
        subtitle: '$unitCount Syllabus Units • ${exam.paperCount} Papers',
        enabled: true,
        icon: _iconFor(exam.examId),
        accent: _accentFor(exam.examId),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CanonicalTrackerScreen(courseId: exam.examId),
            ),
          );
        },
      );
    }

    return ExamTrackerCard(
      title: exam.title,
      subtitle: '${_format(exam.maxMarks)} Marks • ${exam.paperCount} Papers',
      enabled: true,
      icon: _iconFor(exam.examId),
      accent: _accentFor(exam.examId),
      onTap: () => _openExam(context, exam),
    );
  }

  bool _hasCanonicalSyllabus(String courseId) {
    final course = SyllabusService.instance.getCourseById(courseId);
    if (course == null) return false;
    return course.papers.any(
      (paper) =>
          paper.syllabusUnits.isNotEmpty ||
          paper.parts.any((part) => part.syllabusUnits.isNotEmpty),
    );
  }

  Color _accentFor(String examId) {
    return switch (examId) {
      'group-iii' => _darkGreen,
      _ => _darkPurple,
    };
  }

  IconData _iconFor(String examId) {
    return switch (examId) {
      'group-iii' => Icons.menu_book_rounded,
      'group-ii' => Icons.school_rounded,
      _ => Icons.insights_rounded,
    };
  }

  String _format(double value) =>
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}
