import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_shell.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';

void main() {
  const user = AuthUser(
    uid: 'admin-1',
    email: 'admin@example.com',
    displayName: 'Admin User',
  );

  testWidgets('desktop sidebar exposes utility zone and Sign out control', (
    tester,
  ) async {
    final view = tester.view;
    view.physicalSize = const Size(1400, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AdminShell(
          user: user,
          onSignOut: () async => signedOut = true,
          embeddedChild: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('admin-sidebar-utility')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-sidebar-nav')), findsOneWidget);
    expect(find.byKey(const ValueKey('admin-sidebar-sign-out')), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Admin User'), findsOneWidget);
    expect(find.text('admin@example.com'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('admin-sidebar-sign-out')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('admin-sign-out-clean-dialog')),
      findsOneWidget,
    );
    expect(signedOut, isFalse);

    await tester.tap(find.byKey(const ValueKey('sign-out-cancel')));
    await tester.pumpAndSettle();
    expect(signedOut, isFalse);
    expect(
      find.byKey(const ValueKey('admin-sign-out-clean-dialog')),
      findsNothing,
    );
  });
}
