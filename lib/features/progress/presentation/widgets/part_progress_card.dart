import 'package:flutter/material.dart';

import 'paper_progress_card.dart';

class PartProgressCard extends StatelessWidget {
  const PartProgressCard({
    super.key,
    required this.title,
    required this.coveredMarks,
    required this.maxMarks,
    required this.progressPercent,
    this.onTap,
  });

  final String title;
  final double coveredMarks;
  final double maxMarks;
  final double progressPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PaperProgressCard(
      title: title,
      coveredMarks: coveredMarks,
      maxMarks: maxMarks,
      progressPercent: progressPercent,
      onTap: onTap,
    );
  }
}
