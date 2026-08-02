import 'models/syllabus_models.dart';

/// Single source of syllabus catalog data. Add new courses here only.
abstract final class SyllabusDummyData {
  static final List<SyllabusCourse> all = [
    SyllabusCourse(
      id: 'group-ii',
      name: 'Group-II',
      subtitle: 'TSPSC Group-II Services',
      totalMarks: 600,
      isEnrolled: true,
      isAvailable: true,
      icon: 'school',
      papers: [
        SyllabusPaper(
          id: 'paper-i',
          title: 'Paper I',
          sections: [
            _section('current-affairs', 'Current Affairs'),
            _section('international-relations', 'International Relations'),
            _section('general-science', 'General Science'),
            _section('environment', 'Environment'),
            _section('geography', 'Geography'),
            _section('history', 'History'),
            _section('telangana-society', 'Telangana Society'),
            _section('telangana-policies', 'Telangana Policies'),
            _section('social-issues', 'Social Issues'),
            _section('reasoning', 'Reasoning'),
            _section('english', 'English'),
          ],
        ),
        SyllabusPaper(
          id: 'paper-ii',
          title: 'Paper II',
          sections: [
            _section('socio-cultural-history', 'Socio-Cultural History'),
            _section('constitution-politics', 'Constitution & Politics'),
            _section('social-structure', 'Social Structure'),
          ],
        ),
        SyllabusPaper(
          id: 'paper-iii',
          title: 'Paper III',
          sections: [
            _section('indian-economy', 'Indian Economy'),
            _section('telangana-economy', 'Telangana Economy'),
            _section('development', 'Development'),
          ],
        ),
        SyllabusPaper(
          id: 'paper-iv',
          title: 'Paper IV',
          sections: [
            _section(
              'movement-1948-1970',
              'Telangana Movement (1948–1970)',
            ),
            _section(
              'movement-1971-1990',
              'Telangana Movement (1971–1990)',
            ),
            _section(
              'movement-1991-2014',
              'Telangana Movement (1991–2014)',
            ),
          ],
        ),
      ],
    ),
    SyllabusCourse(
      id: 'group-iii',
      name: 'Group-III',
      subtitle: 'TSPSC Group-III Services',
      totalMarks: 450,
      isEnrolled: true,
      isAvailable: true,
      icon: 'menu_book',
      papers: [
        SyllabusPaper(
          id: 'paper-i',
          title: 'Paper I',
          sections: [
            _section('current-affairs', 'Current Affairs'),
            _section('general-science', 'General Science'),
            _section('geography', 'Geography'),
            _section('history', 'History'),
            _section('telangana-society', 'Telangana Society'),
            _section('reasoning', 'Reasoning'),
            _section('english', 'English'),
          ],
        ),
        SyllabusPaper(
          id: 'paper-ii',
          title: 'Paper II',
          sections: [
            _section('socio-cultural-history', 'Socio-Cultural History'),
            _section('constitution-politics', 'Constitution & Politics'),
            _section('social-structure', 'Social Structure'),
          ],
        ),
        SyllabusPaper(
          id: 'paper-iii',
          title: 'Paper III',
          sections: [
            _section('indian-economy', 'Indian Economy'),
            _section('telangana-economy', 'Telangana Economy'),
            _section('development', 'Development'),
          ],
        ),
      ],
    ),
    SyllabusCourse(
      id: 'police-si',
      name: 'Police SI',
      subtitle: 'Sub Inspector Recruitment',
      totalMarks: 200,
      isEnrolled: false,
      isAvailable: false,
      icon: 'badge',
      papers: const [],
    ),
    SyllabusCourse(
      id: 'constable',
      name: 'Constable',
      subtitle: 'Police Constable Recruitment',
      totalMarks: 200,
      isEnrolled: false,
      isAvailable: false,
      icon: 'local_police',
      papers: const [],
    ),
  ];

  /// One section with a matching topic chapter (data-driven leaf).
  static SyllabusSection _section(String id, String title) {
    return SyllabusSection(
      id: id,
      title: title,
      topics: [
        SyllabusTopic(id: '$id-topic', title: title),
      ],
    );
  }
}
