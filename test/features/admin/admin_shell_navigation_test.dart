import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/admin_auth_gate.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_dirty_scope.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_shell.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';

void main() {
  const user = AuthUser(
    uid: 'uid-1',
    email: 'admin@example.com',
    displayName: 'Admin User',
  );

  testWidgets('shell exposes major destinations after admin auth', (
    tester,
  ) async {
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
    await tester.pumpAndSettle();

    expect(find.byType(AdminShell), findsOneWidget);
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Questions'), findsWidgets);
    expect(find.text('Import Questions'), findsWidgets);
    expect(find.text('Chapters'), findsWidgets);
    expect(find.text('Test Series'), findsWidgets);
  });

  testWidgets('dirty leave dialog stay vs discard', (tester) async {
    final dirty = AdminDirtyController();
    dirty.bind(() => true);
    bool? first;
    bool? second;

    await tester.pumpWidget(
      MaterialApp(
        home: AdminDirtyScope(
          controller: dirty,
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    FilledButton(
                      onPressed: () async {
                        first = await dirty.confirmLeaveIfNeeded(context);
                      },
                      child: const Text('Leave A'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        second = await dirty.confirmLeaveIfNeeded(context);
                      },
                      child: const Text('Leave B'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Leave A'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(first, isFalse);

    await tester.tap(find.text('Leave B'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Discard & Leave'));
    await tester.pumpAndSettle();
    expect(second, isTrue);
  });
}
