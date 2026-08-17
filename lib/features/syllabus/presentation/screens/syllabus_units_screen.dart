import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/syllabus_models.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_list_tile_card.dart';
import '../widgets/syllabus_scroll_body.dart';
import 'syllabus_unit_tests_screen.dart';

/// Lists final syllabus units under a Paper or Part.
class SyllabusUnitsScreen extends StatelessWidget {
  const SyllabusUnitsScreen({
    super.key,
    required this.courseId,
    required this.paperId,
    this.partId,
  });

  final String courseId;
  final String paperId;
  final String? partId;

  @override
  Widget build(BuildContext context) {
    final paper = SyllabusService.instance.getPaper(
      courseId: courseId,
      paperId: paperId,
    );
    final part = partId == null
        ? null
        : SyllabusService.instance.getPart(
            courseId: courseId,
            paperId: paperId,
            partId: partId!,
          );
    final units = part?.syllabusUnits ?? paper?.syllabusUnits ?? const [];
    final title = part?.displayName ?? paper?.title ?? 'Syllabus Units';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Select Syllabus Unit',
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (var i = 0; i < units.length; i++) ...[
                  SyllabusListTileCard(
                    title: units[i].displayName,
                    accentColor: AppColors.accentAt(i),
                    icon: Icons.menu_book_rounded,
                    onTap: () => _openUnit(context, units[i]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _openUnit(BuildContext context, SyllabusUnit unit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SyllabusUnitTestsScreen(
          courseId: courseId,
          paperId: paperId,
          partId: partId,
          unitId: unit.id,
        ),
      ),
    );
  }
}
