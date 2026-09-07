import 'package:flutter/material.dart';

import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_spacing.dart';
import 'admin_ui/admin_empty_state.dart';
import 'admin_ui/admin_test_row.dart';

/// Shared Admin leaf list: the actual Test documents at the end of a hierarchy.
class AdminManagedTestList extends StatelessWidget {
  const AdminManagedTestList({
    super.key,
    required this.tests,
    required this.service,
    required this.onChanged,
    required this.onCreate,
    this.emptyLabel = 'No tests in this folder yet.',
    this.emptyMessage =
        'Create the first test for this scope to start managing content.',
    this.scopeLabel,
  });

  final List<TestModel> tests;
  final AdminTestService service;
  final Future<void> Function() onChanged;
  final VoidCallback onCreate;
  final String emptyLabel;
  final String emptyMessage;
  final String? scopeLabel;

  Future<void> _openEdit(BuildContext context, TestModel test) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testEdit, arguments: test);
    if (changed == true) await onChanged();
  }

  Future<void> _setStatus(
    BuildContext context,
    TestModel test,
    TestPublicationStatus status,
  ) async {
    if (status == TestPublicationStatus.published) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publish test?'),
          content: const Text(
            'Students with course access will be able to start this test.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    try {
      await service.setStatus(test.id, status);
      await onChanged();
    } catch (error) {
      if (!context.mounted) return;
      final message = error is FormatException
          ? error.message
          : 'Could not update test. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Managed Tests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (scopeLabel != null && scopeLabel!.isNotEmpty) ...[
                    const SizedBox(height: AdminSpacing.xs),
                    Text(
                      scopeLabel!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Create Test'),
            ),
          ],
        ),
        const SizedBox(height: AdminSpacing.lg),
        if (tests.isEmpty)
          AdminEmptyState(
            title: emptyLabel,
            message: emptyMessage,
            icon: Icons.assignment_outlined,
          )
        else
          for (final test in tests) ...[
            AdminTestRow(
              test: test,
              onEdit: () => _openEdit(context, test),
              onPublish: test.status != TestPublicationStatus.published
                  ? () => _setStatus(
                      context,
                      test,
                      TestPublicationStatus.published,
                    )
                  : null,
              onUnpublish: test.status == TestPublicationStatus.published
                  ? () => _setStatus(
                      context,
                      test,
                      TestPublicationStatus.draft,
                    )
                  : null,
            ),
            const SizedBox(height: AdminSpacing.md),
          ],
      ],
    );
  }
}
