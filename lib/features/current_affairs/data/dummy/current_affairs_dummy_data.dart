import '../models/current_affairs_models.dart';

/// Dummy Current Affairs catalog — add weeks/months here only.
abstract final class CurrentAffairsDummyData {
  static const courseId = 'current-affairs';

  static const instructions = [
    'Read every question carefully.',
    'Complete before time expires.',
    'Result shown immediately after completion.',
    'Progress updates automatically.',
  ];

  static const weeklySets = <CurrentAffairsSet>[
    CurrentAffairsSet(
      id: 'ca-week-1',
      title: 'Week 1',
      mode: CurrentAffairsMode.weekly,
      questionCount: 50,
      marks: 50,
      durationMinutes: 50,
    ),
    CurrentAffairsSet(
      id: 'ca-week-2',
      title: 'Week 2',
      mode: CurrentAffairsMode.weekly,
      questionCount: 50,
      marks: 50,
      durationMinutes: 50,
    ),
    CurrentAffairsSet(
      id: 'ca-week-3',
      title: 'Week 3',
      mode: CurrentAffairsMode.weekly,
      questionCount: 50,
      marks: 50,
      durationMinutes: 50,
    ),
    CurrentAffairsSet(
      id: 'ca-week-4',
      title: 'Week 4',
      mode: CurrentAffairsMode.weekly,
      questionCount: 50,
      marks: 50,
      durationMinutes: 50,
    ),
    CurrentAffairsSet(
      id: 'ca-week-5',
      title: 'Week 5',
      mode: CurrentAffairsMode.weekly,
      questionCount: 50,
      marks: 50,
      durationMinutes: 50,
    ),
  ];

  static const monthlySets = <CurrentAffairsSet>[
    CurrentAffairsSet(
      id: 'ca-month-2026-01',
      title: 'January 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-02',
      title: 'February 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-03',
      title: 'March 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-04',
      title: 'April 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-05',
      title: 'May 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-06',
      title: 'June 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-07',
      title: 'July 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
    CurrentAffairsSet(
      id: 'ca-month-2026-08',
      title: 'August 2026',
      mode: CurrentAffairsMode.monthly,
      questionCount: 100,
      marks: 100,
      durationMinutes: 100,
    ),
  ];
}
