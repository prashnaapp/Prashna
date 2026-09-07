import 'package:flutter/material.dart';

/// Admin-only color tokens. Do not import Student [AppColors] for Admin chrome.
abstract final class AdminColors {
  static const Color primary = Color(0xFF2F5BEA);
  static const Color primaryDark = Color(0xFF1E3FA8);
  static const Color primarySoft = Color(0xFFE8EEFF);

  static const Color accent = Color(0xFF0F9F8A);
  static const Color accentSoft = Color(0xFFE6F7F4);

  static const Color backgroundTop = Color(0xFFF4F7FC);
  static const Color backgroundBottom = Color(0xFFEAEFF8);
  static const Color surface = Color(0xFFFFFFF8);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F5FA);

  static const Color sidebar = Color(0xFF121A2F);
  static const Color sidebarHover = Color(0xFF1C2740);
  static const Color sidebarActive = Color(0xFF243356);
  static const Color sidebarText = Color(0xFFE8ECF7);
  static const Color sidebarTextMuted = Color(0xFFB4BFD6);
  static const Color sidebarBorder = Color(0xFF2A3650);
  static const Color sidebarUtility = Color(0xFF182238);
  static const Color sidebarAccent = Color(0xFF5B7CFF);

  static const Color border = Color(0xFFCDD6E8);
  static const Color borderStrong = Color(0xFFB8C4DB);

  /// Main readable text — titles, body, important copy.
  static const Color textPrimary = Color(0xFF152038);

  /// Supporting descriptions and subtitles (refined for AA readability).
  static const Color textSecondary = Color(0xFF4A5A75);

  /// Metadata only — not body copy or instructions.
  static const Color textTertiary = Color(0xFF66758F);

  static const Color success = Color(0xFF1F9D6A);
  static const Color successSoft = Color(0xFFE7F7F0);
  static const Color warning = Color(0xFFD8901C);
  static const Color warningSoft = Color(0xFFFFF6E8);
  static const Color danger = Color(0xFFD14343);
  static const Color dangerSoft = Color(0xFFFDECEC);

  static const Color draft = Color(0xFF6B7280);
  static const Color published = Color(0xFF1F9D6A);
  static const Color archived = Color(0xFF9A6B2F);

  // --- Destination accent families (Dashboard identity; controlled) ---

  static const Color questionsSoft = Color(0xFFE8EEFF);
  static const Color questionsStrong = Color(0xFF2F5BEA);

  static const Color importSoft = Color(0xFFE6F7F4);
  static const Color importStrong = Color(0xFF0F9F8A);

  static const Color chaptersSoft = Color(0xFFEEE8FF);
  static const Color chaptersStrong = Color(0xFF6B5CE7);

  static const Color testsSoft = Color(0xFFFFF3E4);
  static const Color testsStrong = Color(0xFFD8901C);

  /// Dashboard atmosphere base tones (abstract education composition).
  static const Color atmosphereDeep = Color(0xFF1A2744);
  static const Color atmosphereMid = Color(0xFF2C4570);
  static const Color atmosphereSoft = Color(0xFFDCE6F6);
  static const Color atmosphereWarm = Color(0xFFF2E8D8);

  static const LinearGradient workspaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundTop,
      Color(0xFFEEF2FA),
      backgroundBottom,
    ],
  );
}

/// Controlled accent pair for a Dashboard destination.
class AdminDestinationAccent {
  const AdminDestinationAccent({
    required this.soft,
    required this.strong,
  });

  final Color soft;
  final Color strong;

  static const questions = AdminDestinationAccent(
    soft: AdminColors.questionsSoft,
    strong: AdminColors.questionsStrong,
  );

  static const importQuestions = AdminDestinationAccent(
    soft: AdminColors.importSoft,
    strong: AdminColors.importStrong,
  );

  /// Syllabus / chapter identity — muted warm amber.
  static const chapters = AdminDestinationAccent(
    soft: AdminColors.testsSoft,
    strong: AdminColors.testsStrong,
  );

  /// Examination series identity — muted indigo.
  static const testSeries = AdminDestinationAccent(
    soft: AdminColors.chaptersSoft,
    strong: AdminColors.chaptersStrong,
  );
}
