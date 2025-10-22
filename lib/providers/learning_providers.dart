import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/data_models.dart';
import '../services/learning_repository.dart';

final repositoryProvider = Provider<LearningRepository>((ref) {
  return LearningRepository();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.read(repositoryProvider).fetchUserProfile();
});

final adaptiveMetricsProvider = FutureProvider<AdaptiveMetrics>((ref) async {
  return ref.read(repositoryProvider).fetchAdaptiveMetrics();
});

final recommendationsProvider =
    FutureProvider<List<Recommendation>>((ref) async {
  return ref.read(repositoryProvider).fetchRecommendations();
});

final activeLessonProvider = FutureProvider<ActiveLesson?>((ref) async {
  return ref.read(repositoryProvider).fetchActiveLesson();
});

final weeklyActivityProvider = FutureProvider<WeeklyActivity>((ref) async {
  return ref.read(repositoryProvider).fetchWeeklyActivity();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) async {
  return ref.read(repositoryProvider).fetchAchievements();
});

final dailyChallengeProvider = FutureProvider<DailyChallenge>((ref) async {
  return ref.read(repositoryProvider).fetchDailyChallenge();
});

final aiInsightsProvider = FutureProvider<List<Insight>>((ref) async {
  return ref.read(repositoryProvider).fetchInsights();
});

final nextTopicsProvider = FutureProvider<List<NextTopic>>((ref) async {
  return ref.read(repositoryProvider).fetchNextTopics();
});
