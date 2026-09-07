import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/admin/admin_routes.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:telangana_prep/features/admin/presentation/screens/admin_question_list_screen.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_dirty_scope.dart';
import 'package:telangana_prep/features/admin/presentation/shell/admin_shell.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_hover_lift.dart';
import 'package:telangana_prep/features/admin/presentation/widgets/admin_ui/admin_surface.dart';
import 'package:telangana_prep/features/admin/services/admin_question_service.dart';
import 'package:telangana_prep/features/authentication/models/auth_user.dart';
import 'package:telangana_prep/features/course_enrollment/model/course.dart';
import 'package:telangana_prep/features/question_bank/data/models/question_models.dart';

const _user = AuthUser(
  uid: 'admin-1',
  email: 'admin@example.com',
  displayName: 'Admin',
);

const _course = Course(
  courseId: 'group-ii',
  title: 'Group-II',
  shortTitle: 'G-II',
  description: '',
  thumbnail: null,
  icon: null,
  color: null,
  isFree: false,
  isPublished: true,
  price: 0,
  sortOrder: 1,
  createdAt: null,
  updatedAt: null,
);

void main() {
  testWidgets('Dashboard destination cards and atmosphere are present', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminDashboardScreen(
          user: _user,
          onSignOut: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-atmosphere')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-workspace-background')),
      findsOneWidget,
    );
    expect(adminWorkspaceTransitionDuration, Duration.zero);
    expect(find.byKey(const ValueKey('dashboard-dest-questions')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-dest-import')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboard-dest-chapters')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('dashboard-dest-test-series')),
      findsOneWidget,
    );
    expect(find.byType(AdminHoverLift), findsNWidgets(4));
    expect(find.text('Questions'), findsOneWidget);
    expect(find.text('Import Questions'), findsOneWidget);
    expect(find.text('Chapters'), findsOneWidget);
    expect(find.text('Test Series'), findsOneWidget);
    expect(find.textContaining('Welcome,'), findsOneWidget);
    expect(find.text('Content Management'), findsOneWidget);
    expect(find.text('Quick Stats'), findsNothing);
    expect(find.text('Recent Activity'), findsNothing);
    expect(find.text('Search anything...'), findsNothing);
  });

  testWidgets('Dashboard destination navigation wiring is preserved', (
    tester,
  ) async {
    final observer = _RouteNameObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: AdminDirtyScope(
          controller: AdminDirtyController(),
          child: AdminDashboardScreen(
            user: _user,
            onSignOut: () async {},
            embeddedInShell: true,
          ),
        ),
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => Scaffold(body: Text('route:${settings.name}')),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dashboard-dest-import')));
    await tester.pumpAndSettle();

    expect(find.text('route:${AdminRoutes.questionImport}'), findsOneWidget);
    expect(observer.replacedTo, AdminRoutes.questionImport);
  });

  testWidgets('Question Bank does not inherit Dashboard atmosphere', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('dashboard-atmosphere')), findsNothing);
    expect(
      find.byKey(const ValueKey('dashboard-workspace-background')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('dashboard-dest-questions')), findsNothing);
    expect(find.text('Create Question'), findsWidgets);
    expect(find.text('+ Create Question'), findsNothing);
  });

  testWidgets('Create Question label has no leading plus duplicate', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AdminQuestionListScreen(
          service: _FakeQuestionService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create Question'), findsWidgets);
    expect(find.text('+ Create Question'), findsNothing);
  });

  testWidgets('AdminSurface glass variant is constructible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminSurface(
            variant: AdminSurfaceVariant.glass,
            accentColor: Color(0xFF2F5BEA),
            child: Text('glass'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('glass'), findsOneWidget);
  });
}

class _RouteNameObserver extends NavigatorObserver {
  String? replacedTo;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    replacedTo = route.settings.name;
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedTo = newRoute?.settings.name;
  }
}

class _FakeQuestionService extends AdminQuestionService {
  _FakeQuestionService() : super();

  @override
  Future<List<Course>> loadCourses() async => const [_course];

  @override
  Future<List<Question>> loadQuestions(String courseId) async => const [];
}
