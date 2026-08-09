import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../question_bank/data/models/question_models.dart';
import '../tests/data/models/test_models.dart';
import 'presentation/screens/admin_question_form_screen.dart';
import 'presentation/screens/admin_question_list_screen.dart';
import 'presentation/screens/admin_test_form_screen.dart';
import 'presentation/screens/admin_test_list_screen.dart';
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
            return _gate(const AdminAuthGate(), settings: settings);
          case AdminRoutes.questions:
            return _gate(const AdminQuestionListScreen(), settings: settings);
          case AdminRoutes.questionCreate:
            return _gate(const AdminQuestionFormScreen(), settings: settings);
          case AdminRoutes.questionEdit:
            final question = settings.arguments;
            if (question is! Question) {
              return _gate(const AdminQuestionListScreen(), settings: settings);
            }
            return _gate(
              AdminQuestionFormScreen(question: question),
              settings: settings,
            );
          case AdminRoutes.tests:
            return _gate(const AdminTestListScreen(), settings: settings);
          case AdminRoutes.testCreate:
            return _gate(
              AdminTestFormScreen(
                initialCourseId: settings.arguments as String?,
              ),
              settings: settings,
            );
          case AdminRoutes.testEdit:
            final test = settings.arguments;
            if (test is! TestModel) {
              return _gate(const AdminTestListScreen(), settings: settings);
            }
            return _gate(AdminTestFormScreen(test: test), settings: settings);
          case '/':
          case null:
            return _gate(const AdminAuthGate(), settings: settings);
          default:
            return _gate(const AdminAuthGate(), settings: settings);
        }
      },
    );
  }

  MaterialPageRoute<void> _gate(Widget child, {RouteSettings? settings}) {
    final gatedChild = child is AdminAuthGate ? null : child;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => AdminAuthGate(authenticatedChild: gatedChild),
    );
  }
}
