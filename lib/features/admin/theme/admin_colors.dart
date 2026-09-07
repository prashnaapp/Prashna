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
  static const Color sidebarTextMuted = Color(0xFF9AA6C2);

  static const Color border = Color(0xFFD9E0EF);
  static const Color textPrimary = Color(0xFF152038);
  static const Color textSecondary = Color(0xFF5B6B86);
  static const Color textTertiary = Color(0xFF8B97AE);

  static const Color success = Color(0xFF1F9D6A);
  static const Color successSoft = Color(0xFFE7F7F0);
  static const Color warning = Color(0xFFD8901C);
  static const Color warningSoft = Color(0xFFFFF6E8);
  static const Color danger = Color(0xFFD14343);
  static const Color dangerSoft = Color(0xFFFDECEC);

  static const Color draft = Color(0xFF6B7280);
  static const Color published = Color(0xFF1F9D6A);
  static const Color archived = Color(0xFF9A6B2F);

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
