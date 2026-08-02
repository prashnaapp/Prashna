import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../data/models/practice_models.dart';
import '../../data/practice_dummy_data.dart';
import '../widgets/instruction_card.dart';
import '../widgets/practice_entrance.dart';
import '../widgets/practice_summary_card.dart';
import '../widgets/primary_action_button.dart';
import 'practice_question_screen.dart';

/// Body-only practice session content. Wrap with [Scaffold] at route level.
class PracticeSessionScreen extends StatelessWidget {
  const PracticeSessionScreen({
    super.key,
    required this.session,
    required this.heroTag,
  });

  final PracticeSessionModel session;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return PracticeEntrance(
      child: AppResponsivePadding(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Practice Session',
                      style: AppTextStyles.headline(context),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PracticeSummaryCard(
                      session: session,
                      heroTag: heroTag,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const InstructionCard(
                      instructions: PracticeDummyData.instructions,
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    PrimaryActionButton(
                      label: 'Start Quiz',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PracticeQuestionScreen(
                              session: session,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
