import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/service/course_catalog_service.dart';
import '../../question_bank/data/models/question_models.dart';
import '../../question_bank/data/question_cloud_mapper.dart';
import '../../question_bank/repository/question_cloud_repository.dart';

/// Admin-only orchestration for Question Bank content.
///
/// Student-facing [QuestionService] remains read/preparation-only. All writes
/// still reach Firestore through the existing QuestionCloudRepository and are
/// authorized by the Firebase Auth `admin` custom claim in Firestore rules.
class AdminQuestionService {
  AdminQuestionService({
    QuestionCloudRepository? questionRepository,
    CourseCatalogService? courseCatalogService,
  })  : _questions = questionRepository ?? QuestionCloudRepository(),
        _courses = courseCatalogService;

  static final AdminQuestionService instance = AdminQuestionService();

  final QuestionCloudRepository _questions;
  final CourseCatalogService? _courses;

  Future<List<Course>> loadCourses() {
    return (_courses ?? CourseCatalogService()).loadPublishedCourses();
  }

  Future<List<Question>> loadQuestions(String courseId) {
    final id = courseId.trim();
    if (id.isEmpty) {
      throw const FormatException('Select a course before loading questions.');
    }
    return _questions.loadQuestions(
      filter: QuestionFilter(courseId: id, activeOnly: false),
    );
  }

  Future<Question?> getQuestion(String questionId) {
    return _questions.getQuestionById(questionId);
  }

  List<String> validate(Question question, {String? documentId}) {
    return QuestionCloudMapper.validateForWrite(
      question,
      documentId: documentId,
    );
  }

  Future<String> createQuestion(Question question) {
    // The repository generates the ID. A non-empty sentinel validates all
    // content without allowing a client-provided ID to drift.
    final errors = validate(question, documentId: 'generated-on-create');
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _questions.createQuestion(question);
  }

  Future<void> updateQuestion(Question question) {
    final errors = validate(question, documentId: question.id);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _questions.updateQuestion(question);
  }

  Future<void> deactivateQuestion(String questionId) {
    return _questions.setQuestionActive(questionId, isActive: false);
  }

  Future<void> reactivateQuestion(String questionId) {
    return _questions.setQuestionActive(questionId, isActive: true);
  }
}
