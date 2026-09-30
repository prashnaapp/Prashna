import 'package:flutter/material.dart';

import '../../admin_routes.dart';

enum AdminNavDestination { dashboard, questions, importQuestions, tests }

extension AdminNavDestinationX on AdminNavDestination {
  String get label => switch (this) {
    AdminNavDestination.dashboard => 'Dashboard',
    AdminNavDestination.questions => 'Questions',
    AdminNavDestination.importQuestions => 'Import Questions',
    AdminNavDestination.tests => 'Tests',
  };

  String get routeName => switch (this) {
    AdminNavDestination.dashboard => AdminRoutes.dashboard,
    AdminNavDestination.questions => AdminRoutes.questions,
    AdminNavDestination.importQuestions => AdminRoutes.questionImport,
    AdminNavDestination.tests => AdminRoutes.tests,
  };

  IconData get iconData => switch (this) {
    AdminNavDestination.dashboard => Icons.dashboard_outlined,
    AdminNavDestination.questions => Icons.quiz_outlined,
    AdminNavDestination.importQuestions => Icons.upload_file_outlined,
    AdminNavDestination.tests => Icons.assignment_outlined,
  };

  static AdminNavDestination? fromRouteName(String? name) {
    switch (name) {
      case AdminRoutes.root:
      case AdminRoutes.login:
      case AdminRoutes.dashboard:
      case '/':
      case null:
        return AdminNavDestination.dashboard;
      case AdminRoutes.questions:
      case AdminRoutes.chapterQuestions:
      case AdminRoutes.testSeriesQuestions:
      case AdminRoutes.questionCreate:
      case AdminRoutes.questionEdit:
        return AdminNavDestination.questions;
      case AdminRoutes.questionImport:
        return AdminNavDestination.importQuestions;
      case AdminRoutes.tests:
      case AdminRoutes.chapters:
      case AdminRoutes.testSeries:
      case AdminRoutes.testCreate:
      case AdminRoutes.testEdit:
      case AdminRoutes.testAssignments:
        return AdminNavDestination.tests;
      default:
        return null;
    }
  }
}
