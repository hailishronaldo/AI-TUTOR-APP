import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../main.dart'; // For constants and AuthGate
import '../models/data_models.dart'; // Added import for data models
import '../providers/learning_providers.dart'; // Added import for providers

// 🏠 HOME
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeInController = AnimationController(
    vsync: this,
    duration: kAnimationNormal,
  )..forward();

  final StateProvider<int> _navIndexProvider = StateProvider<int>((ref) => 0);

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  Future<void> _refreshAll() async {
    ref.invalidate(userProfileProvider);
    ref.invalidate(adaptiveMetricsProvider);
    ref.invalidate(recommendationsProvider);
    ref.invalidate(activeLessonProvider);
    ref.invalidate(weeklyActivityProvider);
    ref.invalidate(achievementsProvider);
    ref.invalidate(dailyChallengeProvider);
    ref.invalidate(aiInsightsProvider);
    ref.invalidate(nextTopicsProvider);
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = ref.watch(_navIndexProvider);
    final Widget body = switch (currentIndex) {
      0 => _HomeTab(onSignOut: () => _signOut(context), onRefresh: _refreshAll),
      1 => const _PlaceholderTab(title: 'Learn'),
      2 => const _PlaceholderTab(title: 'My Progress'),
      3 => const _PlaceholderTab(title: 'Achievements'),
      _ => const _PlaceholderTab(title: 'Profile'),
    };

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: SafeArea(child: body),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: _GlassNavBar(
          currentIndex: currentIndex,
          onTap: (i) => ref.read(_navIndexProvider.notifier).state = i,
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  final String title;
  const _PlaceholderTab({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$title (Coming soon)',
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(color: Colors.white70),
      ),
    );
  }
}

// ===============================
// HOME TAB & SECTIONS
// ===============================

class _HomeTab extends ConsumerWidget {
  final VoidCallback onSignOut;
  final Future<void> Function() onRefresh;
  const _HomeTab({required this.onSignOut, required this.onRefresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final activeLessonAsync = ref.watch(activeLessonProvider);

    return RefreshIndicator.adaptive(
      color: kPrimaryColor,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PersonalizedHeader(onSignOut: onSignOut),
            const SizedBox(height: 20),
            const _AdaptiveProgressSection(),
            const SizedBox(height: 20),
            const _AITutorRecommendations(),
            const SizedBox(height: 20),
            activeLessonAsync.when(
              data: (lesson) => lesson == null
                  ? const SizedBox.shrink()
                  : _ContinueLearningCard(lesson: lesson),
              loading: () => const _Skeleton(height: 140),
              error: (_, __) => const _ErrorText(),
            ),
            const SizedBox(height: 20),
            const _LearningPaceChart(),
            const SizedBox(height: 20),
            const _PersonalizedAchievements(),
            const SizedBox(height: 20),
            const _DailyChallenge(),
            const SizedBox(height: 20),
            const _AITutorInsights(),
            const SizedBox(height: 20),
            const _NextTopics(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

class _PersonalizedHeader extends ConsumerWidget {
  final VoidCallback onSignOut;
  const _PersonalizedHeader({required this.onSignOut});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, MMM d • h:mm a').format(now);

    return profileAsync.when(
      data: (profile) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${profile.name}! 👋',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            GestureDetector(
              onTap: onSignOut,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kPrimaryColor, kAccentColor],
                  ),
                ),
                child: const Icon(Icons.logout, color: Colors.white, size: 20),
              ),
            ),
          ],
        );
      },
      loading: () => const _Skeleton(height: 60),
      error: (_, __) => const _ErrorText(),
    );
  }
}

class _AdaptiveProgressSection extends ConsumerWidget {
  const _AdaptiveProgressSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adaptiveMetricsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your Learning Journey'),
        const SizedBox(height: 12),
        async.when(
          data: (m) {
            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Level',
                    valueText: m.level,
                    progress: m.level == 'Beginner'
                        ? 0.33
                        : (m.level == 'Intermediate' ? 0.66 : 1.0),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'Mastery',
                    valueText: '${(m.mastery * 100).round()}%',
                    progress: m.mastery,
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            children: const [
              Expanded(child: _Skeleton(height: 100)),
              SizedBox(width: 12),
              Expanded(child: _Skeleton(height: 100)),
            ],
          ),
          error: (_, __) => const _ErrorText(),
        ),
        const SizedBox(height: 12),
        async.when(
          data: (m) {
            return Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    label: 'Pace',
                    valueText: m.pace,
                    progress: m.pace == 'Slow' ? 0.3 : (m.pace == 'Steady' ? 0.6 : 0.9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricCard(
                    label: 'This Week',
                    valueText: _formatDuration(m.weeklyTime),
                    progress: (m.weeklyTime.inMinutes / 240).clamp(0, 1).toDouble(),
                  ),
                ),
              ],
            );
          },
          loading: () => Row(
            children: const [
              Expanded(child: _Skeleton(height: 100)),
              SizedBox(width: 12),
              Expanded(child: _Skeleton(height: 100)),
            ],
          ),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }

  static String _formatDuration(Duration d) {
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes % 60}m';
    }
    return '${d.inMinutes}m';
  }
}

