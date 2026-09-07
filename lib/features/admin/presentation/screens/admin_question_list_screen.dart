import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../question_bank/data/models/question_models.dart';
import '../../../syllabus/data/models/syllabus_models.dart';
import '../../../syllabus/services/syllabus_service.dart';
import '../../admin_routes.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_surface.dart';

class AdminQuestionListScreen extends StatefulWidget {
  const AdminQuestionListScreen({
    super.key,
    this.service,
    this.syllabusService,
    this.embeddedInShell = false,
  });

  final AdminQuestionService? service;
  final SyllabusService? syllabusService;
  final bool embeddedInShell;

  @override
  State<AdminQuestionListScreen> createState() =>
      _AdminQuestionListScreenState();
}

class _AdminQuestionListScreenState extends State<AdminQuestionListScreen> {
  late final AdminQuestionService _service;
  SyllabusService get _syllabus =>
      widget.syllabusService ?? SyllabusService.instance;

  List<Course> _courses = const [];
  List<Question> _questions = const [];
  String? _courseId;
  QuestionPublicationStatus? _statusFilter;
  String _search = '';

  /// Cascading syllabus filter IDs (null = any).
  String? _paperFilter;
  String? _majorStudyAreaFilter;
  String? _contentTopicFilter;
  String? _partFilter;
  String? _topicFilter;
  String? _lessonFilter;
  String? _syllabusUnitFilter;

