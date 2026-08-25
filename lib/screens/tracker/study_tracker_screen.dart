import 'package:flutter/material.dart';

import '../../features/progress/presentation/screens/tracker_home_screen.dart';

/// Progress tab entry — screen owns its Scaffold (Home-parity).
class StudyTrackerScreen extends StatelessWidget {
  const StudyTrackerScreen({super.key, this.isActive = true});

  /// Forwarded so Attempt Analytics refreshes when the Progress tab is selected.
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return TrackerHomeScreen(isActive: isActive);
  }
}
