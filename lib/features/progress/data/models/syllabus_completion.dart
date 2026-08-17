/// Student-controlled syllabus-unit completion for one CanonicalScope.
///
/// Path: `user_progress/{uid}/syllabus_completion/{scopeKey}`
///
/// Missing document ⇒ [SyllabusCompletionStatus.notStarted].
/// Clients never write these documents directly.
enum SyllabusCompletionStatus { notStarted, inProgress, completed }

extension SyllabusCompletionStatusCodec on SyllabusCompletionStatus {
  String get wireValue {
    switch (this) {
      case SyllabusCompletionStatus.notStarted:
        return 'not_started';
      case SyllabusCompletionStatus.inProgress:
        return 'in_progress';
      case SyllabusCompletionStatus.completed:
        return 'completed';
    }
  }

  static SyllabusCompletionStatus parse(String? raw) {
    switch ((raw ?? '').trim()) {
      case 'in_progress':
        return SyllabusCompletionStatus.inProgress;
      case 'completed':
        return SyllabusCompletionStatus.completed;
      case 'not_started':
      case '':
        return SyllabusCompletionStatus.notStarted;
      default:
        throw FormatException('Unknown syllabus completion status: $raw');
    }
  }
}

class SyllabusCompletion {
  const SyllabusCompletion({
    required this.scopeKey,
    required this.courseId,
    required this.paperId,
    required this.syllabusUnitId,
    required this.status,
    this.partId,
    this.updatedAt,
    this.completedAt,
  });

  final String scopeKey;
  final String courseId;
  final String paperId;
  final String? partId;
  final String syllabusUnitId;
  final SyllabusCompletionStatus status;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  /// Missing Firestore document ⇒ Not Started.
  factory SyllabusCompletion.notStarted({
    required String scopeKey,
    required String courseId,
    required String paperId,
    String? partId,
    required String syllabusUnitId,
  }) {
    return SyllabusCompletion(
      scopeKey: scopeKey,
      courseId: courseId,
      paperId: paperId,
      partId: partId,
      syllabusUnitId: syllabusUnitId,
      status: SyllabusCompletionStatus.notStarted,
    );
  }

  factory SyllabusCompletion.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
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

    return SyllabusCompletion(
      scopeKey: scopeKey,
      courseId: (data['courseId'] as String?)?.trim() ?? '',
      paperId: (data['paperId'] as String?)?.trim() ?? '',
      partId: (data['partId'] as String?)?.trim(),
      syllabusUnitId: (data['syllabusUnitId'] as String?)?.trim() ?? '',
      status: SyllabusCompletionStatusCodec.parse(data['status'] as String?),
      updatedAt: asDate(data['updatedAt']),
      completedAt: asDate(data['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'scopeKey': scopeKey,
      'courseId': courseId,
      'paperId': paperId,
      if (partId != null) 'partId': partId,
      'syllabusUnitId': syllabusUnitId,
      'status': status.wireValue,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }
}
