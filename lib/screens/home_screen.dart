import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../main.dart'; // For constants and AuthGate
import '../providers/learning_providers.dart'; // Added import for providers
import 'chat_screen.dart';

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