import 'package:flutter/material.dart';

import '../../test_engine/presentation/screens/test_attempt_history_screen.dart';
import '../../test_engine/repository/test_attempt_cloud_repository.dart';

/// Lightweight placeholders for Profile actions used outside the Profile tab.
/// Full screens live on the Account tab; deep links can be wired later.

void openSubscription(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Manage Subscription — coming soon')),
  );
}

void openSettings(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Settings — open the Account tab')),
  );
}

void openAbout(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('About Prashna — coming soon')));
}

void openHelpSupport(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Help & Support — coming soon')));
}

void openEditProfile(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Edit Profile — coming soon')));
}

void openTestHistory(
  BuildContext context, {
  TestAttemptCloudRepository? repository,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => TestAttemptHistoryScreen(repository: repository),
    ),
  );
}
