import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/question_search_text.dart';
import 'admin_question_scope.dart';

/// One bounded Test Series Question Bank page.
class QuestionBankPage {
  const QuestionBankPage({
    required this.questions,
    required this.hasMore,
    this.cursorDocumentId,
    this.cursorSearchText,
  });

  final List<Question> questions;
  final bool hasMore;
  final String? cursorDocumentId;
  final String? cursorSearchText;
}

/// How a bank page is read. Cursor pagination, never offset or a growing limit.
class QuestionBankCursorPlan {
  const QuestionBankCursorPlan({
    required this.limit,
    required this.orderBy,
    required this.usesOffset,
    this.arrayContains,
    this.startAt,
    this.startAfter,
    this.endAt,
  });

  final int limit;
  final List<String> orderBy;
  final bool usesOffset;

  /// `questionSearchPrefixes` array-contains value. Null while browsing.
  final String? arrayContains;
  final List<Object>? startAt;
  final List<Object>? startAfter;
  final List<Object>? endAt;
}

/// Server-side Test Series Question Bank query.
///
/// [pageSize] is the page returned to the Admin. The read asks for one extra
/// document so the end of the bank is detected without a second count query.
class AdminTestSeriesQuestionQuery {
  const AdminTestSeriesQuestionQuery({
    required this.courseId,
    required this.testSeriesCategory,
    this.paperId,
    this.seriesId,
    this.year,
    this.searchText,
    this.cursorDocumentId,
    this.cursorSearchText,
  });

  /// Questions returned per page. Not an unlimited course read.
  static const int pageSize = 50;

  /// Document ID. Present on every Question, including legacy documents that
  /// have no `createdAt`. Ordering by `createdAt` would drop those documents.
  static const String documentOrderField = '__name__';

  final String courseId;
  final String testSeriesCategory;
  final String? paperId;
  final String? seriesId;
  final int? year;
  final String? searchText;
  final String? cursorDocumentId;
  final String? cursorSearchText;

  factory AdminTestSeriesQuestionQuery.fromScope(
    AdminQuestionScope scope, {
    String? searchText,
    String? cursorDocumentId,
    String? cursorSearchText,
  }) {
    if (!scope.isQuestionBank) {
      throw const FormatException(
        'Test Series Question Bank scope is incomplete.',
      );
    }
    final category = scope.testSeriesCategory!;
    return AdminTestSeriesQuestionQuery(
      courseId: scope.courseId!.trim(),
      testSeriesCategory: category,
      paperId: category == AdminQuestionScope.categoryPart
          ? scope.paperId!.trim()
          : null,
      seriesId: category == AdminQuestionScope.categoryMock
          ? scope.seriesId!.trim()
          : null,
      year: category == AdminQuestionScope.categoryPreviousYear
          ? scope.year
          : null,
      searchText: searchText,
      cursorDocumentId: cursorDocumentId,
      cursorSearchText: cursorSearchText,
    );
  }

  /// Empty when the Admin is not searching.
  String? get normalizedSearch {
    final normalized = QuestionSearchText.normalize(searchText ?? '');
    return normalized.isEmpty ? null : normalized;
  }

  /// Final token used by the any-word prefix query.
  String? get searchPrefix => QuestionSearchPrefixes.queryTerm(searchText);

  /// Firestore read size. One extra row detects the last page.
  int get readLimit => pageSize + 1;

  QuestionBankCursorPlan get cursorPlan => buildQuestionBankCursorPlan(
    searchPrefix: searchPrefix,
    cursorDocumentId: cursorDocumentId,
    readLimit: readLimit,
  );

  /// Equality filters applied by Firestore. No client-side course scan.
  List<({String field, Object value})> get equalityFilters {
    final filters = <({String field, Object value})>[
      (field: 'contentArea', value: AdminQuestionScope.contentAreaTestSeries),
      (field: 'testSeriesCategory', value: testSeriesCategory),
      (field: 'courseId', value: courseId),
    ];
    switch (testSeriesCategory) {
      case AdminQuestionScope.categoryPart:
        filters.add((field: 'paperId', value: paperId!));
      case AdminQuestionScope.categoryMock:
        filters.add((field: 'seriesId', value: seriesId!));
      case AdminQuestionScope.categoryPreviousYear:
        filters.add((field: 'year', value: year!));
    }
    return filters;
  }
}

/// Shared cursor for Test Series and Chapter banks.
///
/// Browse and any-word search both order by document ID. Search adds one
/// `questionSearchPrefixes` array-contains filter and never invents a
/// document path.
QuestionBankCursorPlan buildQuestionBankCursorPlan({
  required String? searchPrefix,
  required String? cursorDocumentId,
  required int readLimit,
}) {
  final cursor = cursorDocumentId?.trim();
  return QuestionBankCursorPlan(
    limit: readLimit,
    orderBy: const [AdminTestSeriesQuestionQuery.documentOrderField],
    usesOffset: false,
    arrayContains: searchPrefix,
    startAfter: cursor == null || cursor.isEmpty ? null : [cursor],
  );
}
