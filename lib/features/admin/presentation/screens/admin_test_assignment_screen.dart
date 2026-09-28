import 'dart:async';

import 'package:flutter/material.dart';

import '../../../question_bank/data/models/question_models.dart';
import '../../../tests/data/models/test_models.dart';
import '../../services/admin_question_test_assignment.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_status_badge.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Manage the ordered Question assignment for one existing Test.
///
/// All mutations go through [AdminTestService.updateTest], which reaches the
/// Phase 3A transaction. This screen never writes tests or assignments
/// directly.
class AdminTestAssignmentScreen extends StatefulWidget {
  const AdminTestAssignmentScreen({
    super.key,
    required this.test,
    this.service,
  });

  final TestModel test;
  final AdminTestService? service;

  @override
  State<AdminTestAssignmentScreen> createState() =>
      _AdminTestAssignmentScreenState();
}

class _AdminTestAssignmentScreenState extends State<AdminTestAssignmentScreen> {
  static const _searchDebounce = Duration(milliseconds: 300);

  late final AdminTestService _service;
  late final TextEditingController _search;
  Timer? _searchTimer;
  TestModel? _test;
  List<Question> _assigned = const [];
  List<Question> _available = const [];
  Map<String, String> _owners = const {};
  Map<String, List<String>> _legacyTestIds = const {};
  final Set<String> _selected = <String>{};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _cursorDocumentId;
  String? _cursorSearchText;
  String? _error;
  String? _pageError;
  String? _mutationError;
  int _request = 0;

  TestModel get _current => _test ?? widget.test;
  int get _remaining =>
      (AdminQuestionTestAssignment.maxAssignedQuestionsPerTest -
              _current.questionIds.length)
          .clamp(0, AdminQuestionTestAssignment.maxAssignedQuestionsPerTest);

