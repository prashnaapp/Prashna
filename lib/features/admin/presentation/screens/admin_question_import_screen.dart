import 'package:flutter/material.dart';

import '../../data/models/question_import_models.dart';
import '../../services/question_import_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Premium Admin UI: paste JSON → validate → confirm import as drafts.
///
/// Import contract (parser, validator, draft-only atomic batch) is unchanged.
class AdminQuestionImportScreen extends StatefulWidget {
  const AdminQuestionImportScreen({
    super.key,
    this.service,
    this.embeddedInShell = false,
  });

  final QuestionImportService? service;
  final bool embeddedInShell;

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

  /// True after a successful batch write so callers can refresh lists.
  bool _dataChanged = false;

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

  void _leave() {
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(_dataChanged);
    }
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
      if (report.succeeded) {
        _dataChanged = true;
        // When opened from Question Bank (or any caller), return immediately
        // so the list can reload. Standalone/shell-root Import keeps the report.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(true);
          return;
        }
      }
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
    final theme = Theme.of(context);

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(AdminSpacing.pagePadding),
          children: [
            if (widget.embeddedInShell)
              const AdminPageHeader(
                title: 'Import Questions',
                subtitle:
                    'Validate bilingual JSON batches, then import only when every '
                    'record is valid. Imported questions always start as drafts.',
              )
            else ...[
              Text(
                'Validate bilingual JSON batches, then import only when every '
                'record is valid. Imported questions always start as drafts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AdminColors.textSecondary,
                ),
              ),
              const SizedBox(height: AdminSpacing.xl),
            ],
            AdminSurface(
              padding: const EdgeInsets.all(AdminSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Import workspace',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.xs),
                  Text(
                    'Paste a complete JSON import file. Validation runs on the '
                    'entire batch before any write.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AdminColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.lg),
                  TextField(
                    key: const ValueKey('import-json'),
                    controller: _jsonController,
                    maxLines: 16,
                    minLines: 10,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: AdminColors.textPrimary,
                      height: 1.4,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Import JSON',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.lg),
                  Wrap(
                    spacing: AdminSpacing.md,
                    runSpacing: AdminSpacing.md,
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
                ],
              ),
            ),
            const SizedBox(height: AdminSpacing.lg),
            AdminSurface(
              padding: const EdgeInsets.all(AdminSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Format guidance',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AdminSpacing.sm),
                  Text(
                    '• Submit a JSON array or documented batch envelope.\n'
                    '• Every record must validate before import proceeds.\n'
                    '• Successful import creates draft/inactive questions only.\n'
                    '• Nothing is published automatically.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AdminColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            if (_busy) ...[
              const SizedBox(height: AdminSpacing.lg),
              AdminSurface(
                padding: const EdgeInsets.all(AdminSpacing.xl),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AdminSpacing.md),
                    Text(
                      'Working…',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AdminSpacing.lg),
              AdminSurface(
                padding: const EdgeInsets.all(AdminSpacing.lg),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, color: AdminColors.danger),
                    const SizedBox(width: AdminSpacing.md),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AdminColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (validation != null) ...[
              const SizedBox(height: AdminSpacing.lg),
              AdminSurface(
                padding: const EdgeInsets.all(AdminSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validation',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.md),
                    _StatLine(
                      label: 'Total records',
                      value: '${validation.totalRecords}',
                    ),
                    _StatLine(
                      label: 'Valid records',
                      value: '${validation.validRecords}',
                    ),
                    _StatLine(
                      label: 'Invalid records',
                      value: '${validation.invalidRecords}',
                    ),
                    _StatLine(
                      label: 'Warnings',
                      value: '${validation.warnings.length}',
                    ),
                    _StatLine(
                      label: 'Duplicate/collision records',
                      value:
                          '${validation.duplicateOrCollisionRecords.length}',
                    ),
                    if (validation.canImport) ...[
                      const SizedBox(height: AdminSpacing.md),
                      Text(
                        'Batch is ready to import as drafts.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AdminColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (validation.errors.isNotEmpty) ...[
                      const SizedBox(height: AdminSpacing.lg),
                      Text(
                        'Errors',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AdminColors.danger,
                        ),
                      ),
                      for (final issue in validation.errors)
                        Padding(
                          padding: const EdgeInsets.only(top: AdminSpacing.sm),
                          child: Text(
                            issue.display,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AdminColors.textPrimary,
                            ),
                          ),
                        ),
                    ],
                    if (validation.warnings.isNotEmpty) ...[
                      const SizedBox(height: AdminSpacing.lg),
                      Text(
                        'Warnings',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AdminColors.warning,
                        ),
                      ),
                      for (final issue in validation.warnings)
                        Padding(
                          padding: const EdgeInsets.only(top: AdminSpacing.sm),
                          child: Text(
                            issue.display,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
            if (report != null) ...[
              const SizedBox(height: AdminSpacing.lg),
              AdminSurface(
                padding: const EdgeInsets.all(AdminSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Import report',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AdminSpacing.md),
                    _StatLine(
                      label: 'Records submitted',
                      value: '${report.recordsSubmitted}',
                    ),
                    _StatLine(
                      label: 'Records imported',
                      value: '${report.recordsImported}',
                    ),
                    _StatLine(
                      label: 'Records rejected',
                      value: '${report.recordsRejected}',
                    ),
                    if (report.succeeded) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: AdminSpacing.md),
                        child: Text(
                          'Import succeeded. All questions are drafts '
                          'pending human review.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AdminColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AdminSpacing.lg),
                      FilledButton.icon(
                        key: const ValueKey('import-done'),
                        onPressed: _leave,
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Done'),
                      ),
                    ],
                    if (report.createdQuestionIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AdminSpacing.sm),
                        child: Text(
                          'Question IDs created: '
                          '${report.createdQuestionIds.join(', ')}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    if (report.failureMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: AdminSpacing.md),
                        child: Text(
                          report.failureMessage!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AdminColors.danger,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );

    final hasCaller = Navigator.of(context).canPop();
    final body = PopScope(
      // When Import is a shell major destination (no caller), do not trap back.
      canPop: !hasCaller,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _leave();
      },
      child: content,
    );

    if (widget.embeddedInShell) {
      // Shell already supplies Scaffold; Material keeps TextField ink/theme safe.
      return Material(
        color: AdminColors.backgroundTop,
        child: body,
      );
    }
    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(
        title: const Text('Import Questions'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _leave,
        ),
      ),
      body: body,
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AdminColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AdminColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
