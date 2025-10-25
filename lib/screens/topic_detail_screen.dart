import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/topic_model.dart';
import '../models/quiz_model.dart';
import '../services/ai_service.dart';
import '../services/visited_topics_service.dart';
import '../services/supabase_service.dart';
import '../main.dart';
import 'quiz_screen.dart';

class TopicDetailScreen extends StatefulWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  bool _isLoading = false;
  AITutorial? _tutorial;
  String? _error;
  int _currentStepIndex = 0;

  void _showQuiz() async {
    if (_tutorial == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );

    try {
      final quiz = await aiService.generateQuiz(widget.topic, _tutorial!.summary);
      if (!mounted) return;
      Navigator.pop(context);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => QuizScreen(
            quiz: quiz,
            topicTitle: widget.topic.title,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate quiz: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndGenerateTutorial();
    _recordVisit();
  }

  Future<void> _recordVisit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await supabaseService.recordTopicVisit(user.uid, widget.topic.id);
    }
    VisitedTopicsService.recordVisit(widget.topic.id);
  }

  Future<void> _checkAndGenerateTutorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final cachedData = await supabaseService.getTopicDetails(user.uid, widget.topic.id);

        if (cachedData != null) {
          final steps = (cachedData['steps'] as List)
              .map((step) => TutorialStep.fromJson(step as Map<String, dynamic>))
              .toList();

          setState(() {
            _tutorial = AITutorial(
              topicId: widget.topic.id,
              topicTitle: widget.topic.title,
              summary: cachedData['summary'] as String,
              steps: steps,
              generatedAt: DateTime.parse(cachedData['created_at'] as String),
            );
            _isLoading = false;
          });
          return;
        }
      }

      await _generateTutorial();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _generateTutorial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tutorial = await aiService.generateTutorial(widget.topic);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await supabaseService.saveTopicDetails(
          userId: user.uid,
          topicId: widget.topic.id,
          topicTitle: widget.topic.title,
          summary: tutorial.summary,
          steps: tutorial.steps.map((step) => step.toJson()).toList(),
        );
      }

      setState(() {
        _tutorial = tutorial;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // Removed navigation to API config; no longer needed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
              _buildAppBar(),
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [kPrimaryColor, kAccentColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(widget.topic.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.topic.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return _buildErrorState();
    }

    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_tutorial == null) {
      return _buildEmptyState();
    }

    return _buildTutorialContent();
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateTutorial,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: kPrimaryColor),
          const SizedBox(height: 16),
          Text(
            'Generating your tutorial...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        'No tutorial available',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
    );
  }

  Widget _buildTutorialContent() {
    return Column(
      children: [
        if (_tutorial!.steps.length > 1) _buildStepIndicator(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildCurrentStep(),
              ],
            ),
          ),
        ),
        if (_tutorial!.steps.length > 1) _buildNavigationButtons(),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: List.generate(_tutorial!.steps.length, (index) {
          final isCompleted = index < _currentStepIndex;
          final isCurrent = index == _currentStepIndex;

          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < _tutorial!.steps.length - 1 ? 8 : 0),
              decoration: BoxDecoration(
                color: isCompleted || isCurrent
                    ? kPrimaryColor
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb, color: kPrimaryColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'What you\'ll learn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _tutorial!.summary,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    final step = _tutorial!.steps[_currentStepIndex];

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [kPrimaryColor, kAccentColor],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Step ${step.stepNumber}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                step.content,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  height: 1.6,
                ),
              ),
              if (step.codeExample != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.code, color: kPrimaryColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Code Example',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        step.codeExample!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (step.explanation != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kPrimaryColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: kPrimaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.explanation!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (_currentStepIndex > 0)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStepIndex--;
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Previous'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentStepIndex > 0 && _currentStepIndex < _tutorial!.steps.length - 1)
            const SizedBox(width: 12),
          if (_currentStepIndex < _tutorial!.steps.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _currentStepIndex++;
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          if (_currentStepIndex == _tutorial!.steps.length - 1)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showQuiz(),
                icon: const Icon(Icons.quiz),
                label: const Text('Take Quiz'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
