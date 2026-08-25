import 'package:flutter/material.dart';

import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_test_service.dart';

/// Shared Admin leaf list: the actual Test documents at the end of a hierarchy.
class AdminManagedTestList extends StatelessWidget {
  const AdminManagedTestList({
    super.key,
    required this.tests,
    required this.service,
    required this.onChanged,
    required this.onCreate,
    this.emptyLabel = 'No tests in this folder yet.',
  });

  final List<TestModel> tests;
  final AdminTestService service;
  final Future<void> Function() onChanged;
  final VoidCallback onCreate;
  final String emptyLabel;

  Future<void> _openEdit(BuildContext context, TestModel test) async {
    await Navigator.of(context).pushNamed(AdminRoutes.testEdit, arguments: test);
    await onChanged();
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
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('+ Create Test'),
          ),
        ),
        const SizedBox(height: 16),
        if (tests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Text(emptyLabel),
          )
        else
          for (final test in tests) ...[
            Card(
              child: ListTile(
                title: Text(
                  test.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${test.questionCount} questions • ${test.marks} marks • '
                  '${test.durationMinutes} min • ${test.status.name}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => _openEdit(context, test),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    if (test.status != TestPublicationStatus.published)
                      IconButton(
                        tooltip: 'Publish',
                        onPressed: () => _setStatus(
                          context,
                          test,
                          TestPublicationStatus.published,
                        ),
                        icon: const Icon(Icons.visibility_outlined),
                      ),
                    if (test.status == TestPublicationStatus.published)
                      IconButton(
                        tooltip: 'Unpublish',
                        onPressed: () => _setStatus(
                          context,
                          test,
                          TestPublicationStatus.draft,
                        ),
                        icon: const Icon(Icons.visibility_off_outlined),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}
