import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/features/progress/data/models/attempt_analytics_models.dart';
import 'package:telangana_prep/features/progress/presentation/screens/tracker_home_screen.dart';
import 'package:telangana_prep/navigation/app_nav_item.dart';
import 'package:telangana_prep/screens/tracker/study_tracker_screen.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('AppNavItems source of truth', () {
    test('AppTab declaration order matches AppNavItems.all', () {
      expect(AppNavItems.all.map((item) => item.tab).toList(), [
        AppTab.home,
        AppTab.chapters,
        AppTab.testSeries,
        AppTab.progress,
        AppTab.profile,
      ]);

      for (var i = 0; i < AppNavItems.all.length; i++) {
        final tab = AppNavItems.all[i].tab;
        expect(AppNavItems.indexOf(tab), i);
        expect(tab.index, i);
      }
    });

    test('Progress bottom-nav index is 3, not AppTab enum drift', () {
      expect(AppNavItems.indexOf(AppTab.progress), 3);
      expect(AppTab.progress.index, 3);
      expect(AppNavItems.indexOf(AppTab.testSeries), 2);
    });
  });

  group('Progress tab isActive wiring', () {
    testWidgets(
      'StudyTrackerScreen isActive is true only on Progress index',
      (tester) async {
        final progressIndex = AppNavItems.indexOf(AppTab.progress);
        var currentIndex = AppNavItems.indexOf(AppTab.home);

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: StudyTrackerScreen(
                    isActive: currentIndex == progressIndex,
                  ),
                  bottomNavigationBar: NavigationBar(
                    selectedIndex: currentIndex,
                    onDestinationSelected: (index) {
                      setState(() => currentIndex = index);
                    },
                    destinations: [
                      for (final item in AppNavItems.all)
                        NavigationDestination(
                          icon: Icon(item.icon),
                          label: item.label,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        await tester.pump();

        Future<void> selectTab(String label) async {
          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(label),
            ),
          );
          await tester.pump();
        }

        expect(
          tester.widget<StudyTrackerScreen>(find.byType(StudyTrackerScreen))
              .isActive,
          isFalse,
        );

        await selectTab('Test Series');
        expect(
          tester.widget<StudyTrackerScreen>(find.byType(StudyTrackerScreen))
              .isActive,
          isFalse,
          reason: 'Test Series must not mark Progress active',
        );

        await selectTab('Progress');
        expect(
          tester.widget<StudyTrackerScreen>(find.byType(StudyTrackerScreen))
              .isActive,
          isTrue,
        );

        await selectTab('Home');
        expect(
          tester.widget<StudyTrackerScreen>(find.byType(StudyTrackerScreen))
              .isActive,
          isFalse,
        );
      },
    );
  });

  group('TrackerHomeScreen activation refresh', () {
    testWidgets(
      'loads once on init; refreshes on inactive→active; not on leave',
      (tester) async {
        var loads = 0;
        var isActive = true;
        late StateSetter setHostState;

        Future<ProgressSummary> loadSummary() async {
          loads++;
          return ProgressSummary.empty;
        }

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return TrackerHomeScreen(
                  key: const ValueKey('progress-home'),
                  isActive: isActive,
                  debugLoadSummary: loadSummary,
                );
              },
            ),
          ),
        );
        await tester.pump();
        expect(loads, 1, reason: 'initState loads summary once');

        // Leave Progress (same State → didUpdateWidget, no refresh).
        isActive = false;
        setHostState(() {});
        await tester.pump();
        expect(loads, 1, reason: 'leaving Progress must not refresh');

        // Re-enter Progress → inactive→active refresh.
        isActive = true;
        setHostState(() {});
        await tester.pump();
        expect(loads, 2, reason: 're-entering Progress must refresh');

        // Stay active through a rebuild → no extra refresh.
        setHostState(() {});
        await tester.pump();
        expect(loads, 2, reason: 'staying active must not re-trigger');
      },
    );
  });
}
