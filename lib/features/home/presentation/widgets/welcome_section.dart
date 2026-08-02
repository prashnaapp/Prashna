import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';
import '../../services/home_greeting_helper.dart';
import '../../services/home_service.dart';

class WelcomeSection extends StatelessWidget {
  const WelcomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final name = HomeService.instance.getStudentName();
    final greeting = homeTimeGreeting();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$greeting, $name',
          style: AppTextStyles.headline(context),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ready to continue your preparation?',
          style: AppTextStyles.bodyMedium(context),
        ),
      ],
    );
  }
}
