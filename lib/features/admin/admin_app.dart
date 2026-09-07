import 'package:flutter/material.dart';

import 'presentation/admin_auth_gate.dart';
import 'theme/admin_theme.dart';

/// Root widget for the Admin Web application (separate from student app).
class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Prashna Admin',
      theme: AdminTheme.light(),
      home: const AdminAuthGate(),
    );
  }
}
