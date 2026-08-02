import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class ResultHeader extends StatelessWidget {
  const ResultHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Practice Completed',
      style: AppTextStyles.headline(context),
      textAlign: TextAlign.center,
    );
  }
}
