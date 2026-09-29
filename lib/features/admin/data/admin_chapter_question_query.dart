import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/question_search_text.dart';
import 'admin_chapter_question_context.dart';
import 'admin_question_scope.dart';
import 'admin_test_series_question_query.dart';

/// Server query for one terminal Chapter Question Bank.
///
/// Equality filters are the canonical Chapter context. [lessonId] is never a
/// filter, so legacy lesson values stay in the same Topic bank.
///
/// Documents missing `contentArea` cannot match `contentArea == chapter`.
/// This query does not fall back to a whole-course read.
class AdminChapterQuestionQuery {
  const AdminChapterQuestionQuery({
    required this.courseId,
    required this.paperId,
    this.majorStudyAreaId,
    this.contentTopicId,
    this.partId,
    this.topicId,
    this.syllabusUnitId,
    this.status,
    this.searchText,
    this.cursorDocumentId,
    this.cursorSearchText,
  });

  final String courseId;
  final String paperId;
  final String? majorStudyAreaId;
  final String? contentTopicId;
  final String? partId;
  final String? topicId;
  final String? syllabusUnitId;
  final QuestionPublicationStatus? status;
  final String? searchText;
  final String? cursorDocumentId;
  final String? cursorSearchText;

  factory AdminChapterQuestionQuery.fromContext(
    AdminChapterQuestionContext location, {
    QuestionPublicationStatus? status,
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) {
    final courseId = _required(location.courseId, 'courseId');
    final paperId = _required(location.paperId, 'paperId');
    final unitId = _optional(location.syllabusUnitId);
    final areaId = _optional(location.majorStudyAreaId);
    final contentTopicId = _optional(location.contentTopicId);
    final partId = _optional(location.partId);
    final topicId = _optional(location.topicId);

    if (unitId != null) {
      return AdminChapterQuestionQuery(
        courseId: courseId,
        paperId: paperId,
        partId: partId,
        syllabusUnitId: unitId,
        status: status,
        searchText: searchText,
        cursorDocumentId: cursorDocumentId,
        cursorSearchText: cursorSearchText,
      );
    }
    if (contentTopicId != null) {
      return AdminChapterQuestionQuery(
        courseId: courseId,
        paperId: paperId,
        majorStudyAreaId: _required(areaId, 'majorStudyAreaId'),
        contentTopicId: contentTopicId,
        status: status,
        searchText: searchText,
        cursorDocumentId: cursorDocumentId,
        cursorSearchText: cursorSearchText,
      );
    }
    return AdminChapterQuestionQuery(
      courseId: courseId,
      paperId: paperId,
      partId: _required(partId, 'partId'),
      topicId: _required(topicId, 'topicId'),
      status: status,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
  }

  String? get normalizedSearch {
    final normalized = QuestionSearchText.normalize(searchText ?? '');
    return normalized.isEmpty ? null : normalized;
  }

  /// Final token used by the any-word prefix query.
  String? get searchPrefix => QuestionSearchPrefixes.queryTerm(searchText);

  int get readLimit => AdminTestSeriesQuestionQuery.pageSize + 1;

  QuestionBankCursorPlan get cursorPlan => buildQuestionBankCursorPlan(
    searchPrefix: searchPrefix,
    cursorDocumentId: cursorDocumentId,
    readLimit: readLimit,
  );

  /// Firestore equality filters. `lessonId` is intentionally absent.
  List<({String field, Object value})> get equalityFilters {
    final filters = <({String field, Object value})>[
      (field: 'contentArea', value: AdminQuestionScope.contentAreaChapter),
      (field: 'courseId', value: courseId),
      (field: 'paperId', value: paperId),
    ];
    if (_present(syllabusUnitId)) {
      if (_present(partId)) {
        filters.add((field: 'partId', value: partId!.trim()));
      }
      filters.add((field: 'syllabusUnitId', value: syllabusUnitId!.trim()));
    } else if (_present(contentTopicId)) {
      filters.add((field: 'majorStudyAreaId', value: majorStudyAreaId!.trim()));
      filters.add((field: 'contentTopicId', value: contentTopicId!.trim()));
    } else {
      filters.add((field: 'partId', value: partId!.trim()));
      filters.add((field: 'topicId', value: topicId!.trim()));
    }
    if (status != null) {
      filters.add((field: 'status', value: status!.name));
    }
    return filters;
  }

  static String _required(String? value, String name) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw FormatException('Chapter Question Bank requires $name.');
    }
    return trimmed;
  }

  static String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _present(String? value) =>
      value != null && value.trim().isNotEmpty;
}
