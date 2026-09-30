import 'dart:async';

import 'package:flutter/material.dart';

import '../../../question_bank/data/models/question_models.dart';
import '../../data/admin_test_series_question_query.dart';
import '../../../tests/data/models/test_models.dart';
import '../../debug/admin_perf_trace.dart';
import '../../services/admin_question_test_assignment.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_status_badge.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Stages an ordered Question membership edit for one existing Test.
///
/// The only write is the single [AdminTestService.updateTest] call made by
/// Save Changes. Add, remove, manual-ID validation, Cancel, and back are all
/// read-only with respect to the backend.
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
  late final TextEditingController _manualIds;
  Timer? _searchTimer;
  TestModel? _test;
  List<String> _originalQuestionIds = const [];
  List<String> _stagedQuestionIds = const [];
  List<Question> _assigned = const [];
  List<Question> _available = const [];
  Map<String, String> _owners = const {};
  Map<String, List<String>> _legacyTestIds = const {};
  final Set<String> _selected = <String>{};
  bool _loading = true;
  bool _loadingMore = false;
  bool _saving = false;
  bool _saveCommitted = false;
  bool _validatingManualIds = false;
  bool _discardPromptOpen = false;
  bool _hasMore = false;
  String? _cursorDocumentId;
  String? _cursorSearchText;
  String? _error;
  String? _pageError;
  String? _mutationError;
  int _request = 0;

  TestModel get _current => _test ?? widget.test;
  bool get _dirty => !_sameIds(_originalQuestionIds, _stagedQuestionIds);
  int get _remaining =>
      (AdminQuestionTestAssignment.maxAssignedQuestionsPerTest -
              _stagedQuestionIds.length)
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
    _manualIds = TextEditingController();
    _loadFirstPage();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _search.dispose();
    _manualIds.dispose();
    super.dispose();
  }

  Future<void> _loadFirstPage() async {
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _pageError = null;
      _hasMore = false;
      _cursorDocumentId = null;
      _cursorSearchText = null;
      _selected.clear();
    });
    try {
      final initializing = _test == null;
      final current = initializing
          ? await AdminPerfTrace.span(
              'manageQuestions.load.test',
              () => _service.getTest(widget.test.id),
            )
          : _current;
      if (current == null) {
        throw const FormatException('Test was not found.');
      }
      final stagedIds = initializing
          ? List<String>.of(current.questionIds)
          : List<String>.of(_stagedQuestionIds);
      final loaded = await Future.wait([
        AdminPerfTrace.span(
          'manageQuestions.load.compatible',
          () => _service.loadCompatibleQuestionPage(
            current,
            searchText: _search.text,
          ),
        ),
        AdminPerfTrace.span(
          'manageQuestions.load.assigned',
          () => _service.loadQuestionsByIds(stagedIds),
        ),
      ]);
      final page = loaded[0] as QuestionBankPage;
      final assignedQuestions = loaded[1] as List<Question>;
      final assignmentState = await AdminPerfTrace.span(
        'manageQuestions.load.ownership',
        () => _service.loadQuestionAssignmentState([
          ...stagedIds,
          ...page.questions.map((question) => question.id),
        ]),
      );
      if (!mounted || request != _request) return;
      setState(() {
        _test = current;
        if (initializing) {
          _originalQuestionIds = List<String>.unmodifiable(current.questionIds);
          _stagedQuestionIds = List<String>.of(current.questionIds);
        }
        _assigned = _orderedAssigned(stagedIds, assignedQuestions);
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

  List<Question> _orderedAssigned(
    List<String> ids,
    Iterable<Question> questions,
  ) {
    final byId = <String, Question>{
      for (final question in questions) question.id: question,
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!,
    ];
  }

  void _stageQuestionIds(
    List<String> ids, {
    Iterable<Question> additionalQuestions = const [],
  }) {
    final unique = AdminTestService.dedupeQuestionIds(ids);
    final questions = <String, Question>{
      for (final question in _assigned) question.id: question,
      for (final question in _available) question.id: question,
      for (final question in additionalQuestions) question.id: question,
    };
    setState(() {
      _stagedQuestionIds = unique;
      _assigned = [
        for (final id in unique)
          if (questions[id] != null) questions[id]!,
      ];
      _selected.clear();
      _mutationError = null;
      _saveCommitted = false;
    });
  }

  void _assignSelected() {
    if (_selected.isEmpty) return;
    if (_selected.length > _remaining) {
      setState(
        () => _mutationError =
            'Only $_remaining Question${_remaining == 1 ? '' : 's'} can be added.',
      );
      return;
    }
    final selectedInPageOrder = [
      for (final question in _available)
        if (_selected.contains(question.id)) question.id,
    ];
    _stageQuestionIds([..._stagedQuestionIds, ...selectedInPageOrder]);
  }

  Future<void> _remove(String questionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Question?'),
        content: const Text(
          'This removal stays pending until you choose Save Changes.',
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
    _stageQuestionIds([
      for (final id in _stagedQuestionIds)
        if (id != questionId) id,
    ]);
  }

  Future<void> _stageManualQuestionIds() async {
    if (_validatingManualIds || _saving) return;
    setState(() {
      _validatingManualIds = true;
      _mutationError = null;
    });
    try {
      final ids = await _service.normalizeManagedQuestionIds(
        _current,
        _stagedQuestionIds,
        [_manualIds.text],
      );
      final questions = await _service.loadQuestionsByIds(ids);
      if (!mounted) return;
      _manualIds.clear();
      _stageQuestionIds([
        ..._stagedQuestionIds,
        ...ids,
      ], additionalQuestions: questions);
      setState(() => _validatingManualIds = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _validatingManualIds = false;
        _mutationError = _friendlyError(error);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_dirty || _saving) return;
    setState(() {
      _saving = true;
      _mutationError = null;
    });
    try {
      if (!_saveCommitted) {
        await AdminPerfTrace.span(
          'manageQuestions.save.write',
          () => _service.updateTest(
            _withQuestionIds(_current, _stagedQuestionIds),
          ),
        );
        _saveCommitted = true;
      }
      final fresh = await AdminPerfTrace.span(
        'manageQuestions.save.reloadTest',
        () => _service.getTest(_current.id),
      );
      if (fresh == null) {
        throw const FormatException('Saved Test could not be reloaded.');
      }
      if (!mounted) return;
      setState(() {
        _test = fresh;
        _originalQuestionIds = List<String>.unmodifiable(fresh.questionIds);
        _stagedQuestionIds = List<String>.of(fresh.questionIds);
        _saving = false;
      });
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _mutationError = _friendlyError(error);
      });
    }
  }

  Future<void> _requestLeave() async {
    if (_saving || _discardPromptOpen) return;
    if (!_dirty) {
      Navigator.of(context).pop(false);
      return;
    }
    _discardPromptOpen = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard unsaved Question changes?'),
        content: const Text(
          'Your staged Question membership changes have not been saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _discardPromptOpen = false;
    if (discard == true && mounted) Navigator.of(context).pop(false);
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

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String _ownerLabel(String owner) => owner == _current.id
      ? 'Ownership record conflict'
      : 'Assigned to another Test';

  bool _hasLegacyConflict(String id) {
    final references = _legacyTestIds[id] ?? const <String>[];
    return references.any(
      (testId) => testId != _current.id || !_originalQuestionIds.contains(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _requestLeave();
      },
      child: Scaffold(
        backgroundColor: AdminColors.backgroundTop,
        appBar: AppBar(title: Text('Manage Questions · ${_current.title}')),
        body: _loading ? const AdminLoadingSurface(rows: 5) : _body(context),
        bottomNavigationBar: _footer(),
      ),
    );
  }

  Widget _footer() {
    return SafeArea(
      top: false,
      child: Material(
        elevation: 8,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(AdminSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                key: const ValueKey('cancel-assignment-changes'),
                onPressed: _saving ? null : _requestLeave,
                child: const Text('Cancel'),
              ),
              const SizedBox(width: AdminSpacing.sm),
              FilledButton.icon(
                key: const ValueKey('save-assignment-changes'),
                onPressed: _dirty && !_saving ? _saveChanges : null,
                icon: _saving
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saving ? 'Saving…' : 'Save Changes'),
              ),
            ],
          ),
        ),
      ),
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
        _manualIdsSection(context),
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
                '${_stagedQuestionIds.length} / '
                '${AdminQuestionTestAssignment.maxAssignedQuestionsPerTest} assigned',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'Remaining capacity: $_remaining',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _dirty
                    ? 'Pending changes are not saved yet.'
                    : 'Add or remove Questions, then choose Save Changes.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _dirty
                      ? AdminColors.warning
                      : AdminColors.textSecondary,
                ),
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
        if (_assigned.isEmpty && _stagedQuestionIds.isEmpty)
          const Text('No Questions assigned yet.')
        else
          for (var i = 0; i < _stagedQuestionIds.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AdminSpacing.sm),
              child: _assignedRow(context, _stagedQuestionIds[i], i + 1),
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
            onPressed: _saving ? null : () => _remove(id),
            icon: const Icon(Icons.remove_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _manualIdsSection(BuildContext context) {
    return AdminSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual Question IDs',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AdminSpacing.xs),
          Text(
            'Enter one ID per line or separate IDs with commas.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AdminSpacing.sm),
          TextField(
            key: const ValueKey('managed-question-ids'),
            controller: _manualIds,
            enabled: !_saving && !_validatingManualIds,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'question-id-1, question-id-2',
            ),
          ),
          const SizedBox(height: AdminSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              key: const ValueKey('stage-manual-question-ids'),
              onPressed: _saving || _validatingManualIds
                  ? null
                  : _stageManualQuestionIds,
              icon: _validatingManualIds
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.playlist_add, size: 18),
              label: const Text('Stage IDs'),
            ),
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
                onPressed: _saving ? null : _assignSelected,
                icon: const Icon(Icons.playlist_add),
                label: Text('Stage ${_selected.length}'),
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
              key: const ValueKey('test-assignment-load-more'),
              onPressed: _loadMore,
              child: const Text('Load More'),
            ),
          ),
      ],
    );
  }

  Widget _availableRow(BuildContext context, Question question) {
    final owner = _owners[question.id];
    final alreadyStaged = _stagedQuestionIds.contains(question.id);
    final originalMember = _originalQuestionIds.contains(question.id);
    final ownerConflict =
        owner != null && (owner != _current.id || !originalMember);
    final legacyConflict = _hasLegacyConflict(question.id);
    final archived = question.status == QuestionPublicationStatus.archived;
    final unavailable =
        alreadyStaged || ownerConflict || legacyConflict || archived;
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
              alreadyStaged
                  ? 'Already staged for this Test'
                  : archived
                  ? 'Archived Question cannot be assigned'
                  : ownerConflict
                  ? _ownerLabel(owner)
                  : legacyConflict
                  ? 'Legacy Test reference not verified'
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
