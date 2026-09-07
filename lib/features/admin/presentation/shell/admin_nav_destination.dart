import 'package:flutter/material.dart';

import '../../admin_routes.dart';

enum AdminNavDestination {
  dashboard,
  questions,
  importQuestions,
  chapters,
  testSeries,
}

extension AdminNavDestinationX on AdminNavDestination {
  String get label => switch (this) {
    AdminNavDestination.dashboard => 'Dashboard',
    AdminNavDestination.questions => 'Questions',
    AdminNavDestination.importQuestions => 'Import Questions',
    AdminNavDestination.chapters => 'Chapters',
    AdminNavDestination.testSeries => 'Test Series',
  };

  String get routeName => switch (this) {
    AdminNavDestination.dashboard => AdminRoutes.dashboard,
    AdminNavDestination.questions => AdminRoutes.questions,
    AdminNavDestination.importQuestions => AdminRoutes.questionImport,
    AdminNavDestination.chapters => AdminRoutes.chapters,
    AdminNavDestination.testSeries => AdminRoutes.testSeries,
  };

  IconData get iconData => switch (this) {
    AdminNavDestination.dashboard => Icons.dashboard_outlined,
    AdminNavDestination.questions => Icons.quiz_outlined,
    AdminNavDestination.importQuestions => Icons.upload_file_outlined,
    AdminNavDestination.chapters => Icons.account_tree_outlined,
    AdminNavDestination.testSeries => Icons.assignment_outlined,
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
      case AdminRoutes.questionCreate:
      case AdminRoutes.questionEdit:
        return AdminNavDestination.questions;
      case AdminRoutes.questionImport:
        return AdminNavDestination.importQuestions;
      case AdminRoutes.chapters:
        return AdminNavDestination.chapters;
      case AdminRoutes.testSeries:
      case AdminRoutes.tests:
      case AdminRoutes.testCreate:
      case AdminRoutes.testEdit:
        return AdminNavDestination.testSeries;
      default:
        return null;
    }
  }
}
