import 'package:flutter/material.dart';

import '../../../course_enrollment/model/course.dart';
import '../../../tests/data/models/test_models.dart';
import '../../admin_routes.dart';
import '../../services/admin_test_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_page_header.dart';
import '../widgets/admin_ui/admin_surface.dart';
import '../widgets/admin_ui/admin_test_row.dart';

class AdminTestListScreen extends StatefulWidget {
  const AdminTestListScreen({super.key, this.service});

  final AdminTestService? service;

  @override
  State<AdminTestListScreen> createState() => _AdminTestListScreenState();
}

class _AdminTestListScreenState extends State<AdminTestListScreen> {
  late final AdminTestService _service;
  List<Course> _courses = const [];
  List<TestModel> _tests = const [];
  String? _courseId;
  String? _error;
  bool _loadingCourses = true;
  bool _loadingTests = false;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminTestService.instance;
    _loadCourses();
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
      if (_courseId != null) await _loadTests();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingCourses = false;
        _error = 'Unable to load courses: $error';
      });
    }
  }

  Future<void> _loadTests() async {
    final courseId = _courseId;
    if (courseId == null || courseId.isEmpty) return;
    setState(() {
      _loadingTests = true;
      _error = null;
    });
    try {
      final tests = await _service.loadTests(courseId);
      if (!mounted) return;
      setState(() {
        _tests = tests;
        _loadingTests = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingTests = false;
        _error = 'Unable to load tests: $error';
      });
    }
  }

  Future<void> _openCreate() async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testCreate, arguments: _courseId);
    if (mounted) await _loadTests();
  }

  Future<void> _openEdit(TestModel test) async {
    await Navigator.of(
      context,
    ).pushNamed(AdminRoutes.testEdit, arguments: test);
    if (mounted) await _loadTests();
  }

  Future<void> _setStatus(TestModel test, TestPublicationStatus status) async {
    if (status == TestPublicationStatus.published) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Publish test?'),
          content: const Text(
            'Students with course access will be able to see this test '
            'in the Test Series catalog.',
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
      await _service.setStatus(test.id, status);
      if (mounted) await _loadTests();
    } catch (error) {
      if (!mounted) return;
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
    return Scaffold(
      backgroundColor: AdminColors.backgroundTop,
      appBar: AppBar(title: const Text('Tests')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            height: double.infinity,
            child: _buildBody(context),
          ),
        ),
      ),
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
        message: 'No published courses are available.',
        icon: Icons.school_outlined,
      );
    }
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
                title: 'Managed Tests',
                subtitle:
                    'Flat catalog view across a course. Prefer Test Series or '
                    'Chapters browsers for scoped workflows.',
                actions: [
                  FilledButton.icon(
                    onPressed: _courseId == null ? null : _openCreate,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Create Test'),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 200, maxWidth: 600),
                child: DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  decoration: const InputDecoration(
                    labelText: 'Course',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final course in _courses)
                      DropdownMenuItem(
                        value: course.courseId,
                        child: Text('${course.title} (${course.courseId})'),
                      ),
                  ],
                  onChanged: (value) async {
                    setState(() => _courseId = value);
                    await _loadTests();
                  },
                ),
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
                        onPressed: _loadTests,
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
          child: _loadingTests
              ? const AdminLoadingSurface()
              : _tests.isEmpty
              ? const AdminEmptyState(
                  title: 'No tests for this course',
                  message:
                      'Create a test or open Test Series / Chapters for scoped '
                      'management.',
                  icon: Icons.assignment_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AdminSpacing.pagePadding,
                    AdminSpacing.sm,
                    AdminSpacing.pagePadding,
                    AdminSpacing.pagePadding,
                  ),
                  itemCount: _tests.length,
                  separatorBuilder: (_, index) =>
                      const SizedBox(height: AdminSpacing.md),
                  itemBuilder: (context, index) {
                    final test = _tests[index];
                    return AdminTestRow(
                      test: test,
                      onEdit: () => _openEdit(test),
                      onPublish: test.status != TestPublicationStatus.published
                          ? () => _setStatus(
                              test,
                              TestPublicationStatus.published,
                            )
                          : null,
                      onUnpublish:
                          test.status == TestPublicationStatus.published
                          ? () =>
                                _setStatus(test, TestPublicationStatus.draft)
                          : null,
                      onArchive: test.status != TestPublicationStatus.archived
                          ? () => _setStatus(
                              test,
                              TestPublicationStatus.archived,
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
