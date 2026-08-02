import '../dummy/current_affairs_dummy_data.dart';
import '../models/current_affairs_models.dart';

/// Repository for Current Affairs sets. Dummy today; Firebase later.
class CurrentAffairsRepository {
  CurrentAffairsRepository._();

  static final CurrentAffairsRepository instance = CurrentAffairsRepository._();

  List<CurrentAffairsSet> getWeeklySets() =>
      List.unmodifiable(CurrentAffairsDummyData.weeklySets);

  List<CurrentAffairsSet> getMonthlySets() =>
      List.unmodifiable(CurrentAffairsDummyData.monthlySets);

  CurrentAffairsSet? getSetById(String id) {
    for (final set in CurrentAffairsDummyData.weeklySets) {
      if (set.id == id) return set;
    }
    for (final set in CurrentAffairsDummyData.monthlySets) {
      if (set.id == id) return set;
    }
    return null;
  }
}
