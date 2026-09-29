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

/// Any-word prefixes stored for Admin Question Bank search.
///
/// V1 matches one active token anywhere in the English question. A term such
/// as `date` matches the word `date` in the middle of a sentence, and `mini`
/// matches the token produced from `Mini-Constitution`. Firestore
/// `array-contains` cannot express an AND across several words, so a
/// multi-word box uses its final token only.
abstract final class QuestionSearchPrefixes {
  static const String field = 'questionSearchPrefixes';

  /// `on` and `date` stay searchable. One-character tokens are omitted.
  static const int minPrefixLength = 2;

  /// Long tokens remain searchable by their first 32 characters.
  static const int maxPrefixLength = 32;

  /// Keeps a pasted passage from growing the Question document without bound.
  /// Full tokens are retained before shorter prefixes.
  static const int maxPrefixes = 800;

  static List<String> tokenize(String? value) {
    final normalized = QuestionSearchText.normalize(value ?? '');
    if (normalized.isEmpty) return const [];
    return [
      for (final token in normalized.split(RegExp(r'[^a-z0-9]+')))
        if (token.isNotEmpty) token,
    ];
  }

  /// The single Firestore `array-contains` value for this search box.
  static String? queryTerm(String? value) {
    final tokens = tokenize(value);
    if (tokens.isEmpty) return null;
    final token = tokens.last;
    if (token.length < minPrefixLength) return null;
    if (token.length <= maxPrefixLength) return token;
    return token.substring(0, maxPrefixLength);
  }

  static List<String> fromQuestion(String value) {
    final words = <String>{};
    final shorter = <String>{};
    for (final token in tokenize(value)) {
      if (token.length < minPrefixLength) continue;
      final limit = token.length < maxPrefixLength
          ? token.length
          : maxPrefixLength;
      final capped = token.substring(0, limit);
      words.add(capped);
      for (var length = minPrefixLength; length < limit; length++) {
        shorter.add(capped.substring(0, length));
      }
    }
    final orderedWords = words.toList()..sort();
    final orderedPrefixes = shorter.toList()..sort();
    final combined = <String>[...orderedWords, ...orderedPrefixes];
    if (combined.length <= maxPrefixes) {
      combined.sort();
      return combined;
    }
    return combined.take(maxPrefixes).toList();
  }
}
