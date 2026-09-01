import '../../syllabus/services/syllabus_service.dart';
import '../data/models/test_models.dart';

/// Presentation-only helpers for the catalog Test Instructions screen.
///
/// Does not change test metadata, scoring, or duration values.
abstract final class TestInstructionsPresentation {
  /// Human-readable duration from the existing [durationMinutes] integer.
  static String durationLabel(int durationMinutes) {
    final unit = durationMinutes == 1 ? 'Minute' : 'Minutes';
    return '$durationMinutes $unit';
  }

  /// Lavender context pill text from IDs already on [test].
  ///
  /// Returns null when paper/part/unit cannot be resolved from existing
  /// catalog data — never fabricates "Chapter 5" or similar.
  static String? contextLabel(TestModel test, {SyllabusService? syllabus}) {
    final service = syllabus ?? SyllabusService.instance;
    final paperId = test.paperId?.trim();
    if (paperId == null || paperId.isEmpty) return null;

    final segments = <String>[];
    final paper = service.getPaper(courseId: test.examId, paperId: paperId);
    final paperTitle = paper?.title.trim();
    if (paperTitle != null && paperTitle.isNotEmpty) {
      segments.add(paperTitle);
    }

    final partId = test.partId?.trim();
    if (partId != null && partId.isNotEmpty) {
      final part = service.getPart(
        courseId: test.examId,
        paperId: paperId,
        partId: partId,
      );
      final partLabel = part?.displayName.trim();
      if (partLabel != null && partLabel.isNotEmpty) {
        segments.add(partLabel);
      }
    }

    final unitId = test.syllabusUnitId?.trim();
    if (unitId != null && unitId.isNotEmpty) {
      final unit = partId == null || partId.isEmpty
          ? service.getPaperSyllabusUnit(
              courseId: test.examId,
              paperId: paperId,
              unitId: unitId,
            )
          : service.getPartSyllabusUnit(
              courseId: test.examId,
              paperId: paperId,
              partId: partId,
              unitId: unitId,
            );
      final unitLabel = unit?.displayName.trim();
      if (unitLabel != null && unitLabel.isNotEmpty) {
        segments.add(unitLabel);
      }
    }

    if (segments.isEmpty) return null;
    return segments.join(' • ');
  }
}
