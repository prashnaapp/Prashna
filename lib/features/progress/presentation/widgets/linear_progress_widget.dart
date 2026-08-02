import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class LinearProgressWidget extends StatelessWidget {
  const LinearProgressWidget({
    super.key,
    required this.value,
    this.height = AppSpacing.sm,
  });

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AppLinearProgress(
      value: value.clamp(0, 1),
      height: height,
      showLabel: false,
    );
  }
}
