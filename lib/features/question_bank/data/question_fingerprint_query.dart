/// Bounded exact-fingerprint lookups. Each chunk is one `whereIn` query.
abstract final class QuestionFingerprintQuery {
  static const int chunkSize = 30;

  static List<List<String>> chunks(Iterable<String> fingerprints) {
    final unique = <String>[];
    final seen = <String>{};
    for (final raw in fingerprints) {
      final fingerprint = raw.trim();
      if (fingerprint.isEmpty || !seen.add(fingerprint)) continue;
      unique.add(fingerprint);
    }
    final groups = <List<String>>[];
    for (var i = 0; i < unique.length; i += chunkSize) {
      final end = i + chunkSize < unique.length ? i + chunkSize : unique.length;
      groups.add(unique.sublist(i, end));
    }
    return groups;
  }
}
