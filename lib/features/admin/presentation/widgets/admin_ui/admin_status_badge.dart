import 'package:flutter/material.dart';

import '../../../../question_bank/data/models/question_models.dart';
import '../../../../tests/data/models/test_models.dart';
import '../../../theme/admin_colors.dart';

enum AdminStatusTone { draft, published, archived }

/// Compact status badge for Admin content lists and editors.
class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({
    super.key,
    required this.label,
    required this.tone,
  });

  factory AdminStatusBadge.question(
    QuestionPublicationStatus status, {
    Key? key,
  }) {
    return AdminStatusBadge(
      key: key,
      label: labelForQuestion(status),
      tone: switch (status) {
        QuestionPublicationStatus.draft => AdminStatusTone.draft,
        QuestionPublicationStatus.published => AdminStatusTone.published,
        QuestionPublicationStatus.archived => AdminStatusTone.archived,
      },
    );
  }

  factory AdminStatusBadge.test(
    TestPublicationStatus status, {
    Key? key,
  }) {
    return AdminStatusBadge(
      key: key,
      label: labelForTest(status),
      tone: switch (status) {
        TestPublicationStatus.draft => AdminStatusTone.draft,
        TestPublicationStatus.published => AdminStatusTone.published,
        TestPublicationStatus.archived => AdminStatusTone.archived,
      },
    );
  }

  final String label;
  final AdminStatusTone tone;

  static String labelForQuestion(QuestionPublicationStatus status) {
    switch (status) {
      case QuestionPublicationStatus.draft:
        return 'Draft';
      case QuestionPublicationStatus.published:
        return 'Published';
      case QuestionPublicationStatus.archived:
        return 'Archived';
    }
  }

  static String labelForTest(TestPublicationStatus status) {
    switch (status) {
      case TestPublicationStatus.draft:
        return 'Draft';
      case TestPublicationStatus.published:
        return 'Published';
      case TestPublicationStatus.archived:
        return 'Archived';
    }
  }

  /// Backward-compatible alias used by Question form chips.
  static String labelFor(QuestionPublicationStatus status) =>
      labelForQuestion(status);

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      AdminStatusTone.published => (
        AdminColors.published,
        AdminColors.successSoft,
      ),
      AdminStatusTone.draft => (AdminColors.draft, AdminColors.surfaceMuted),
      AdminStatusTone.archived => (
        AdminColors.archived,
        AdminColors.warningSoft,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
