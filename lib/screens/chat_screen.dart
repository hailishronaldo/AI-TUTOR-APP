import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/topic_model.dart';
import '../main.dart';
import 'topic_detail_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<Topic> _allTopics = [
    Topic(
      id: '1',
      title: 'Flutter Basics',
      description: 'Learn the fundamentals of Flutter development',
      icon: Icons.smartphone,
      category: 'Mobile Development',
      estimatedMinutes: 30,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '2',
      title: 'State Management',
      description: 'Master state management with Provider and Riverpod',
      icon: Icons.settings_applications,
      category: 'Mobile Development',
      estimatedMinutes: 45,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '3',
      title: 'REST APIs',
      description: 'Understanding and working with REST APIs',
      icon: Icons.cloud,
      category: 'Backend',
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '4',
      title: 'Firebase Integration',
      description: 'Integrate Firebase services in your Flutter app',
      icon: Icons.firebase,
      category: 'Backend',
      estimatedMinutes: 50,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '5',
      title: 'Custom Animations',
      description: 'Create beautiful custom animations in Flutter',
      icon: Icons.animation,
      category: 'UI/UX',
      estimatedMinutes: 35,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '6',
      title: 'Material Design',
      description: 'Implement Material Design principles',
      icon: Icons.design_services,
      category: 'UI/UX',
      estimatedMinutes: 25,
      difficulty: 'Beginner',
    ),
    Topic(
      id: '7',
      title: 'Responsive Layouts',
      description: 'Build responsive UIs for all screen sizes',
      icon: Icons.devices,
      category: 'UI/UX',
      estimatedMinutes: 30,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '8',
      title: 'Local Database',
      description: 'Work with SQLite and local storage',
      icon: Icons.storage,
      category: 'Data',
      estimatedMinutes: 40,
      difficulty: 'Intermediate',
    ),
    Topic(
      id: '9',
      title: 'Testing in Flutter',
      description: 'Write unit, widget, and integration tests',
      icon: Icons.bug_report,
      category: 'Testing',
      estimatedMinutes: 45,
      difficulty: 'Advanced',
    ),
    Topic(
      id: '10',
      title: 'App Deployment',
      description: 'Deploy your app to App Store and Play Store',
      icon: Icons.publish,
      category: 'DevOps',
      estimatedMinutes: 60,
      difficulty: 'Advanced',
    ),
  ];

  List<Topic> get _filteredTopics {
    if (_searchQuery.isEmpty) {
      return _allTopics;
    }
    return _allTopics.where((topic) {
      return topic.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          topic.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          topic.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: kDarkGradient,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildTopicsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble, color: kPrimaryColor, size: 32),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Tutor',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
              Text(
                'Choose a topic to learn',
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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

  Widget _buildTopicsList() {
    final topics = _filteredTopics;

    if (topics.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              'No topics found',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: topics.length,
      itemBuilder: (context, index) {
        return _TopicCard(
          topic: topics[index],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicDetailScreen(topic: topics[index]),
              ),
            );
          },
        );
      },
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
                                _buildChip(
                                  topic.category,
                                  Icons.category,
                                  Colors.blue.withOpacity(0.3),
                                ),
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
