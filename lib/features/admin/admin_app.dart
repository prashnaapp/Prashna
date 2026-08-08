import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'admin_routes.dart';
import 'presentation/admin_auth_gate.dart';

/// Root widget for the Admin Web application (separate from student app).
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prashna Admin',
      theme: AppTheme.light(),
      initialRoute: AdminRoutes.root,
      onGenerateRoute: (settings) {
        // All admin routes go through the claim gate — never expose CRUD
        // (or dashboard content) without verifying admin:true.
        switch (settings.name) {
          case AdminRoutes.root:
          case AdminRoutes.login:
          case AdminRoutes.dashboard:
          case '/':
          case null:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AdminAuthGate(),
            );
          default:
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => const AdminAuthGate(),
            );
        }
      },
    );
  }
}
