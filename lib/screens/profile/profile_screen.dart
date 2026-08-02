import 'package:flutter/material.dart';

import '../../features/profile/presentation/screens/profile_screen.dart'
    as profile_ui;

/// Tab shell entry — feature [ProfileScreen] owns Scaffold.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const profile_ui.ProfileScreen();
  }
}
