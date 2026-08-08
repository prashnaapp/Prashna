import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/admin_auth_gate.dart';
import 'package:telangana_prep/features/admin/presentation/admin_auth_phase.dart';
import 'package:telangana_prep/features/admin/presentation/admin_auth_phase_resolver.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_access_denied_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_login_screen.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';

void main() {
  const user = AuthUser(
    uid: 'uid-1',
    email: 'admin@example.com',
    displayName: 'Admin User',
  );

  group('AdminAuthPhaseResolver', () {
    test('1: no user → login', () async {
      final phase = await AdminAuthPhaseResolver.resolve(
        user: null,
        isAdmin: ({bool forceRefresh = false}) async => true,
      );
      expect(phase, AdminAuthPhase.login);
    });

    test('2: user without admin claim → access denied', () async {
      final phase = await AdminAuthPhaseResolver.resolve(
        user: user,
        isAdmin: ({bool forceRefresh = false}) async => false,
      );
      expect(phase, AdminAuthPhase.accessDenied);
    });

    test('3: user with admin:true → dashboard', () async {
      final phase = await AdminAuthPhaseResolver.resolve(
        user: user,
        isAdmin: ({bool forceRefresh = false}) async => true,
      );
      expect(phase, AdminAuthPhase.dashboard);
    });
  });

  group('AdminAuthGate widget', () {
    testWidgets('1: no user → login', (tester) async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminAuthGate(
            authStateChanges: controller.stream,
            isAdminChecker: ({bool forceRefresh = false}) async => false,
          ),
        ),
      );

      // Initial loading before first auth event.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add(null);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AdminLoginScreen), findsOneWidget);
      expect(find.text('Prashna Admin'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('2: user without admin claim → access denied', (tester) async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminAuthGate(
            authStateChanges: controller.stream,
            isAdminChecker: ({bool forceRefresh = false}) async => false,
          ),
        ),
      );

      controller.add(user);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
      expect(find.text('Access denied'), findsOneWidget);
    });

    testWidgets('3: user with admin:true → dashboard', (tester) async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);

      await tester.pumpWidget(
        MaterialApp(
          home: AdminAuthGate(
            authStateChanges: controller.stream,
            isAdminChecker: ({bool forceRefresh = false}) async => true,
          ),
        ),
      );

      controller.add(user);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
      expect(find.text('PRASHNA ADMIN'), findsOneWidget);
      expect(find.textContaining('Welcome'), findsOneWidget);
    });

    testWidgets('4: loading state handled', (tester) async {
      final controller = StreamController<AuthUser?>();
      addTearDown(controller.close);

      final adminCompleter = Completer<bool>();

      await tester.pumpWidget(
        MaterialApp(
          home: AdminAuthGate(
            authStateChanges: controller.stream,
            isAdminChecker: ({bool forceRefresh = false}) =>
                adminCompleter.future,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add(user);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      adminCompleter.complete(true);
      await tester.pump();
      await tester.pump();

      expect(find.byType(AdminDashboardScreen), findsOneWidget);
    });
  });
}
