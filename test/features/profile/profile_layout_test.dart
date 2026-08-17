import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/profile/presentation/screens/profile_screen.dart';
import 'package:telangana_prep/features/profile/presentation/widgets/logout_button.dart';
import 'package:telangana_prep/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:telangana_prep/features/profile/presentation/widgets/profile_hero.dart';
import 'package:telangana_prep/features/profile/presentation/widgets/settings_tile.dart';
import 'package:telangana_prep/features/profile/services/profile_service.dart';
import 'package:telangana_prep/navigation/app_nav_metrics.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => ProfileService.skipAuthLookup = true);
  tearDown(() => ProfileService.skipAuthLookup = false);

  testWidgets('Profile shows only the retained sections, without overflow', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(412, 915),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      // Fresh tree per size: otherwise the previous iteration's scroll offset
      // is restored and the position assertions below measure a scrolled sheet.
      await tester.pumpWidget(const SizedBox.shrink());

      FlutterErrorDetails? overflow;
      final old = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.exceptionAsString().contains('overflowed')) {
          overflow ??= details;
        }
      };

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pump();
      while (tester.takeException() != null) {}

      expect(
        overflow,
        isNull,
        reason: '$size ${overflow?.exceptionAsString()}',
      );
      FlutterError.onError = old;

      // Hero + account card.
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Manage your account and preferences.'), findsOneWidget);
      expect(find.byType(ProfileHeaderCard), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // Retained sections, in order.
      for (final label in [
        'Subscription',
        'Free Plan',
        'Manage Subscription',
        'Activity',
        'Test History',
        'Preferences',
        'Theme',
        'Notifications',
        'Support',
        'Contact Us',
        'Share App',
        'Logout',
      ]) {
        expect(find.text(label), findsOneWidget, reason: '$label missing');
      }
      expect(find.text('Inactive'), findsOneWidget);

      // Removed low-value entries.
      for (final label in [
        'Language',
        'Downloads',
        'Help Center',
        'Report a Bug',
        'FAQ',
        'Rate App',
        'Legal',
        'Privacy Policy',
        'Terms & Conditions',
      ]) {
        expect(find.text(label), findsNothing, reason: '$label should be gone');
      }

      // Rows stay compact and equal width.
      final rows = find.byType(SettingsTile);
      expect(rows, findsNWidgets(7));
      final firstRow = tester.getSize(rows.first);
      expect(firstRow.height, lessThan(84));
      for (final element in rows.evaluate()) {
        final rowSize = tester.getSize(find.byWidget(element.widget));
        expect(rowSize.width, closeTo(firstRow.width, 0.5));
      }

      // Content starts below the hero's wave, never on the gradient.
      final heroBottom = tester.getBottomLeft(find.byType(ProfileHero)).dy;
      final cardTop = tester.getTopLeft(find.byType(ProfileHeaderCard)).dy;
      expect(cardTop, greaterThan(heroBottom - 6));

      // Logout must scroll clear of the floating bottom navigation.
      await tester.fling(
        find.byType(SettingsTile).first,
        const Offset(0, -900),
        1500,
      );
      await tester.pumpAndSettle();
      final logoutBottom = tester.getBottomLeft(find.byType(LogoutButton)).dy;
      expect(logoutBottom, lessThan(size.height - AppNavMetrics.barHeight));
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}
