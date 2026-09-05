/// Fixed Grand Test container identities.
///
/// These are product containers, not [TestModel]s. Child papers are published
/// tests whose [TestModel.seriesId] equals one of [ids].
abstract final class GrandTestSeries {
  static const grandTestI = 'Grand Test - I';
  static const grandTestII = 'Grand Test - II';
  static const grandTestIII = 'Grand Test - III';
  static const oldGrandTests = 'Old Grand Tests';

  static const List<String> ids = [
    grandTestI,
    grandTestII,
    grandTestIII,
    oldGrandTests,
  ];

  static bool isApproved(String? seriesId) {
    final value = seriesId?.trim();
    return value != null && value.isNotEmpty && ids.contains(value);
  }

  /// Approved selector values, plus a non-approved existing value so edit/save
  /// does not silently rewrite a production [seriesId].
  static List<String> selectorValues({String? existing}) {
    final current = existing?.trim();
    if (current == null || current.isEmpty || ids.contains(current)) {
      return ids;
    }
    return [...ids, current];
  }
}