  String? _error;
  bool _loadingCourses = true;
  bool _loadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _loadCourses();
  }

  void _clearHierarchyFilters() {
    _paperFilter = null;
    _majorStudyAreaFilter = null;
    _contentTopicFilter = null;
    _partFilter = null;
    _topicFilter = null;
    _lessonFilter = null;
    _syllabusUnitFilter = null;
  }

  Future<void> _loadCourses() async {
    try {
      final courses = await _service.loadCourses();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _courseId = courses.isEmpty ? null : courses.first.courseId;
        _loadingCourses = false;
      });
      if (_courseId != null) await _loadQuestions();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _error = 'Unable to load courses: $error';
      });
    }
  }

  Future<void> _loadQuestions() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) return;
    setState(() {
      _loadingQuestions = true;
      _error = null;
    });
    try {
      final questions = await _service.loadQuestions(courseId);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loadingQuestions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingQuestions = false;
        _error = 'Unable to load questions: $error';
      });
    }
  }

  Future<void> _openCreate() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.questionCreate);
    if (mounted && changed == true) await _loadQuestions();
  }

  Future<void> _openEdit(Question question) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.questionEdit, arguments: question);
    if (mounted && changed == true) await _loadQuestions();
  }

  Future<void> _openImport() async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.questionImport);
    if (mounted && changed == true) await _loadQuestions();
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
      if (mounted) await _loadQuestions();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update status: $error')),
      );
    }
  }

  bool get _hasActiveFilters {
    return _search.trim().isNotEmpty ||
        _statusFilter != null ||
        _paperFilter != null ||
        _majorStudyAreaFilter != null ||
        _contentTopicFilter != null ||
        _partFilter != null ||
        _topicFilter != null ||
        _lessonFilter != null ||
        _syllabusUnitFilter != null;
  }

  List<Question> get _visibleQuestions {
    final query = _search.trim().toLowerCase();
    return _questions
        .where((question) {
          final status =
              question.status ??
              (question.isActive
                  ? QuestionPublicationStatus.published
                  : QuestionPublicationStatus.archived);
          if (_statusFilter != null && status != _statusFilter) return false;

          if (_paperFilter != null && question.paperId != _paperFilter) {
            return false;
          }
          if (_majorStudyAreaFilter != null &&
              question.majorStudyAreaId != _majorStudyAreaFilter) {
            return false;
          }
          if (_contentTopicFilter != null &&
              question.contentTopicId != _contentTopicFilter) {
            return false;
          }
          if (_partFilter != null && question.partId != _partFilter) {
            return false;
          }
          final topicId = (question.syllabus?.topicId?.isNotEmpty == true)
              ? question.syllabus!.topicId!
              : question.topicId;
          if (_topicFilter != null && topicId != _topicFilter) {
            return false;
          }
          if (_lessonFilter != null && question.lessonId != _lessonFilter) {
            return false;
          }
          if (_syllabusUnitFilter != null &&
              question.syllabusUnitId != _syllabusUnitFilter) {
            return false;
          }

          if (query.isEmpty) return true;
          return question.question.toLowerCase().contains(query) ||
              question.id.toLowerCase().contains(query) ||
              question.paperId.toLowerCase().contains(query) ||
              (question.partId ?? '').toLowerCase().contains(query) ||
              (question.contentTopicId ?? '').toLowerCase().contains(query) ||
              (question.majorStudyAreaId ?? '').toLowerCase().contains(query) ||
              (question.lessonId ?? '').toLowerCase().contains(query) ||
              (question.syllabusUnitId ?? '').toLowerCase().contains(query) ||
              topicId.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  List<Widget> get _headerActions => [
    FilledButton.icon(
      key: const ValueKey('question-list-create'),
      onPressed: _courseId == null ? null : _openCreate,
      icon: const Icon(Icons.add, size: 18),
      label: const Text('+ Create Question'),
    ),
    OutlinedButton.icon(
      key: const ValueKey('question-list-import'),
      onPressed: _openImport,
      icon: const Icon(Icons.upload_file_outlined, size: 18),
      label: const Text('Import Questions'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;
        final contentW = maxW < AdminSpacing.contentMaxWidth
            ? maxW
            : AdminSpacing.contentMaxWidth;

        return SizedBox(
          width: maxW,
          height: maxH,
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentW,
              height: maxH,
              child: _buildBody(context),
            ),
          ),
        );
      },
    );

    if (widget.embeddedInShell) return body;

    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: const Text('Question Bank')),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loadingCourses) {
      return const AdminLoadingSurface();
    }
    if (_error != null && _courses.isEmpty) {
      return AdminEmptyState(
        title: 'Unable to load courses',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: () {
            setState(() {
              _loadingCourses = true;
              _error = null;
            });
            _loadCourses();
          },
          child: const Text('Retry'),
        ),
      );
    }
    if (_courses.isEmpty) {
      return const AdminEmptyState(
        title: 'No courses available',
        message: 'No published courses are available for question management.',
        icon: Icons.school_outlined,
      );
    }

    final visible = _visibleQuestions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AdminSpacing.pagePadding,
            AdminSpacing.pagePadding,
            AdminSpacing.pagePadding,
            AdminSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                title: 'Question Bank',
                subtitle:
                    'Manage, review, publish, archive, and organize your exam questions.',
                actions: _headerActions,
              ),
              _FilterWorkspace(
                courses: _courses,
                syllabus: _syllabus,
                courseId: _courseId,
                statusFilter: _statusFilter,
                paperFilter: _paperFilter,
                majorStudyAreaFilter: _majorStudyAreaFilter,
                contentTopicFilter: _contentTopicFilter,
                partFilter: _partFilter,
                topicFilter: _topicFilter,
                lessonFilter: _lessonFilter,
                syllabusUnitFilter: _syllabusUnitFilter,
                onCourseChanged: (value) async {
                  setState(() {
                    _courseId = value;
                    _clearHierarchyFilters();
                  });
                  await _loadQuestions();
                },
                onSearchChanged: (value) => setState(() => _search = value),
                onStatusChanged: (value) =>
                    setState(() => _statusFilter = value),
                onPaperChanged: (value) => setState(() {
                  _paperFilter = value;
                  _majorStudyAreaFilter = null;
                  _contentTopicFilter = null;
                  _partFilter = null;
                  _topicFilter = null;
                  _lessonFilter = null;
                  _syllabusUnitFilter = null;
                }),
                onMajorStudyAreaChanged: (value) => setState(() {
                  _majorStudyAreaFilter = value;
                  _contentTopicFilter = null;
                }),
                onContentTopicChanged: (value) =>
                    setState(() => _contentTopicFilter = value),
                onPartChanged: (value) => setState(() {
                  _partFilter = value;
                  _topicFilter = null;
                  _lessonFilter = null;
                  _syllabusUnitFilter = null;
                }),
                onTopicChanged: (value) => setState(() {
                  _topicFilter = value;
                  _lessonFilter = null;
                }),
                onLessonChanged: (value) =>
                    setState(() => _lessonFilter = value),
                onSyllabusUnitChanged: (value) =>
                    setState(() => _syllabusUnitFilter = value),
              ),
              if (_error != null) ...[
                const SizedBox(height: AdminSpacing.md),
                AdminSurface(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AdminSpacing.lg,
                    vertical: AdminSpacing.md,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AdminColors.danger,
                      ),
                      const SizedBox(width: AdminSpacing.md),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AdminColors.danger),
                        ),
                      ),
                      TextButton(
                        onPressed: _loadQuestions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: _loadingQuestions
              ? const AdminLoadingSurface(rows: 3)
              : visible.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AdminSpacing.pagePadding,
                    0,
                    AdminSpacing.pagePadding,
                    AdminSpacing.pagePadding,
                  ),
                  child: _buildEmptyState(),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AdminSpacing.pagePadding,
                    AdminSpacing.sm,
                    AdminSpacing.pagePadding,
                    AdminSpacing.pagePadding,
                  ),
                  itemCount: visible.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AdminSpacing.md),
                  itemBuilder: (context, index) {
                    final question = visible[index];
                    return AdminQuestionRow(
                      question: question,
                      onEdit: () => _openEdit(question),
                      onRequestStatus: (status) =>
                          _requestLifecycleStatus(question, status),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    if (_questions.isEmpty) {
      return AdminEmptyState(
        title: 'No questions yet',
        message:
            'Create your first question for this course, or import a bilingual JSON batch.',
        icon: Icons.quiz_outlined,
        action: FilledButton.icon(
          onPressed: _courseId == null ? null : _openCreate,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('+ Create Question'),
        ),
      );
    }
    return AdminEmptyState(
      title: 'No questions found',
      message: _hasActiveFilters
          ? 'Try adjusting your filters or create a new question.'
          : 'No questions match the current view.',
      icon: Icons.filter_alt_outlined,
      action: FilledButton.icon(
        onPressed: _courseId == null ? null : _openCreate,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('+ Create Question'),
      ),
    );
  }
}

