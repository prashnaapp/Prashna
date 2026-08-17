import 'package:flutter_test/flutter_test.dart';
import 'package:telangana_prep/features/syllabus/data/syllabus_dummy_data.dart';
import 'package:telangana_prep/features/syllabus/services/syllabus_service.dart';

void main() {
  final groupIII = SyllabusDummyData.all.singleWhere(
    (course) => course.id == 'group-iii',
  );

  test('Group-III has exactly 3 papers with locked IDs', () {
    expect(groupIII.papers.map((paper) => paper.id), [
      'group-iii-paper-i',
      'group-iii-paper-ii',
      'group-iii-paper-iii',
    ]);
  });

  test('Paper-I has no Parts and 11 direct syllabus units', () {
    final paper = groupIII.papers.singleWhere(
      (paper) => paper.id == 'group-iii-paper-i',
    );
    expect(paper.parts, isEmpty);
    expect(paper.sections, isEmpty);
    expect(paper.majorStudyAreas, isEmpty);
    expect(paper.syllabusUnits, hasLength(11));
    expect(
      paper.syllabusUnits.every((unit) => unit.id.startsWith('group-iii-paper-i-unit-')),
      isTrue,
    );
  });

  test('Paper-II and Paper-III each have exactly 3 Parts', () {
    for (final paperId in ['group-iii-paper-ii', 'group-iii-paper-iii']) {
      final paper = groupIII.papers.singleWhere((paper) => paper.id == paperId);
      expect(paper.syllabusUnits, isEmpty, reason: paperId);
      expect(paper.parts, hasLength(3), reason: paperId);
      expect(
        paper.parts.map((part) => part.displayName).toList(),
        ['Part-I', 'Part-II', 'Part-III'],
        reason: paperId,
      );
    }
  });

  test('Group-III contains exactly 46 final syllabus units', () {
    final paperI = groupIII.papers
        .singleWhere((paper) => paper.id == 'group-iii-paper-i')
        .syllabusUnits
        .length;
    final partUnits = groupIII.papers
        .skip(1)
        .expand((paper) => paper.parts)
        .expand((part) => part.syllabusUnits)
        .length;
    expect(paperI + partUnits, 46);
  });

  test('no Indian Economy parent folder under Paper-III Part-I', () {
    final part = SyllabusService.instance.getPart(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-iii',
      partId: 'group-iii-paper-iii-part-i',
    )!;
    expect(part.displayName, 'Part-I');
    expect(part.officialName, 'Indian Economy: Issues and Challenges');
    expect(
      part.syllabusUnits.map((unit) => unit.displayName),
      isNot(contains('Indian Economy')),
    );
    expect(
      part.syllabusUnits.map((unit) => unit.displayName),
      contains('Agriculture and Allied Sectors'),
    );
    expect(
      part.syllabusUnits.singleWhere(
        (unit) => unit.displayName == 'Agriculture and Allied Sectors',
      ).id,
      'group-iii-paper-iii-part-i-unit-03',
    );
  });

  test('Kakatiyas and Medieval Telangana is directly under Paper-II Part-I', () {
    final part = SyllabusService.instance.getPart(
      courseId: 'group-iii',
      paperId: 'group-iii-paper-ii',
      partId: 'group-iii-paper-ii-part-i',
    )!;
    expect(
      part.syllabusUnits.map((unit) => unit.displayName),
      contains('Kakatiyas and Medieval Telangana'),
    );
    final unit = part.syllabusUnits.singleWhere(
      (unit) => unit.displayName == 'Kakatiyas and Medieval Telangana',
    );
    expect(unit.id, 'group-iii-paper-ii-part-i-unit-02');
  });

  test('Group-III has no Lessons level', () {
    for (final paper in groupIII.papers) {
      for (final part in paper.parts) {
        expect(part.topics, isEmpty, reason: part.id);
        for (final unit in part.syllabusUnits) {
          expect(unit.displayName.toLowerCase(), isNot(contains('lesson')));
        }
      }
      for (final unit in paper.syllabusUnits) {
        expect(unit.displayName.toLowerCase(), isNot(contains('lesson')));
      }
    }
  });

  test('Group-III IDs are unique and course-scoped', () {
    final ids = <String>[];
    for (final paper in groupIII.papers) {
      ids.add(paper.id);
      ids.addAll(paper.syllabusUnits.map((unit) => unit.id));
      for (final part in paper.parts) {
        ids.add(part.id);
        ids.addAll(part.syllabusUnits.map((unit) => unit.id));
      }
    }
    expect(ids.toSet().length, ids.length);
    expect(ids, everyElement(startsWith('group-iii-')));
  });
}
