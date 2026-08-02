import '../data/home_dummy_data.dart';
import '../data/models/home_models.dart';

/// Home dashboard data. UI never reads [HomeDummyData] directly.
class HomeService {
  HomeService._();

  static final HomeService instance = HomeService._();

  String getStudentName() => HomeDummyData.studentName;

  ContinueLearningModel getContinueLearning() => HomeDummyData.continueLearning;

  TodayGoalModel getTodayGoal() => HomeDummyData.todayGoal;
}
