import 'package:flutter/material.dart';

import '../../data/models/question_import_models.dart';
import '../../services/question_import_service.dart';

/// Minimal admin UI: paste JSON → validate → confirm import as drafts.
class AdminQuestionImportScreen extends StatefulWidget {
  const AdminQuestionImportScreen({super.key, this.service});

  final QuestionImportService? service;

  @override
  State<AdminQuestionImportScreen> createState() =>
      _AdminQuestionImportScreenState();
}

class _AdminQuestionImportScreenState extends State<AdminQuestionImportScreen> {
  late final QuestionImportService _service;
  final _jsonController = TextEditingController();

  QuestionImportValidationResult? _validation;
  QuestionImportReport? _importReport;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? QuestionImportService();
  }

  @override
  void dispose() {
    _jsonController.dispose();
    super.dispose();
  }

  Future<void> _validate() async {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _busy = true;
      _error = null;
      _validation = null;
      _importReport = null;
    });
    try {
      final result = await _service.validateJson(_jsonController.text);
      if (!mounted) return;
      setState(() {
        _validation = result;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString().replaceFirst('FormatException: ', '');
      });
    }
  }

  Future<void> _import() async {
    final validation = _validation;
    if (validation == null || !validation.canImport) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import as drafts?'),
        content: Text(
          '${validation.totalRecords} validated question(s) will be imported '
          'as draft/inactive. Nothing will be published automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import drafts'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() {
      _busy = true;
      _error = null;
      _importReport = null;
    });
    try {
      final report = await _service.importValidatedBatch(validation);
      if (!mounted) return;
      setState(() {
        _importReport = report;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final validation = _validation;
    final report = _importReport;
    return Scaffold(
      appBar: AppBar(title: const Text('Import Questions')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Paste a JSON import file, validate the entire batch, then '
                'import only when every record is valid. Imported questions '
                'always start as drafts.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('import-json'),
                controller: _jsonController,
                maxLines: 18,
                decoration: const InputDecoration(
                  labelText: 'Import JSON',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    key: const ValueKey('validate-import'),
                    onPressed: _busy ? null : _validate,
                    child: const Text('Validate'),
                  ),
                  FilledButton.tonal(
                    key: const ValueKey('confirm-import'),
                    onPressed: _busy || validation?.canImport != true
                        ? null
                        : _import,
                    child: const Text('Import as drafts'),
                  ),
                ],
              ),
              if (_busy) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (validation != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Validation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Total records: ${validation.totalRecords}'),
                Text('Valid records: ${validation.validRecords}'),
                Text('Invalid records: ${validation.invalidRecords}'),
                Text('Warnings: ${validation.warnings.length}'),
                Text(
                  'Duplicate/collision records: '
                  '${validation.duplicateOrCollisionRecords.length}',
                ),
                if (validation.errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Errors', style: Theme.of(context).textTheme.titleSmall),
                  for (final issue in validation.errors)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(issue.display),
                    ),
                ],
                if (validation.warnings.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Warnings',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  for (final issue in validation.warnings)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(issue.display),
                    ),
                ],
              ],
              if (report != null) ...[
                const SizedBox(height: 24),
                Text(
                  'Import report',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Records submitted: ${report.recordsSubmitted}'),
                Text('Records imported: ${report.recordsImported}'),
                Text('Records rejected: ${report.recordsRejected}'),
                if (report.createdQuestionIds.isNotEmpty)
                  Text(
                    'Question IDs created: ${report.createdQuestionIds.join(', ')}',
                  ),
                if (report.failureMessage != null)
                  Text(
                    report.failureMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (report.succeeded)
                  Text(
                    'Import succeeded. All questions are drafts pending human review.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
