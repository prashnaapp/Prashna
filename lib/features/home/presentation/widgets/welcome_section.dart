import 'package:flutter/material.dart';

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
          '$greeting, $name 👋',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Let's achieve your dream job!",
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.86),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
