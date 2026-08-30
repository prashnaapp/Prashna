import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:telangana_prep/core/theme/app_theme.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/course_enrollment/model/course_context.dart';
import 'package:telangana_prep/features/course_enrollment/service/course_loader_service.dart';
import 'package:telangana_prep/features/home/presentation/home_visual.dart';
import 'package:telangana_prep/features/home/presentation/screens/home_screen.dart';
import 'package:telangana_prep/features/home/presentation/widgets/continue_learning_card.dart';
import 'package:telangana_prep/features/home/presentation/widgets/home_courses_section.dart';
import 'package:telangana_prep/features/home/presentation/widgets/home_hero.dart';
import 'package:telangana_prep/features/home/presentation/widgets/home_quick_access_section.dart';
import 'package:telangana_prep/features/home/presentation/widgets/today_goal_card.dart';
import 'package:telangana_prep/features/syllabus/presentation/screens/syllabus_home_screen.dart';
import 'package:telangana_prep/navigation/app_nav_item.dart';
import 'package:telangana_prep/navigation/custom_bottom_navigation.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    CourseLoaderService.instance.debugSetCurrent(
      CourseContext(
        publishedCourses: [
          _course(id: 'group-ii', title: 'Group-II', shortTitle: 'G-II'),
          _course(id: 'group-iii', title: 'Group-III', shortTitle: 'G-III'),
        ],
        enrollments: const [],
      ),
    );
  });

  tearDown(() {
    CourseLoaderService.instance.debugSetCurrent(null);
  });

  testWidgets('Home renders compact sections with existing dynamic data', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 740),
      const Size(390, 844),
      const Size(430, 932),
    ]) {
      await _pumpHome(tester, size);

      expect(find.text('Prashna'), findsWidgets);
      expect(find.text('Your Preparation'), findsOneWidget);
      expect(find.text('Questions Today'), findsOneWidget);
      expect(find.text('Daily Target'), findsOneWidget);
      expect(find.text('Remaining'), findsOneWidget);
      expect(find.text('12'), findsWidgets);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('18'), findsOneWidget);
      expect(find.text('40%'), findsOneWidget);
      expect(find.text("Today's Goal"), findsOneWidget);

      expect(find.text('Continue Learning'), findsOneWidget);
      expect(find.text('GROUP-II'), findsOneWidget);
      expect(find.text('PAPER-II'), findsOneWidget);
      expect(find.text('PART-I'), findsOneWidget);
      expect(find.text('Chapter 5'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Continue Now →'), findsOneWidget);

      expect(find.text('Quick Access'), findsOneWidget);
      expect(find.text('Chapter Wise'), findsOneWidget);
      expect(find.text('Test Series'), findsOneWidget);
      expect(find.text('Current Affairs'), findsOneWidget);
      expect(find.text('Previous Papers'), findsOneWidget);

      expect(find.text('My Courses'), findsOneWidget);
      expect(find.text('Group-II'), findsOneWidget);
      expect(find.text('Group-III'), findsOneWidget);
      expect(find.text('G-II'), findsOneWidget);
      expect(find.text('G-III'), findsOneWidget);

      expect(find.byType(TodayGoalCard), findsOneWidget);
      expect(find.byType(ContinueLearningCard), findsOneWidget);
      expect(find.byType(HomeQuickAccessSection), findsOneWidget);
      expect(find.byType(HomeCoursesSection), findsOneWidget);

      expect(
        tester.widgetList<ColoredBox>(find.byType(ColoredBox)).any(
          (box) => box.color == HomeVisual.page,
        ),
        isTrue,
      );

      final prepMaterials = tester
          .widgetList<Material>(
            find.descendant(
              of: find.byType(TodayGoalCard),
              matching: find.byType(Material),
            ),
          )
          .toList();
      expect(prepMaterials, isNotEmpty);
      expect(
        prepMaterials.first.clipBehavior,
        Clip.antiAlias,
      );
      expect(prepMaterials.first.color, HomeVisual.surface);

      final heroSize = tester.getSize(find.byType(HomeHeroBackdrop));
      expect(heroSize.height, lessThan(180), reason: '$size hero too tall');

      final prepSize = tester.getSize(find.byType(TodayGoalCard));
      expect(prepSize.height, lessThan(220), reason: '$size prep too tall');

      final progressBottom = tester.getBottomLeft(find.text('42%')).dy;
      final ctaTop = tester.getTopLeft(find.text('Continue Now →')).dy;
      expect(
        ctaTop - progressBottom,
        lessThan(20),
        reason: '$size progress-to-button gap too large: ${ctaTop - progressBottom}',
      );

      expect(
        tester.getTopLeft(find.text('Continue Learning')).dy,
        greaterThan(tester.getTopLeft(find.text('Your Preparation')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Quick Access')).dy,
        greaterThan(tester.getTopLeft(find.text('Continue Learning')).dy),
      );
      expect(
        tester.getTopLeft(find.text('My Courses')).dy,
        greaterThan(tester.getTopLeft(find.text('Quick Access')).dy),
      );

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
      await tester.pump();
      await tester.scrollUntilVisible(find.text('G-III'), 80);
      expect(find.text('G-III'), findsOneWidget);
      expect(find.text('My Courses'), findsOneWidget);
    }
  });

  testWidgets('My Courses clears the bottom navigation when scrolled', (
    tester,
  ) async {
    const size = Size(390, 844);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Stack(
          children: [
            const HomeScreen(),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CustomBottomNavigation(
                currentIndex: 0,
                onDestinationSelected: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.scrollUntilVisible(find.text('G-III'), 80);
    await tester.pump();

    final coursesBottom =
        tester.getRect(find.byType(HomeCoursesSection)).bottom;
    final navTop = tester.getRect(find.byType(CustomBottomNavigation)).top;
    expect(
      coursesBottom,
      lessThanOrEqualTo(navTop),
      reason: 'My Courses must scroll fully above the bottom navigation',
    );
  });

  testWidgets('Quick Access Chapter Wise still opens syllabus', (tester) async {
    await _pumpHome(tester, const Size(390, 844));

    await tester.tap(find.text('Chapter Wise'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SyllabusHomeScreen), findsOneWidget);
  });

  testWidgets('Bottom navigation tabs are unchanged', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: CustomBottomNavigation(
            currentIndex: AppTab.home.index,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(CustomBottomNavigation), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Test Series'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}

Course _course({
  required String id,
  required String title,
  required String shortTitle,
}) {
  return Course(
    courseId: id,
    title: title,
    shortTitle: shortTitle,
    description: '',
    thumbnail: null,
    icon: 'school',
    color: null,
    isFree: true,
    isPublished: true,
    price: 0,
    sortOrder: 0,
    createdAt: null,
    updatedAt: null,
  );
}

Future<void> _pumpHome(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  FlutterErrorDetails? overflow;
  final old = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) {
      overflow ??= details;
    }
    old?.call(details);
  };
  addTearDown(() => FlutterError.onError = old);

  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      home: const HomeScreen(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 900));

  expect(overflow, isNull, reason: '$size ${overflow?.exceptionAsString()}');
}
