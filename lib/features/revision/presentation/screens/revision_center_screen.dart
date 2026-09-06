import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../navigation/tab_scroll_view.dart';
import '../../data/models/revision_models.dart';
import '../../services/revision_service.dart';
import '../revision_navigation.dart';
import '../widgets/revision_center_hero.dart';
import '../widgets/revision_empty_state.dart';
import '../widgets/revision_hub_card.dart';
import '../widgets/revision_motivation_card.dart';

class RevisionCenterScreen extends StatefulWidget {
  const RevisionCenterScreen({
    super.key,
    this.courseId,
    this.revisionService,
  });

  final String? courseId;

  /// Optional override for tests; production uses [RevisionService.instance].
  final RevisionService? revisionService;

  @override
  State<RevisionCenterScreen> createState() => _RevisionCenterScreenState();
}

class _RevisionCenterScreenState extends State<RevisionCenterScreen> {
  late final RevisionService _service;
  late Future<List<RevisionHubItem>> _future;

  @override
  void initState() {
    super.initState();
    _service = widget.revisionService ?? RevisionService.instance;
    _future = _service.loadHubItems(courseId: widget.courseId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _service.loadHubItems(
        courseId: widget.courseId,
        forceRefresh: true,
      );
    });
  }

  Future<void> _open(RevisionHubItem item) async {
    await RevisionNavigation.openHubDestination(
      context,
      type: item.type,
      courseId: widget.courseId,
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Revision Center'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      extendBodyBehindAppBar: false,
      body: Stack(
        children: [
          const Positioned.fill(child: _RevisionAmbientBackground()),
          FutureBuilder<List<RevisionHubItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const RevisionEmptyState(
                  title: 'Could not load revision data.',
                  subtitle: 'Please try again.',
                  icon: Icons.error_outline_rounded,
                );
              }
              if (!snapshot.hasData) {
                return const Center(child: AppCircularProgress());
              }

              final items = snapshot.data!;

              return SafeArea(
                bottom: false,
                child: AppResponsivePadding(
                  child: TabScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      0,
                      AppSpacing.lg,
                      0,
                      AppSpacing.xxxl,
                    ),
                    children: [
                      const RevisionCenterHero(),
                      const SizedBox(height: AppSpacing.xxxl),
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.lg),
                        RevisionHubCard(
                          key: ValueKey('revision-hub-${items[i].type.name}'),
                          item: items[i],
                          onTap: () => _open(items[i]),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      const RevisionMotivationCard(),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RevisionAmbientBackground extends StatelessWidget {
  const _RevisionAmbientBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.lavender.withValues(alpha: 0.55),
            AppColors.background,
            AppColors.background,
          ],
          stops: const [0.0, 0.28, 1.0],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: _blob(
              size: 180,
              color: AppColors.primaryLight.withValues(alpha: 0.28),
            ),
          ),
          Positioned(
            top: 120,
            left: -60,
            child: _blob(
              size: 160,
              color: AppColors.accent.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
