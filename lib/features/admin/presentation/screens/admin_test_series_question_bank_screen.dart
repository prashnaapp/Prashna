import 'dart:async';

import 'package:flutter/material.dart';

import '../../../question_bank/data/models/question_models.dart';
import '../../admin_routes.dart';
import '../../data/admin_content_callable_client.dart';
import '../../data/admin_question_scope.dart';
import '../../data/question_create_outcome.dart';
import '../../data/models/question_import_models.dart';
import '../../services/admin_question_service.dart';
import '../../services/admin_question_test_assignment.dart';
import '../../services/question_import_service.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_question_row.dart';
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
  AdminQuestionAssignmentState _assignmentState =
      const AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
  bool _assignmentLookupFailed = false;
  final Set<String> _deletingQuestionIds = {};

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

  Future<AdminQuestionAssignmentState> _loadAssignmentHints(
    List<Question> questions,
  ) async {
    final ids = [
      for (final question in questions)
        if (question.id.trim().isNotEmpty) question.id,
    ];
    if (ids.isEmpty) {
      _assignmentLookupFailed = false;
      return const AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
    }
    try {
      final owners = <String, String>{};
      final legacyTestIds = <String, List<String>>{};
      for (var offset = 0; offset < ids.length; offset += 500) {
        final end = offset + 500 > ids.length ? ids.length : offset + 500;
        final chunk = ids.sublist(offset, end);
        final state = await _service.loadQuestionAssignmentState(chunk);
        owners.addAll(state.owners);
        legacyTestIds.addAll(state.legacyTestIds);
      }
      _assignmentLookupFailed = false;
      return AdminQuestionAssignmentState(
        owners: owners,
        legacyTestIds: legacyTestIds,
      );
    } catch (_) {
      _assignmentLookupFailed = true;
      return const AdminQuestionAssignmentState(owners: {}, legacyTestIds: {});
    }
  }

  Future<void> _requestDelete(Question question) async {
    if (_deletingQuestionIds.contains(question.id)) return;
    final confirmed = await AdminQuestionRow.confirmPermanentDelete(context);
    if (!confirmed || !mounted) return;
    setState(() => _deletingQuestionIds.add(question.id));
    try {
      await _service.deleteQuestion(question.id);
      if (!mounted) return;
      setState(() {
        _deletingQuestionIds.remove(question.id);
        _questions = [
          for (final item in _questions)
            if (item.id != question.id) item,
        ];
        final owners = Map<String, String>.from(_assignmentState.owners);
        owners.remove(question.id);
        final legacy = Map<String, List<String>>.from(
          _assignmentState.legacyTestIds,
        );
        legacy.remove(question.id);
        _assignmentState = AdminQuestionAssignmentState(
          owners: owners,
          legacyTestIds: legacy,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Question deleted.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _deletingQuestionIds.remove(question.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete question: $error')),
      );
    }
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
      final assignmentState = await _loadAssignmentHints(page.questions);
      if (!mounted || request != _request) return;
      setState(() {
        _questions = page.questions;
        _assignmentState = assignmentState;
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
      final assignmentState = await _loadAssignmentHints([
        ..._questions,
        ...page.questions,
      ]);
      if (!mounted || request != _request) return;
      setState(() {
        final seen = {for (final question in _questions) question.id};
        _questions = [
          ..._questions,
          for (final question in page.questions)
            if (seen.add(question.id)) question,
        ];
        _assignmentState = assignmentState;
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

  Future<void> _openEdit(Question question) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.questionEdit, arguments: question);
    if (mounted && changed == true) await _loadFirstPage();
  }

  Future<void> _requestLifecycleStatus(
    Question question,
    QuestionPublicationStatus status,
  ) async {
    if (status == QuestionPublicationStatus.archived) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Archive Question?'),
            content: const Text(
              'This question will be removed from Student Practice and new Tests.\n'
              'Existing historical records will not be deleted.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Archive'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }
    await _setStatus(question, status);
  }

  Future<void> _setStatus(
    Question question,
    QuestionPublicationStatus status,
  ) async {
    try {
      await _service.setStatus(question.id, status);
      if (mounted) await _loadFirstPage();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $error')),
      );
    }
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
        return AdminQuestionRow(
          question: question,
          onEdit: () => _openEdit(question),
          onRequestStatus: (status) =>
              _requestLifecycleStatus(question, status),
          onDelete:
              _assignmentLookupFailed ||
                  _deletingQuestionIds.contains(question.id) ||
                  !AdminQuestionService.canDeleteQuestion(
                    question,
                    _assignmentState,
                  )
              ? null
              : () => _requestDelete(question),
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
