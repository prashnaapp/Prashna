import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/syllabus_models.dart';
import '../syllabus_visual.dart';

/// Compact light header: back, course dropdown, balanced trailing space.
class SyllabusBrowserHeader extends StatelessWidget {
  const SyllabusBrowserHeader({
    super.key,
    required this.courseName,
    required this.courses,
    required this.selectedCourseId,
    required this.onBack,
    required this.onCourseSelected,
  });

  final String courseName;
  final List<SyllabusCourse> courses;
  final String selectedCourseId;
  final VoidCallback onBack;
  final ValueChanged<SyllabusCourse> onCourseSelected;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topInset = media.viewPadding.top > media.padding.top
        ? media.viewPadding.top
        : media.padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4, topInset + 4, 4, 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back',
              onPressed: onBack,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: SyllabusVisual.accent,
              ),
            ),
            Expanded(
              child: Center(
                child: PopupMenuButton<String>(
                  tooltip: 'Select course',
                  onSelected: (id) {
                    for (final course in courses) {
                      if (course.id == id) {
                        onCourseSelected(course);
                        return;
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    for (final course in courses)
                      PopupMenuItem<String>(
                        value: course.id,
                        child: Row(
                          children: [
                            Expanded(child: Text(course.name)),
                            if (course.id == selectedCourseId)
                              const Icon(
                                Icons.check_rounded,
                                size: 18,
                                color: SyllabusVisual.accent,
                              ),
                          ],
                        ),
                      ),
                  ],
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleLarge(context).copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: SyllabusVisual.accent,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: SyllabusVisual.accent,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }
}
