/// Current Affairs catalog models (admin-uploaded sets; Firebase later).
enum CurrentAffairsMode {
  weekly,
  monthly,
}

class CurrentAffairsSet {
  const CurrentAffairsSet({
    required this.id,
    required this.title,
    required this.mode,
    required this.questionCount,
    required this.marks,
    required this.durationMinutes,
  });

  final String id;
  final String title;
  final CurrentAffairsMode mode;
  final int questionCount;
  final int marks;
  final int durationMinutes;
}