class _AITutorRecommendations extends ConsumerWidget {
  const _AITutorRecommendations();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recommendationsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your AI Tutor Recommends'),
        const SizedBox(height: 12),
        async.when(
          data: (recs) {
            return SizedBox(
              height: 180,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final r = recs[i];
                  return _RecommendationCard(rec: r);
                },
              ),
            );
          },
          loading: () => const _Skeleton(height: 160),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final ActiveLesson lesson;
  const _ContinueLearningCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Continue Learning', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            lesson.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(progress: lesson.progress),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
              ),
              child: const Text('Resume'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningPaceChart extends ConsumerWidget {
  const _LearningPaceChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(weeklyActivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Weekly Activity'),
        const SizedBox(height: 12),
        async.when(
          data: (activity) {
            return GlassCard(
              child: SizedBox(
                height: 180,
                child: _WeeklyBarChart(values: activity.lessonsPerDay),
              ),
            );
          },
          loading: () => const _Skeleton(height: 200),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

class _PersonalizedAchievements extends ConsumerWidget {
  const _PersonalizedAchievements();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(achievementsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Achievements'),
        const SizedBox(height: 12),
        async.when(
          data: (achievements) {
            return SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: achievements.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final a = achievements[i];
                  return _AchievementBadge(achievement: a);
                },
              ),
            );
          },
          loading: () => const _Skeleton(height: 100),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

class _DailyChallenge extends ConsumerWidget {
  const _DailyChallenge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyChallengeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Daily Challenge'),
        const SizedBox(height: 12),
        async.when(
          data: (challenge) {
            return _GradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                      ),
                      child: const Text('Start Challenge'),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const _Skeleton(height: 140),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

class _AITutorInsights extends ConsumerWidget {
  const _AITutorInsights();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aiInsightsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('AI Insights'),
        const SizedBox(height: 12),
        async.when(
          data: (insights) {
            return Column(
              children: insights
                  .map((insight) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GlassCard(
                          child: Row(
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  insight.text,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const _Skeleton(height: 100),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

class _NextTopics extends ConsumerWidget {
  const _NextTopics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(nextTopicsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Next Topics'),
        const SizedBox(height: 12),
        async.when(
          data: (topics) {
            return Column(
              children: topics
                  .map((topic) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      topic.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${topic.difficulty} • ${topic.estimatedTime.inHours}h',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward,
                                  color: Colors.white60, size: 20),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
          loading: () => const _Skeleton(height: 100),
          error: (_, __) => const _ErrorText(),
        ),
      ],
    );
  }
}

// ===============================
// SHARED UI COMPONENTS
// ===============================

class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GradientCard extends StatelessWidget {
  final Widget child;
  const _GradientCard({required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String valueText;
  final double progress;
  const _MetricCard({
    required this.label,
    required this.valueText,
    required this.progress,
  });
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(
            valueText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 8),
          _ProgressBar(progress: progress),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
          ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Recommendation rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why this lesson?',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(rec.reason, style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rec.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              rec.reason,
              style: const TextStyle(color: Colors.white70),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                _Pill(label: 'Est: ${rec.estimatedTime.inMinutes}m'),
                const SizedBox(width: 8),
                _Pill(label: 'Match: ${(rec.difficultyMatch * 100).round()}%'),
                const Spacer(),
                SizedBox(
                  width: 120,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text('Start', style: TextStyle(color: kPrimaryColor)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<int> values;
  const _WeeklyBarChart({required this.values});
  @override
  Widget build(BuildContext context) {
    final maxVal = (values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b)).toDouble();
    final bars = values
        .map((v) => v.toDouble())
        .map((v) => v / (maxVal == 0 ? 1 : maxVal))
        .toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(7, (i) {
        final h = bars[i] * 160 + 8;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 6 ? 0 : 8),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [kPrimaryColor, kAccentColor],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text(achievement.title, style: const TextStyle(color: Colors.white)),
            content: Text(achievement.description, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: achievement.earned
              ? const LinearGradient(colors: [kPrimaryColor, kAccentColor])
              : null,
          color: achievement.earned ? null : Colors.white12,
        ),
        child: Icon(
          Icons.emoji_events,
          color: achievement.earned ? Colors.white : Colors.white30,
          size: 40,
        ),
      ),
    );
  }
}

class _ErrorText extends StatelessWidget {
  const _ErrorText();
  @override
  Widget build(BuildContext context) {
    return const Text('Something went wrong', style: TextStyle(color: Colors.redAccent));
  }
}

class _Skeleton extends StatelessWidget {
  final double height;
  const _Skeleton({required this.height});
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
    );
  }
}

class _GlassNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasNewAchievementAsync = ref.watch(achievementsProvider);
    final hasNewAchievement = hasNewAchievementAsync.maybeWhen(
      data: (list) => list.any((a) => a.earned),
      orElse: () => false,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: BottomNavigationBar(
          backgroundColor: Colors.white.withOpacity(0.06),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white60,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: onTap,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Learn'),
            const BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Progress'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.emoji_events_rounded),
                  if (hasNewAchievement)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Achievements',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
