/// English prefix-search text stored on Question writes.
///
/// Trim, lowercase, and collapse whitespace. Telugu is not folded into this
/// field; a second language would be a separate bounded field.
abstract final class QuestionSearchText {
  static const String field = 'questionSearchText';

  static String normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}
