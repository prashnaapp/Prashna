import 'dart:async';

import 'package:flutter/material.dart';

import '../../authentication/models/auth_user.dart';
import '../../authentication/services/auth_service.dart';
import '../services/admin_auth_service.dart';
import 'admin_auth_phase.dart';
import 'admin_auth_phase_resolver.dart';
import 'screens/admin_access_denied_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';

/// Gates Admin Web UI on Firebase Auth + `admin: true` custom claim.
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({
    super.key,
    this.authService,
    this.adminAuthService,
    this.authStateChanges,
    this.isAdminChecker,
    this.authenticatedChild,
  });

  final AuthService? authService;
  final AdminAuthService? adminAuthService;

  /// Test override for auth stream.
  final Stream<AuthUser?>? authStateChanges;

  /// Test override for claim verification (must mirror token claims).
  final Future<bool> Function({bool forceRefresh})? isAdminChecker;
  final Widget? authenticatedChild;

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  AdminAuthPhase _phase = AdminAuthPhase.loading;
  AuthUser? _user;
  Object? _error;
  StreamSubscription<AuthUser?>? _subscription;

  AuthService get _auth => widget.authService ?? AuthService.instance;

  AdminAuthService get _adminAuth =>
      widget.adminAuthService ?? AdminAuthService.instance;

  Future<bool> Function({bool forceRefresh}) get _isAdmin =>
      widget.isAdminChecker ?? _adminAuth.isAdmin;

  @override
  void initState() {
    super.initState();
    final stream = widget.authStateChanges ?? _auth.authStateChanges();
    _subscription = stream.listen(
      _onAuthChanged,
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _phase = AdminAuthPhase.login;
          _user = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _onAuthChanged(AuthUser? user) async {
    if (!mounted) return;
    setState(() {
      _phase = AdminAuthPhase.loading;
      _error = null;
      _user = user;
    });

    try {
      final phase = await AdminAuthPhaseResolver.resolve(
        user: user,
        isAdmin: _isAdmin,
        forceRefreshClaim: true,
      );
      if (!mounted) return;
      setState(() => _phase = phase);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _phase = user == null
            ? AdminAuthPhase.login
            : AdminAuthPhase.accessDenied;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case AdminAuthPhase.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AdminAuthPhase.login:
        return AdminLoginScreen(
          authService: widget.authService,
          errorMessage: _error?.toString(),
        );
      case AdminAuthPhase.accessDenied:
        return AdminAccessDeniedScreen(
          user: _user,
          onSignOut: _signOut,
        );
      case AdminAuthPhase.dashboard:
        return widget.authenticatedChild ??
            AdminDashboardScreen(
              user: _user,
              onSignOut: _signOut,
            );
    }
  }
}