  bool get _isTestSeries =>
      _current.category == TestCategoryType.partTests ||
      _current.category == TestCategoryType.mockTests ||
      _current.category == TestCategoryType.previousYear;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _search = TextEditingController()..addListener(_onSearchChanged);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
      _mutationError = null;
      _hasMore = false;
      _cursorDocumentId = null;
      _cursorSearchText = null;
      _selected.clear();
    });
    try {
      final current = await _service.getTest(widget.test.id) ?? widget.test;
      final page = await _service.loadCompatibleQuestionPage(
        current,
        searchText: _search.text,
      );
      final assignedQuestions = await _service.loadQuestionsByIds(
        current.questionIds,
      );
      final assignmentState = await _service.loadQuestionAssignmentState([
        ...current.questionIds,
        ...page.questions.map((question) => question.id),
      ]);
      if (!mounted || request != _request) return;
      setState(() {
        _test = current;
        _assigned = _orderedAssigned(current, assignedQuestions);
        _available = page.questions;
        _owners = assignmentState.owners;
        _legacyTestIds = assignmentState.legacyTestIds;
        _hasMore = page.hasMore;
        _cursorDocumentId = page.cursorDocumentId;
        _cursorSearchText = page.cursorSearchText;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load assignment data: $error';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final request = _request;
    setState(() {
      _loadingMore = true;
      _pageError = null;
    });
    try {
      final page = await _service.loadCompatibleQuestionPage(
        _current,
        searchText: _search.text,
        cursorDocumentId: _cursorDocumentId,
        cursorSearchText: _cursorSearchText,
      );
      final assignmentState = await _service.loadQuestionAssignmentState(
        page.questions.map((question) => question.id).toList(),
      );
      if (!mounted || request != _request) return;
      setState(() {
        final seen = {for (final question in _available) question.id};
        _available = [
          ..._available,
          for (final question in page.questions)
            if (seen.add(question.id)) question,
        ];
        _owners = {..._owners, ...assignmentState.owners};
        _legacyTestIds = {..._legacyTestIds, ...assignmentState.legacyTestIds};
        _hasMore = page.hasMore;
        _cursorDocumentId = page.cursorDocumentId;
        _cursorSearchText = page.cursorSearchText;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _loadingMore = false;
        _pageError = 'Unable to load more Questions: $error';
      });
    }
  }

  void _onSearchChanged() {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, _loadFirstPage);
  }

  List<Question> _orderedAssigned(TestModel test, List<Question> questions) {
    final byId = <String, Question>{
      for (final question in questions) question.id: question,
    };
    return [
      for (final id in test.questionIds)
        if (byId[id] != null) byId[id]!,
    ];
  }

  Future<void> _mutateAssignments(List<String> ids) async {
    final current = _current;
    final unique = <String>[];
    final seen = <String>{};
    for (final id in ids) {
      if (id.trim().isNotEmpty && seen.add(id.trim())) unique.add(id.trim());
    }
    setState(() {
      _mutationError = null;
      _loading = true;
    });
    try {
      await _service.updateTest(_withQuestionIds(current, unique));
      await _loadFirstPage();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _mutationError = _friendlyError(error);
      });
    }
  }

  Future<void> _assignSelected() async {
    if (_selected.isEmpty) return;
    if (_selected.length > _remaining) {
      setState(
        () => _mutationError =
            'Only $_remaining Question${_remaining == 1 ? '' : 's'} can be added.',
      );
      return;
    }
    await _mutateAssignments([..._current.questionIds, ..._selected]);
  }

  Future<void> _remove(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Question?'),
        content: const Text(
          'This removes the Question from this Test. The Question itself '
          'will remain in its Question Bank.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _mutateAssignments([
      for (final id in _current.questionIds)
        if (id != questionId) id,
    ]);
  }

  TestModel _withQuestionIds(TestModel test, List<String> ids) {
    return TestModel(
      id: test.id,
      examId: test.examId,
      category: test.category,
      title: test.title,
      description: test.description,
      questionCount: ids.length,
      marks: test.marks,
      durationMinutes: test.durationMinutes,
      negativeMarking: test.negativeMarking,
      difficulty: test.difficulty,
      questionIds: ids,
      status: test.status,
      paperId: test.paperId,
      partId: test.partId,
      syllabusUnitId: test.syllabusUnitId,
      majorStudyAreaId: test.majorStudyAreaId,
      contentTopicId: test.contentTopicId,
      canonicalTopicId: test.canonicalTopicId,
      lessonId: test.lessonId,
      scopeShape: test.scopeShape,
      year: test.year,
      seriesId: test.seriesId,
    );
  }

  String _friendlyError(Object error) {
    if (error is FormatException) return error.message;
    return 'Could not update Question assignments. Please retry.';
  }

  String _ownerLabel(String owner) => owner == _current.id
      ? 'Already assigned to this Test'
      : 'Assigned to another Test';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: Text('Manage Questions · ${_current.title}')),
      body: _loading && _test == null
          ? const AdminLoadingSurface(rows: 5)
          : _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_error != null) {
      return AdminEmptyState(
        title: 'Unable to load Questions',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _loadFirstPage,
          child: const Text('Retry'),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      children: [
        _header(context),
        if (_mutationError != null) ...[
          const SizedBox(height: AdminSpacing.md),
          _message(_mutationError!, isError: true),
        ],
        const SizedBox(height: AdminSpacing.lg),
        _assignedSection(context),
        const SizedBox(height: AdminSpacing.xl),
        _availableSection(context),
      ],
    );
  }

  Widget _header(BuildContext context) {
    return AdminSurface(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AdminSpacing.lg,
        runSpacing: AdminSpacing.sm,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_current.questionIds.length} / '
                '${AdminQuestionTestAssignment.maxAssignedQuestionsPerTest} assigned',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Remaining capacity: $_remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          AdminStatusBadge.test(_current.status),
        ],
      ),
    );
  }

  Widget _assignedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Assigned Questions',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AdminSpacing.sm),
        if (_assigned.isEmpty && _current.questionIds.isEmpty)
          const Text('No Questions assigned yet.')
        else
          for (var i = 0; i < _current.questionIds.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: _assignedRow(context, _current.questionIds[i], i + 1),
            ),
      ],
    );
  }

  Widget _assignedRow(BuildContext context, String id, int position) {
    Question? question;
    for (final candidate in _assigned) {
      if (candidate.id == id) {
        question = candidate;
        break;
      }
    }
    final owner = _owners[id];
    final legacyReferences = _legacyTestIds[id] ?? const <String>[];
    final missing = question == null;
    return AdminSurface(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$position.', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: AdminSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  missing
                      ? 'Missing Question reference: $id'
                      : AdminQuestionRow.previewText(question),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: missing ? AdminColors.warning : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  missing
                      ? legacyReferences.isNotEmpty
                            ? 'Legacy Test reference not verified; the reference '
                                  'was not removed automatically.'
                            : 'The reference was not removed automatically.'
                      : [
                          question.resolvedItemFormat.name,
                          '${question.marks} mark${question.marks == 1 ? '' : 's'}',
                          if (owner == null && legacyReferences.isNotEmpty)
                            'Legacy Test reference not verified',
                          if (owner != null && owner != _current.id)
                            _ownerLabel(owner),
                        ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            key: ValueKey('remove-question-$id'),
            tooltip: 'Remove Question',
            onPressed: _loading ? null : () => _remove(id),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _availableSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Add Questions',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (_selected.isNotEmpty)
              FilledButton.icon(
                key: const ValueKey('assign-selected-questions'),
                onPressed: _loading ? null : _assignSelected,
                icon: const Icon(Icons.playlist_add),
                label: Text('Assign ${_selected.length}'),
              ),
          ],
        ),
        const SizedBox(height: AdminSpacing.sm),
        TextField(
          key: const ValueKey('test-assignment-search'),
          controller: _search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search compatible Questions',
            isDense: true,
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        if (_available.isEmpty)
          Text(
            _isTestSeries
                ? 'No compatible Questions match this bank.'
                : 'No compatible Chapter Questions found.',
          )
        else
          for (final question in _available) _availableRow(context, question),
        if (_pageError != null) ...[
          const SizedBox(height: AdminSpacing.sm),
          _message(_pageError!, isError: true),
          FilledButton.tonal(
            onPressed: _loadingMore ? null : _loadMore,
            child: const Text('Retry'),
          ),
        ] else if (_loadingMore)
          const Padding(
            padding: EdgeInsets.all(AdminSpacing.md),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_hasMore)
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonal(
              key: ValueKey('test-assignment-load-more'),
              onPressed: _loadMore,
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }

  Widget _availableRow(BuildContext context, Question question) {
    final owner = _owners[question.id];
    final legacyReferences = _legacyTestIds[question.id] ?? const <String>[];
    final alreadyAssigned = _current.questionIds.contains(question.id);
    final unavailable =
        alreadyAssigned || owner != null || legacyReferences.isNotEmpty;
    final selected = _selected.contains(question.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: AdminSurface(
        child: Material(
          color: Colors.transparent,
          child: CheckboxListTile(
            key: ValueKey('assignable-question-${question.id}'),
            value: selected,
            onChanged: unavailable || (_remaining == 0 && !selected)
                ? null
                : (value) {
                    setState(() {
                      if (value == true) {
                        _selected.add(question.id);
                      } else {
                        _selected.remove(question.id);
                      }
                    });
                  },
            title: Text(AdminQuestionRow.previewText(question)),
            subtitle: Text(
              unavailable
                  ? alreadyAssigned
                        ? 'Already assigned to this Test'
                        : owner != null
                        ? _ownerLabel(owner)
                        : 'Legacy Test reference not verified'
                  : '${question.resolvedItemFormat.name} · ${question.marks} mark${question.marks == 1 ? '' : 's'}',
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ),
    );
  }

  Widget _message(String message, {required bool isError}) {
    return Container(
      padding: const EdgeInsets.all(AdminSpacing.md),
      color: isError ? AdminColors.warning.withValues(alpha: 0.12) : null,
      child: Text(message),
    );
  }
}
