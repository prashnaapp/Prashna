import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.prompt,
  });

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Text(
        prompt,
        style: AppTextStyles.bodyLarge(context),
      ),
    );
  }
}
