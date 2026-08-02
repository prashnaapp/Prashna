import 'package:flutter/material.dart';

import '../../features/progress/presentation/screens/tracker_home_screen.dart';

/// Progress tab entry — screen owns its Scaffold (Home-parity).
class StudyTrackerScreen extends StatelessWidget {
  const StudyTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TrackerHomeScreen();
  }
}
