import 'package:flutter/material.dart';

import '../profile_visual.dart';

/// Section label over a stack of evenly spaced Profile rows.
class ProfileSection extends StatelessWidget {
  const ProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  static const double rowGap = 10;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: ProfileVisual.sectionTitle(context)),
        const SizedBox(height: 10),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: rowGap),
          children[i],
        ],
      ],
    );
  }
}
