import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';

/// Tracks whether the current Admin content has unsaved form edits.
class AdminDirtyController extends ChangeNotifier {
  bool Function()? _isDirtyChecker;

  void bind(bool Function() isDirtyChecker) {
    _isDirtyChecker = isDirtyChecker;
  }

  void unbind(bool Function() isDirtyChecker) {
    if (identical(_isDirtyChecker, isDirtyChecker)) {
      _isDirtyChecker = null;
    }
  }

  bool get isDirty => _isDirtyChecker?.call() ?? false;

  /// Returns true when navigation may proceed.
  Future<bool> confirmLeaveIfNeeded(BuildContext context) async {
    if (!isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
            'You have unsaved changes. If you leave this page, your changes '
            'will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AdminColors.danger,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Discard & Leave'),
            ),
          ],
        );
      },
    );
    return result == true;
  }

  /// Always confirms sign-out. Dirty and clean use ONE dialog each (never two).
  Future<bool> confirmSignOutIfNeeded(BuildContext context) {
    return AdminSignOutConfirm.show(context, isDirty: isDirty);
  }
}

/// Shared Admin sign-out confirmation (shell + auth surfaces).
///
/// Clean → Cancel / Sign Out
/// Dirty → Stay / Discard & Sign Out
/// Never stacks both dialogs.
abstract final class AdminSignOutConfirm {
  static Future<bool> show(
    BuildContext context, {
    required bool isDirty,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        if (isDirty) {
          return AlertDialog(
            key: const ValueKey('admin-sign-out-dirty-dialog'),
            title: const Text('Sign out and discard changes?'),
            content: const Text(
              'You have unsaved changes. Signing out will discard them.',
            ),
            actions: [
              TextButton(
                key: const ValueKey('dirty-sign-out-stay'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              FilledButton(
                key: const ValueKey('dirty-sign-out-discard'),
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Discard & Sign Out'),
              ),
            ],
          );
        }

        return AlertDialog(
          key: const ValueKey('admin-sign-out-clean-dialog'),
          title: const Text('Sign out?'),
          content: const Text(
            'Are you sure you want to sign out of the Admin workspace?',
          ),
          actions: [
            TextButton(
              key: const ValueKey('sign-out-cancel'),
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const ValueKey('sign-out-confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
    return result == true;
  }
}

class AdminDirtyScope extends InheritedNotifier<AdminDirtyController> {
  const AdminDirtyScope({
    super.key,
    required AdminDirtyController controller,
    required super.child,
  }) : super(notifier: controller);

  static AdminDirtyController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminDirtyScope>()
        ?.notifier;
  }

  static AdminDirtyController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'AdminDirtyScope not found in context');
    return controller!;
  }
}
