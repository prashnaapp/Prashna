import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../features/tests/presentation/screens/tests_home_screen.dart';

class TestsScreen extends StatelessWidget {
  const TestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Test Series'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_rounded),
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: AppResponsivePadding(
          child: const TestsHomeScreen(),
        ),
      ),
    );
  }
}
