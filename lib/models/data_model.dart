import 'package:flutter/material.dart';

// ===============================
// DATA MODELS
// ===============================

@immutable
class UserProfile {
  final String name;
  final String avatarUrl;
  final int streakDays;
  final bool hasActiveLesson;
  const UserProfile({
    required this.name,
    required this.avatarUrl,
    required this.streakDays,
    required this.hasActiveLesson,
  });
}

@immutable
class AdaptiveMetrics {
  final String level; // Beginner, Intermediate, Advanced
  final double mastery; // 0..1 depth of understanding
  final String pace; // Slow, Steady, Fast
  final Duration weeklyTime; // invested time this week
  const AdaptiveMetrics({
    required this.level,
    required this.mastery,
    required this.pace,
    required this.weeklyTime,
  });
}

@immutable
class Recommendation {
  final String id;
  final String title;
  final String reason;
  final Duration estimatedTime;
  final double difficultyMatch; // 0..1
  final String topic;
  const Recommendation({
    required this.id,
    required this.title,
    required this.reason,
    required this.estimatedTime,
    required this.difficultyMatch,
    required this.topic,
  });
}

@immutable
class ActiveLesson {
  final String id;
  final String title;
  final String topic;
  final double progress; // 0..1
  final Duration timeSpent;
  const ActiveLesson({
    required this.id,
    required this.title,
    required this.topic,
    required this.progress,
    required this.timeSpent,
  });
}

@immutable
class WeeklyActivity {
  final List<int> lessonsPerDay; // length 7
  final List<double> avgTimePerLessonMinutes; // length 7
  final String paceTrend; // accelerating/steady/slowing down
  final double fasterVsLastWeek; // e.g. 0.2 for 20%
  const WeeklyActivity({
    required this.lessonsPerDay,
    required this.avgTimePerLessonMinutes,
    required this.paceTrend,
    required this.fasterVsLastWeek,
  });
}

@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final bool earned;
  final IconData icon;
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.earned,
    required this.icon,
  });
}

@immutable
class DailyChallenge {
  final String id;
  final String title;
  final String description;
  final String difficulty;
  final Duration estimatedTime;
  final int rewardXp;
  const DailyChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.estimatedTime,
    required this.rewardXp,
  });
}

@immutable
class Insight {
  final String id;
  final String text;
  const Insight({required this.id, required this.text});
}

@immutable
class NextTopic {
  final String id;
  final String title;
  final int prerequisiteCompletion; // 0..100
  final Duration estimatedTime;
  final String difficulty;
  const NextTopic({
    required this.id,
    required this.title,
    required this.prerequisiteCompletion,
    required this.estimatedTime,
    required this.difficulty,
  });
}
