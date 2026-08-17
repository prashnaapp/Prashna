import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/syllabus_service.dart';
import '../widgets/syllabus_scroll_body.dart';
import 'syllabus_units_screen.dart';

/// Papers that use Parts: Paper → Parts → Syllabus Units.
class SyllabusPartsScreen extends StatelessWidget {
  const SyllabusPartsScreen({
    super.key,
    required this.courseId,
    required this.paperId,
  });

  final String courseId;
  final String paperId;

  @override
  Widget build(BuildContext context) {
    final paper = SyllabusService.instance.getPaper(
      courseId: courseId,
      paperId: paperId,
    );
    final parts = paper?.parts ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(paper?.title ?? 'Parts')),
      body: SyllabusScrollBody(
        bottomInset: false,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Select Part', style: AppTextStyles.titleMedium(context)),
                const SizedBox(height: AppSpacing.lg),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < parts.length; i++) ...[
                        if (i > 0) const SizedBox(width: AppSpacing.sm),
                        _PartPill(
                          title: parts[i].displayName,
                          subtitle:
                              '${parts[i].syllabusUnits.length} Syllabus Units',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SyllabusUnitsScreen(
                                  courseId: courseId,
                                  paperId: paperId,
                                  partId: parts[i].id,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _PartPill extends StatelessWidget {
  const _PartPill({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pillAll,
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.pillAll,
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.soft,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleMedium(context),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
