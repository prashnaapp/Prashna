import '../data/models/syllabus_models.dart';

/// One Paper or Paper+Part stop in the Syllabus Browser sequence.
class SyllabusBrowserStop {
  const SyllabusBrowserStop({required this.paperId, this.partId});

  final String paperId;
  final String? partId;

  bool matches({required String? paperId, required String? partId}) {
    return this.paperId == paperId && this.partId == partId;
  }
}

/// Sequential Paper/Part destinations derived from existing course data.
abstract final class SyllabusBrowserSequence {
  static List<SyllabusBrowserStop> fromPapers(List<SyllabusPaper> papers) {
    final stops = <SyllabusBrowserStop>[];
    for (final paper in papers) {
      if (paper.hasPartSyllabusUnits) {
        for (final part in paper.parts) {
          stops.add(SyllabusBrowserStop(paperId: paper.id, partId: part.id));
        }
      } else {
        stops.add(SyllabusBrowserStop(paperId: paper.id));
      }
    }
    return stops;
  }

  static int indexOf(
    List<SyllabusBrowserStop> stops, {
    required String? paperId,
    required String? partId,
  }) {
    for (var i = 0; i < stops.length; i++) {
      if (stops[i].matches(paperId: paperId, partId: partId)) return i;
    }
    return 0;
  }
}
