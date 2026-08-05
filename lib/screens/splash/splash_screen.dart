import 'package:flutter/material.dart';

import '../../core/design_system/design_system.dart';
import '../../features/authentication/screens/login_screen.dart';
import '../../features/authentication/services/auth_service.dart';
import '../../features/course_enrollment/service/course_loader_service.dart';
import '../../navigation/main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _fadeDuration = Duration(milliseconds: 400);
  static const _minDisplay = Duration(milliseconds: 900);

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: _fadeDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    // Firebase Auth restores the session asynchronously on launch.
    final user = await AuthService.instance.authStateChanges().first;
    await Future<void>.delayed(_minDisplay);
    if (!mounted) return;

    if (user != null) {
      // Read-only course catalog + enrollment cache for the session.
      await CourseLoaderService.instance.load();
      if (!mounted) return;
    }

    final Widget destination = user != null
        ? const MainNavigationScreen()
        : const LoginScreen();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ప్రశ్న',
                    style: AppTextStyles.display(context).copyWith(
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'PRASHNA',
                    style: AppTextStyles.titleLarge(context).copyWith(
                      color: AppColors.textOnPrimary,
                      letterSpacing: 6,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'Every Question. One Step Closer to Victory!',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium(context).copyWith(
                      color: AppColors.textOnPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