class _FilterWorkspace extends StatelessWidget {
  const _FilterWorkspace({
    required this.courses,
    required this.syllabus,
    required this.courseId,
    required this.statusFilter,
    required this.paperFilter,
    required this.majorStudyAreaFilter,
    required this.contentTopicFilter,
    required this.partFilter,
    required this.topicFilter,
    required this.lessonFilter,
    required this.syllabusUnitFilter,
    required this.onCourseChanged,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onPaperChanged,
    required this.onMajorStudyAreaChanged,
    required this.onContentTopicChanged,
    required this.onPartChanged,
    required this.onTopicChanged,
    required this.onLessonChanged,
    required this.onSyllabusUnitChanged,
  });

  final List<Course> courses;
  final SyllabusService syllabus;
  final String? courseId;
  final QuestionPublicationStatus? statusFilter;
  final String? paperFilter;
  final String? majorStudyAreaFilter;
  final String? contentTopicFilter;
  final String? partFilter;
  final String? topicFilter;
  final String? lessonFilter;
  final String? syllabusUnitFilter;
  final ValueChanged<String?> onCourseChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<QuestionPublicationStatus?> onStatusChanged;
  final ValueChanged<String?> onPaperChanged;
  final ValueChanged<String?> onMajorStudyAreaChanged;
  final ValueChanged<String?> onContentTopicChanged;
  final ValueChanged<String?> onPartChanged;
  final ValueChanged<String?> onTopicChanged;
  final ValueChanged<String?> onLessonChanged;
  final ValueChanged<String?> onSyllabusUnitChanged;

