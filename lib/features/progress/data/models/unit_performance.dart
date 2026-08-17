/// Server-authored performance for one canonical syllabus scope.
///
/// Path: `user_progress/{uid}/unit_performance/{scopeKey}`
///
/// Analytical identity is [scopeKey] derived from CanonicalScope.
/// Clients never write these documents.
class UnitPerformance {
  const UnitPerformance({
    required this.scopeKey,
    required this.courseId,
    required this.paperId,
    required this.syllabusUnitId,
    required this.testsAttempted,
    required this.testsCompleted,
    required this.questionsAttempted,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.totalMarks,
    required this.marksObtained,
    required this.accuracy,
    required this.percentage,
    required this.bestMarks,
    required this.bestPercentage,
    this.partId,
    this.latestAttemptAt,
    this.lastTestId,
    this.lastAttemptId,
    this.scopeShape,
    this.authority,
    this.schemaVersion,
  });

  final String scopeKey;
  final String courseId;
  final String paperId;
  final String? partId;
  final String syllabusUnitId;

  final int testsAttempted;
  final int testsCompleted;
  final int questionsAttempted;
  final int correct;
  final int wrong;
  final int skipped;

  final double totalMarks;
  final double marksObtained;
  final double accuracy;
  final double percentage;
  final double bestMarks;
  final double bestPercentage;

  final DateTime? latestAttemptAt;
  final String? lastTestId;
  final String? lastAttemptId;
  final String? scopeShape;
  final String? authority;
  final int? schemaVersion;

  bool get isServerVerified => authority == 'server_verified';

  factory UnitPerformance.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    int asInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    double asDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    DateTime? asDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      try {
        // cloud_firestore Timestamp
        // ignore: avoid_dynamic_calls
        return value.toDate() as DateTime?;
      } catch (_) {
        return null;
      }
    }

    final scopeKey = (data['scopeKey'] as String?)?.trim().isNotEmpty == true
        ? (data['scopeKey'] as String).trim()
        : docId;

    return UnitPerformance(
      scopeKey: scopeKey,
      courseId: (data['courseId'] as String?)?.trim() ?? '',
      paperId: (data['paperId'] as String?)?.trim() ?? '',
      partId: (data['partId'] as String?)?.trim(),
      syllabusUnitId: (data['syllabusUnitId'] as String?)?.trim() ?? '',
      testsAttempted: asInt(data['testsAttempted']),
      testsCompleted: asInt(data['testsCompleted']),
      questionsAttempted: asInt(data['questionsAttempted']),
      correct: asInt(data['correct']),
      wrong: asInt(data['wrong']),
      skipped: asInt(data['skipped']),
      totalMarks: asDouble(data['totalMarks']),
      marksObtained: asDouble(data['marksObtained']),
      accuracy: asDouble(data['accuracy']),
      percentage: asDouble(data['percentage']),
      bestMarks: asDouble(data['bestMarks']),
      bestPercentage: asDouble(data['bestPercentage']),
      latestAttemptAt: asDate(data['latestAttemptAt']),
      lastTestId: (data['lastTestId'] as String?)?.trim(),
      lastAttemptId: (data['lastAttemptId'] as String?)?.trim(),
      scopeShape: (data['scopeShape'] as String?)?.trim(),
      authority: (data['authority'] as String?)?.trim(),
      schemaVersion: data['schemaVersion'] is num
          ? (data['schemaVersion'] as num).toInt()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scopeKey': scopeKey,
      'courseId': courseId,
      'paperId': paperId,
      if (partId != null) 'partId': partId,
      'syllabusUnitId': syllabusUnitId,
      'testsAttempted': testsAttempted,
      'testsCompleted': testsCompleted,
      'questionsAttempted': questionsAttempted,
      'correct': correct,
      'wrong': wrong,
      'skipped': skipped,
      'totalMarks': totalMarks,
      'marksObtained': marksObtained,
      'accuracy': accuracy,
      'percentage': percentage,
      'bestMarks': bestMarks,
      'bestPercentage': bestPercentage,
      if (latestAttemptAt != null)
        'latestAttemptAt': latestAttemptAt!.toIso8601String(),
      if (lastTestId != null) 'lastTestId': lastTestId,
      if (lastAttemptId != null) 'lastAttemptId': lastAttemptId,
      if (scopeShape != null) 'scopeShape': scopeShape,
      if (authority != null) 'authority': authority,
      if (schemaVersion != null) 'schemaVersion': schemaVersion,
    };
  }
}
