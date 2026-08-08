import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'features/admin/admin_app.dart';
import 'features/authentication/services/auth_service.dart';
import 'firebase_options.dart';

/// Admin Web entry point.
///
/// Build:
///   flutter build web -t lib/main_admin.dart
///
/// Does not start the student Android navigation shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.initialize();
  runApp(const AdminApp());
}
