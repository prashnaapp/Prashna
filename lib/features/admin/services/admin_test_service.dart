import '../../course_enrollment/model/course.dart';
import '../../course_enrollment/service/course_catalog_service.dart';
import '../../tests/data/models/test_models.dart';
import '../../tests/data/test_cloud_mapper.dart';
import '../../tests/repository/test_cloud_repository.dart';

/// Admin-only orchestration for Test Series definitions.
///
/// Student-facing [TestService] remains read-only. All writes reach Firestore
/// through [TestCloudRepository] and are authorized by the Firebase Auth
/// `admin` custom claim in Firestore rules.
class AdminTestService {
  AdminTestService({
    TestCloudRepository? testRepository,
    CourseCatalogService? courseCatalogService,
  }) : _tests = testRepository ?? TestCloudRepository(),
       _courses = courseCatalogService;

  static final AdminTestService instance = AdminTestService();

  final TestCloudRepository _tests;
  final CourseCatalogService? _courses;

  Future<List<Course>> loadCourses() {
    return (_courses ?? CourseCatalogService()).loadPublishedCourses();
  }

  Future<List<TestModel>> loadTests(String courseId) {
    final id = courseId.trim();
    if (id.isEmpty) {
      throw const FormatException('Select a course before loading tests.');
    }
    return _tests.loadAdminTests(id);
  }

  Future<TestModel?> getTest(String testId) {
    return _tests.getAdminTestById(testId);
  }

  List<String> validate(TestModel test, {String? documentId}) {
    return TestCloudMapper.validateForWrite(test, documentId: documentId);
  }

  Future<String> createTest(TestModel test) {
    final errors = validate(test, documentId: 'generated-on-create');
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _tests.createTest(test);
  }

  Future<void> updateTest(TestModel test) {
    final errors = validate(test, documentId: test.id);
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }
    return _tests.updateTest(test);
  }

  Future<void> publishTest(String testId) async {
    final id = testId.trim();
    if (id.isEmpty) {
      throw const FormatException('Test ID is required.');
    }

    // Never trust the model that was rendered in the list. Re-read the
    // authoritative admin document immediately before changing visibility.
    final current = await _tests.getAdminTestById(id);
    if (current == null) {
      throw const FormatException('Test was not found.');
    }

    final errors = TestCloudMapper.validateForPublication(
      current,
      documentId: id,
    );
    if (errors.isNotEmpty) {
      throw FormatException(errors.join(' '));
    }

    await _tests.setTestPublished(id, isPublished: true);
  }

  Future<void> unpublishTest(String testId) {
    return _tests.setTestPublished(testId, isPublished: false);
  }
}
