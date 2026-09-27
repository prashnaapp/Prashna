import 'package:flutter/material.dart';

import '../../../question_bank/data/models/question_models.dart';
import '../../data/admin_question_scope.dart';
import '../../services/admin_question_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_spacing.dart';
import '../widgets/admin_ui/admin_empty_state.dart';
import '../widgets/admin_ui/admin_loading_surface.dart';
import '../widgets/admin_ui/admin_question_row.dart';
import '../widgets/admin_ui/admin_status_badge.dart';
import '../widgets/admin_ui/admin_surface.dart';

/// Read-only Test Series Question Bank for one [AdminQuestionScope].
///
/// Does not expose create, import, edit, or assignment actions.
class AdminTestSeriesQuestionBankScreen extends StatefulWidget {
  const AdminTestSeriesQuestionBankScreen({
    super.key,
    required this.scope,
    this.service,
  });

  final AdminQuestionScope scope;
  final AdminQuestionService? service;

  @override
  State<AdminTestSeriesQuestionBankScreen> createState() =>
      _AdminTestSeriesQuestionBankScreenState();
}

class _AdminTestSeriesQuestionBankScreenState
    extends State<AdminTestSeriesQuestionBankScreen> {
  late final AdminQuestionService _service;
  List<Question> _questions = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? AdminQuestionService.instance;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await _service.loadTestSeriesQuestions(widget.scope);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load questions: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const AdminLoadingSurface();
    if (_error != null) {
      return AdminEmptyState(
        title: 'Unable to load questions',
        message: _error!,
        icon: Icons.error_outline,
        action: FilledButton.tonal(
          onPressed: _load,
          child: const Text('Retry'),
        ),
      );
    }
    if (_questions.isEmpty) {
      return const AdminEmptyState(
        key: ValueKey('test-series-question-bank-empty'),
        title: 'No questions yet',
        message: 'No questions in this bank yet.',
        icon: Icons.quiz_outlined,
      );
    }

    return ListView.separated(
      key: const ValueKey('test-series-question-bank-list'),
      padding: const EdgeInsets.all(AdminSpacing.pagePadding),
      itemCount: _questions.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AdminSpacing.md),
      itemBuilder: (context, index) {
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
}
