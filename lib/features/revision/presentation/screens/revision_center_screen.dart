import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../test_engine/presentation/test_engine_navigation.dart';
import '../../data/models/revision_models.dart';
import '../../services/revision_service.dart';
import '../widgets/revision_collection_card.dart';

class RevisionCenterScreen extends StatefulWidget {
  const RevisionCenterScreen({
    super.key,
    this.courseId,
  });

  final String? courseId;

  @override
  State<RevisionCenterScreen> createState() => _RevisionCenterScreenState();
}

class _RevisionCenterScreenState extends State<RevisionCenterScreen> {
  late Future<List<RevisionCollection>> _future;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _future = RevisionService.instance.generateCollections(
      courseId: widget.courseId,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = RevisionService.instance.generateCollections(
        courseId: widget.courseId,
      );
    });
  }

  Future<void> _start(RevisionCollection collection) async {
    if (_starting || collection.isEmpty) return;
    setState(() => _starting = true);

    try {
      final test = await RevisionService.instance.buildRevisionTest(
        collection: collection,
        courseId: widget.courseId ?? 'group-ii',
      );
      if (!mounted) return;
      if (test == null || test.questions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No questions available for revision.')),
        );
        return;
      }
      await TestEngineNavigation.openTest(context, test: test);
      if (mounted) await _refresh();
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Revision Center')),
      body: FutureBuilder<List<RevisionCollection>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final collections = snapshot.data!;
          final total = collections.fold<int>(0, (sum, c) => sum + c.count);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                'Revise smarter',
                style: AppTextStyles.headline(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Collections are generated from your Question Bank and Progress.',
                style: AppTextStyles.bodyMedium(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                showShadow: false,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ready to revise',
                        style: AppTextStyles.bodyMedium(context),
                      ),
                    ),
                    Text(
                      '$total questions',
                      style: AppTextStyles.label(context).copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              if (_starting)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.lg),
                  child: LinearProgressIndicator(),
                ),
              for (final collection in collections) ...[
                RevisionCollectionCard(
                  collection: collection,
                  onStart: () => _start(collection),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        },
      ),
    );
  }
}