  SyllabusCourse? get _course =>
      courseId == null ? null : syllabus.getCourseById(courseId!);

  SyllabusPaper? get _paper {
    if (courseId == null || paperFilter == null) return null;
    return syllabus.getPaper(courseId: courseId!, paperId: paperFilter!);
  }

  bool get _isPaperI => _paper?.hasCanonicalPaperIContent == true;

  bool get _isPapersWithTopics {
    final paper = _paper;
    if (paper == null || !paper.hasCanonicalParts) return false;
    return paper.parts.any((part) => part.topics.isNotEmpty);
  }

  bool get _isSyllabusUnitPaper {
    final paper = _paper;
    if (paper == null) return false;
    return paper.hasDirectSyllabusUnits || paper.hasPartSyllabusUnits;
  }

  @override
  Widget build(BuildContext context) {
    final papers = _course?.papers ?? const <SyllabusPaper>[];
    final paper = _paper;

    return AdminSurface(
      padding: const EdgeInsets.all(AdminSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            key: const ValueKey('question-list-search'),
            decoration: const InputDecoration(
              isDense: true,
              labelText: 'Search',
              hintText: 'Search questions by text, ID, or syllabus…',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: AdminSpacing.sm),
          Wrap(
            spacing: AdminSpacing.sm,
            runSpacing: AdminSpacing.sm,
            children: [
              _dropdown<String>(
                key: const ValueKey('question-list-course'),
                rebuildKey: ValueKey('rebuild-course-$courseId'),
                label: 'Course',
                value: courseId,
                width: 260,
                items: [
                  for (final course in courses)
                    DropdownMenuItem(
                      value: course.courseId,
                      child: Text(
                        course.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: onCourseChanged,
              ),
              _dropdown<QuestionPublicationStatus?>(
                key: const ValueKey('question-list-status'),
                rebuildKey: ValueKey('rebuild-status-$statusFilter'),
                label: 'Status',
                value: statusFilter,
                width: 160,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  for (final status in QuestionPublicationStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status)),
                    ),
                ],
                onChanged: onStatusChanged,
              ),
              _dropdown<String?>(
                key: const ValueKey('question-list-paper'),
                rebuildKey: ValueKey('rebuild-paper-$paperFilter'),
                label: 'Paper',
                value: paperFilter,
                width: 200,
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All papers'),
                  ),
                  for (final item in papers)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(item.title, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: onPaperChanged,
              ),
              if (_isPaperI) ...[
                _dropdown<String?>(
                  key: const ValueKey('question-list-major-study-area'),
                  rebuildKey: ValueKey(
                    'rebuild-msa-$majorStudyAreaFilter',
                  ),
                  label: 'Major Study Area',
                  value: majorStudyAreaFilter,
                  width: 220,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All areas'),
                    ),
                    for (final area in paper!.majorStudyAreas)
                      DropdownMenuItem(
                        value: area.id,
                        child: Text(
                          area.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onMajorStudyAreaChanged,
                ),
                _dropdown<String?>(
                  key: const ValueKey('question-list-content-topic'),
                  rebuildKey: ValueKey(
                    'rebuild-content-topic-$contentTopicFilter',
                  ),
                  label: 'Content Topic',
                  value: contentTopicFilter,
                  width: 220,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All content topics'),
                    ),
                    for (final area in paper.majorStudyAreas)
                      if (majorStudyAreaFilter == null ||
                          area.id == majorStudyAreaFilter)
                        for (final topic in area.contentTopics)
                          DropdownMenuItem(
                            value: topic.id,
                            child: Text(
                              topic.displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ],
                  onChanged: onContentTopicChanged,
                ),
              ],
              if (_isPapersWithTopics) ...[
                _dropdown<String?>(
                  key: const ValueKey('question-list-part'),
                  rebuildKey: ValueKey('rebuild-part-$partFilter'),
                  label: 'Part',
                  value: partFilter,
                  width: 180,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All parts'),
                    ),
                    for (final part in paper!.parts)
                      DropdownMenuItem(
                        value: part.id,
                        child: Text(
                          part.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onPartChanged,
                ),
                _dropdown<String?>(
                  key: const ValueKey('question-list-topic'),
                  rebuildKey: ValueKey('rebuild-topic-$topicFilter'),
                  label: 'Topic',
                  value: topicFilter,
                  width: 220,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All topics'),
                    ),
                    for (final part in paper.parts)
                      if (partFilter == null || part.id == partFilter)
                        for (final topic in part.topics)
                          DropdownMenuItem(
                            value: topic.id,
                            child: Text(
                              topic.resolvedDisplayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ],
                  onChanged: onTopicChanged,
                ),
                _dropdown<String?>(
                  key: const ValueKey('question-list-lesson'),
                  rebuildKey: ValueKey('rebuild-lesson-$lessonFilter'),
                  label: 'Lesson',
                  value: lessonFilter,
                  width: 200,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All lessons'),
                    ),
                    for (final part in paper.parts)
                      if (partFilter == null || part.id == partFilter)
                        for (final topic in part.topics)
                          if (topicFilter == null || topic.id == topicFilter)
                            for (final lesson in topic.lessons)
                              DropdownMenuItem(
                                value: lesson.id,
                                child: Text(
                                  lesson.displayName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                  ],
                  onChanged: onLessonChanged,
                ),
              ],
              if (!_isPaperI &&
                  !_isPapersWithTopics &&
                  _isSyllabusUnitPaper) ...[
                if (paper!.hasPartSyllabusUnits)
                  _dropdown<String?>(
                    key: const ValueKey('question-list-part'),
                    rebuildKey: ValueKey('rebuild-part-$partFilter'),
                    label: 'Part',
                    value: partFilter,
                    width: 180,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All parts'),
                      ),
                      for (final part in paper.parts)
                        DropdownMenuItem(
                          value: part.id,
                          child: Text(
                            part.displayName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: onPartChanged,
                  ),
                _dropdown<String?>(
                  key: const ValueKey('question-list-syllabus-unit'),
                  rebuildKey: ValueKey(
                    'rebuild-unit-$syllabusUnitFilter',
                  ),
                  label: 'Syllabus Unit',
                  value: syllabusUnitFilter,
                  width: 240,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All units'),
                    ),
                    for (final unit in _unitsForPaper(paper))
                      DropdownMenuItem(
                        value: unit.id,
                        child: Text(
                          unit.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: onSyllabusUnitChanged,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<SyllabusUnit> _unitsForPaper(SyllabusPaper paper) {
    if (paper.hasDirectSyllabusUnits) return paper.syllabusUnits;
    final units = <SyllabusUnit>[];
    for (final part in paper.parts) {
      if (partFilter != null && part.id != partFilter) continue;
      units.addAll(part.syllabusUnits);
    }
    return units;
  }

  Widget _dropdown<T>({
    required Key key,
    required Key rebuildKey,
    required String label,
    required T? value,
    required double width,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: KeyedSubtree(
        key: rebuildKey,
        child: DropdownButtonFormField<T>(
          key: key,
          initialValue: value,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  static String _statusLabel(QuestionPublicationStatus status) {
    switch (status) {
      case QuestionPublicationStatus.draft:
        return 'Draft';
      case QuestionPublicationStatus.published:
        return 'Published';
      case QuestionPublicationStatus.archived:
        return 'Archived';
    }
  }
}
