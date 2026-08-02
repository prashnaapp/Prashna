import '../dummy/current_affairs_dummy_data.dart';
import '../models/current_affairs_models.dart';
import '../repositories/current_affairs_repository.dart';

/// Current Affairs catalog API for UI.
class CurrentAffairsService {
  CurrentAffairsService._();

  static final CurrentAffairsService instance = CurrentAffairsService._();

  final CurrentAffairsRepository _repository = CurrentAffairsRepository.instance;

  String get courseId => CurrentAffairsDummyData.courseId;

  List<String> get instructions => CurrentAffairsDummyData.instructions;

  List<CurrentAffairsSet> getWeeklySets() => _repository.getWeeklySets();

  List<CurrentAffairsSet> getMonthlySets() => _repository.getMonthlySets();

  CurrentAffairsSet? getSetById(String id) => _repository.getSetById(id);
}
