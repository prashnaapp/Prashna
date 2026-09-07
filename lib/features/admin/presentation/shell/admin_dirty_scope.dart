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

  /// Returns true when sign-out may proceed.
  Future<bool> confirmSignOutIfNeeded(BuildContext context) async {
    if (!isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('You have unsaved changes'),
          content: const Text(
            'You have unsaved changes. If you sign out now, your changes '
            'will be lost.',
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
