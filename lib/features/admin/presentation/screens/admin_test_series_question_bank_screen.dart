import 'dart:async';

import 'package:flutter/material.dart';

import '../../../question_bank/data/models/question_models.dart';
import '../../data/admin_question_scope.dart';
import '../../data/question_create_outcome.dart';
import '../../data/models/question_import_models.dart';
import '../../services/admin_question_service.dart';
import '../../services/admin_question_test_assignment.dart';
import '../../services/question_import_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_status_badge.dart';
import '../widgets/admin_ui/admin_surface.dart';
import 'admin_question_form_screen.dart';
import 'admin_question_import_screen.dart';

/// Test Series Question Bank for one [AdminQuestionScope].
///
/// Create and Import use this bank's locked ownership. Search and Load More
/// stay on the same equality filters.
class AdminTestSeriesQuestionBankScreen extends StatefulWidget {
  const AdminTestSeriesQuestionBankScreen({
    super.key,
    required this.scope,
    this.service,
    this.assignment,
    this.importService,
  });

  final AdminQuestionScope scope;
  final AdminQuestionService? service;
  final AdminQuestionTestAssignment? assignment;
  final QuestionImportService? importService;

  @override
  State<AdminTestSeriesQuestionBankScreen> createState() =>
      _AdminTestSeriesQuestionBankScreenState();
}

class _AdminTestSeriesQuestionBankScreenState
    extends State<AdminTestSeriesQuestionBankScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  late final AdminQuestionService _service;
  late final TextEditingController _searchController;
  List<Question> _questions = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;
  String? _pageError;
  String? _cursorDocumentId;
  String? _cursorSearchText;
  int _request = 0;
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _searchController = TextEditingController();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final request = ++_request;
    final search = _searchController.text;
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
      _questions = const [];
      _hasMore = false;
      _cursorDocumentId = null;
      _cursorSearchText = null;
    });
    try {
      final page = await _service.loadTestSeriesQuestionPage(
        widget.scope,
        searchText: search,
      );
      if (!mounted || request != _request) return;
      setState(() {
        _questions = page.questions;
        _hasMore = page.hasMore;
        _cursorDocumentId = page.cursorDocumentId;
        _cursorSearchText = page.cursorSearchText;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load questions: $error';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final request = _request;
    final search = _searchController.text;
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    try {
      final page = await _service.loadTestSeriesQuestionPage(
        widget.scope,
        searchText: search,
        cursorDocumentId: _cursorDocumentId,
        cursorSearchText: _cursorSearchText,
      );
      if (!mounted || request != _request) return;
      setState(() {
        final seen = {for (final question in _questions) question.id};
        _questions = [
          ..._questions,
          for (final question in page.questions)
            if (seen.add(question.id)) question,
        ];
        _hasMore = page.hasMore;
        _cursorDocumentId = page.cursorDocumentId;
        _cursorSearchText = page.cursorSearchText;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loadingMore = false;
        _pageError = 'Unable to load more questions: $error';
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _loadFirstPage);
  }

  Future<void> _create() async {
    final outcome = await Navigator.of(context).push<QuestionCreateOutcome>(
      MaterialPageRoute(
        builder: (_) => AdminQuestionFormScreen(
          scope: widget.scope,
          service: _service,
          assignment: widget.assignment,
        ),
      ),
    );
    if (!mounted || outcome == null) return;
    await _loadFirstPage();
    if (!mounted || !outcome.assignmentFailed) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(outcome.message ?? QuestionAssignmentFailed.message),
      ),
    );
  }

  Future<void> _import() async {
    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => AdminQuestionImportScreen(
          scope: widget.scope,
          service:
              widget.importService ??
              QuestionImportService(
                scope: widget.scope,
                assignment: widget.assignment,
              ),
        ),
      ),
    );
    if (!mounted || result == null || result == false) return;
    await _loadFirstPage();
    if (!mounted || result is! QuestionImportReport) return;
    final message = result.assignmentFailureMessage;
    if (message == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.pagePadding,
              AdminSpacing.pagePadding,
              AdminSpacing.pagePadding,
              0,
            ),
            child: Wrap(
              spacing: AdminSpacing.md,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  key: const ValueKey('test-series-question-bank-import'),
                  onPressed: _loading ? null : _import,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import Questions'),
                ),
                FilledButton.icon(
                  key: const ValueKey('test-series-question-bank-create'),
                  onPressed: _loading ? null : _create,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Question'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AdminSpacing.pagePadding,
              AdminSpacing.md,
              AdminSpacing.pagePadding,
              0,
            ),
            child: TextField(
              key: const ValueKey('test-series-question-bank-search'),
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search question text',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _body(context)),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading) return const AdminLoadingSurface();
    if (_error != null) {
      return AdminEmptyState(
        title: 'Unable to load questions',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _loadFirstPage,
          child: const Text('Retry'),
        ),
      );
    }
    if (_questions.isEmpty) {
      return AdminEmptyState(
        key: const ValueKey('test-series-question-bank-empty'),
        title: 'No questions yet',
        message: _searchController.text.trim().isEmpty
            ? 'No questions in this bank yet.'
            : 'No questions match this search.',
        icon: Icons.quiz_outlined,
      );
    }

    return ListView.separated(
      key: const ValueKey('test-series-question-bank-list'),
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: _questions.length + 1,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) {
        if (index == _questions.length) return _pageFooter();
        final question = _questions[index];
        final status = AdminQuestionRow.effectiveStatus(question);
        return AdminSurface(
          padding: const EdgeInsets.symmetric(
            horizontal: AdminSpacing.lg,
            vertical: AdminSpacing.md,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  AdminQuestionRow.previewText(question),
                  key: ValueKey('test-series-question-${question.id}'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AdminSpacing.md),
              AdminStatusBadge.question(status),
            ],
          ),
        );
      },
    );
  }

  Widget _pageFooter() {
    if (_pageError != null) {
      return Column(
        key: const ValueKey('test-series-question-bank-page-error'),
        children: [
          Text(_pageError!),
          const SizedBox(height: AdminSpacing.sm),
          FilledButton.tonal(
            onPressed: _loadingMore ? null : _loadMore,
            child: const Text('Retry'),
          ),
        ],
      );
    }
    if (_loadingMore) {
      return const Center(
        key: ValueKey('test-series-question-bank-loading-more'),
        child: Padding(
          padding: EdgeInsets.all(AdminSpacing.md),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_hasMore) {
      return Align(
        alignment: Alignment.centerLeft,
        child: FilledButton.tonal(
          key: const ValueKey('test-series-question-bank-load-more'),
          onPressed: _loadMore,
          child: const Text('Load More'),
        ),
      );
    }
    return const Text(
      'All questions loaded',
      key: ValueKey('test-series-question-bank-end'),
    );
  }
}
