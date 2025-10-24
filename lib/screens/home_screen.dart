import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../main.dart'; // For constants and AuthGate
import '../providers/learning_providers.dart'; // Added import for providers
import 'chat_screen.dart';
import '../models/topic_model.dart';
import 'topic_detail_screen.dart';
import '../services/visited_topics_service.dart';

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
      1 => const ChatScreen(),
      2 => const _PlaceholderTab(title: 'My Progress'),
      _ => const _PlaceholderTab(title: 'Profile'),
    };

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient, // Your gradient colors
          ),
        ),
        child: SafeArea(child: body),
      ),
      backgroundColor: Colors.transparent, // Keep this transparent so gradient shows
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
    return RefreshIndicator.adaptive(
      color: kPrimaryColor,
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // <CHANGE> Keep only the header, remove all content sections
            _PersonalizedHeader(onSignOut: onSignOut),
            const SizedBox(height: 20),
            const _AiTopicExplorer(),
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

class _AiTopicExplorer extends StatefulWidget {
  const _AiTopicExplorer();

  @override
  State<_AiTopicExplorer> createState() => _AiTopicExplorerState();
}

class _AiTopicExplorerState extends State<_AiTopicExplorer> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory; // null = All

  static const List<Topic> _allTopics = [
    Topic(
      id: '1',
      title: 'Flutter Basics',
      description: 'Learn the fundamentals of Flutter development',
      category: 'Flutter',
      icon: Icons.smartphone,
      
      estimatedMinutes: 30,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '2',
      title: 'State Management',
      description: 'Master state management with Provider and Riverpod',
      category: 'Flutter',
      icon: Icons.settings_applications,
      
      estimatedMinutes: 45,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '3',
      title: 'REST APIs',
      description: 'Understanding and working with REST APIs',
      category: 'Backend',
      icon: Icons.cloud,
      
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '4',
      title: 'Firebase Integration',
      description: 'Integrate Firebase services in your Flutter app',
      category: 'Cloud',
      icon: Icons.data_exploration_rounded,
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '5',
      title: 'Custom Animations',
      description: 'Create beautiful custom animations in Flutter',
      category: 'Flutter',
      icon: Icons.animation,
      estimatedMinutes: 35,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '6',
      title: 'Material Design',
      description: 'Implement Material Design principles',
      category: 'UI/UX',
      icon: Icons.design_services,
      
      estimatedMinutes: 25,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '7',
      title: 'Responsive Layouts',
      description: 'Build responsive UIs for all screen sizes',
      category: 'UI/UX',
      icon: Icons.devices,
      
      estimatedMinutes: 30,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '8',
      title: 'Local Database',
      description: 'Work with SQLite and local storage',
      category: 'Backend',
      icon: Icons.storage,
      
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '9',
      title: 'Testing in Flutter',
      description: 'Write unit, widget, and integration tests',
      category: 'Testing',
      icon: Icons.bug_report,
      
      estimatedMinutes: 45,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '10',
      title: 'App Deployment',
      description: 'Deploy your app to App Store and Play Store',
      category: 'DevOps',
      icon: Icons.publish,
      
      estimatedMinutes: 60,
      difficulty: 'Advanced',
    ),
    // More topics and categories
    Topic(
      id: '11',
      title: 'Dart Fundamentals',
      description: 'Syntax, types, collections, and async in Dart',
      category: 'Dart',
      icon: Icons.code,
      estimatedMinutes: 40,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '12',
      title: 'Clean Architecture',
      description: 'Layered architecture patterns for Flutter apps',
      category: 'Architecture',
      icon: Icons.account_tree,
      estimatedMinutes: 50,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '13',
      title: 'CI/CD with GitHub Actions',
      description: 'Automate build, test and deploy for Flutter',
      category: 'DevOps',
      icon: Icons.sync,
      estimatedMinutes: 55,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '14',
      title: 'Accessibility',
      description: 'Build accessible apps with a11y best practices',
      category: 'UI/UX',
      icon: Icons.accessibility,
      estimatedMinutes: 30,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '15',
      title: 'Security Basics',
      description: 'Secure storage, auth, and network in apps',
      category: 'Security',
      icon: Icons.lock,
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
  ];

  static final Map<String, Topic> _idToTopic = {
    for (final t in _allTopics) t.id: t,
  };

  List<String> get _allCategories {
    final set = <String>{ for (final t in _allTopics) t.category };
    final list = set.toList()..sort();
    return list;
  }

  List<Topic> get _filteredTopics {
    Iterable<Topic> base = _allTopics;
    if (_selectedCategory != null) {
      base = base.where((t) => t.category == _selectedCategory);
    }
    if (_searchQuery.isEmpty) {
      return base.toList();
    }
    final String q = _searchQuery.toLowerCase();
    return base.where((topic) {
      return topic.title.toLowerCase().contains(q) ||
          topic.description.toLowerCase().contains(q) ||
          topic.category.toLowerCase().contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        _buildSearchBar(context),
        _buildCategoryChips(context),
        _buildRecentlyVisited(context),
        _buildTopicsList(context),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: kPrimaryColor, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Tutor',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              Text(
                'Choose a topic to learn now',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final categories = _allCategories;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            const SizedBox(width: 4),
            _buildCategoryChip('All', _selectedCategory == null, onTap: () {
              setState(() => _selectedCategory = null);
            }),
            const SizedBox(width: 8),
            for (final c in categories) ...[
              _buildCategoryChip(c, _selectedCategory == c, onTap: () {
                setState(() => _selectedCategory = c);
              }),
              const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool selected, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kPrimaryColor : Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.category,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyVisited(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: VisitedTopicsService.getVisitedIdsOrdered(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }
        final ids = snapshot.data!;
        final List<Topic> visitedTopics = ids
            .map((id) => _idToTopic[id])
            .whereType<Topic>()
            .toList();
        if (visitedTopics.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: kPrimaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recently visited',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: Builder(
                builder: (context) {
                  final int itemCount = visitedTopics.length > 12 ? 12 : visitedTopics.length;
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: itemCount,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final topic = visitedTopics[index];
                      return _VisitedTopicTile(
                        topic: topic,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TopicDetailScreen(topic: topic),
                            ),
                          ).then((_) => setState(() {}));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopicsList(BuildContext context) {
    final topics = _filteredTopics;

    // Group by category
    final Map<String, List<Topic>> byCategory = <String, List<Topic>>{};
    for (final t in topics) {
      byCategory.putIfAbsent(t.category, () => <Topic>[]).add(t);
    }

    if (topics.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48, color: Colors.white.withOpacity(0.3)),
              const SizedBox(height: 12),
              Text(
                'No topics found',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            children: [
              const Icon(Icons.view_list, color: kPrimaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedCategory == null ? 'All categories' : _selectedCategory!,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        for (final entry in byCategory.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              entry.key,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entry.value.length,
            itemBuilder: (context, index) {
              final topic = entry.value[index];
              return _TopicCard(
                topic: topic,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TopicDetailScreen(topic: topic),
                    ),
                  ).then((_) => setState(() {}));
                },
              );
            },
          ),
        ],
      ],
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;

  const _TopicCard({required this.topic, required this.onTap});

  Color get _difficultyColor {
    switch (topic.difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [kPrimaryColor, kAccentColor],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(topic.icon, color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              topic.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topic.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 13,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const SizedBox(width: 8),
                                _buildChip(
                                  '${topic.estimatedMinutes} min',
                                  Icons.access_time,
                                  Colors.purple.withOpacity(0.3),
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  topic.difficulty,
                                  Icons.signal_cellular_alt,
                                  _difficultyColor.withOpacity(0.3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white.withOpacity(0.5),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitedTopicTile extends StatelessWidget {
  final Topic topic;
  final VoidCallback onTap;
  const _VisitedTopicTile({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(topic.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      topic.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      topic.category,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

class _GlassNavBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _GlassNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Progress'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}