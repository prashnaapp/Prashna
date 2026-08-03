import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/authentication/services/auth_service.dart';
import 'firebase_options.dart';
import 'screens/splash/splash_screen.dart';
import 'services/auth/auth_service.dart' as legacy_auth;
import 'services/auth/fake_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AuthService.instance.initialize();
  // Keep legacy OTP stubs available for unused phone auth screens.
  legacy_auth.AuthServiceRegistry.instance = const FakeAuthService();
  runApp(const PrashnaApp());
}

class PrashnaApp extends StatelessWidget {
  const PrashnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prashna',
      theme: AppTheme.light(),
      home: const SplashScreen(),
    );
  }
}
