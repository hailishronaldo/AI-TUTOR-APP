import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ProviderScope(child: const MyApp()));
}

// 🌈 THEME CONSTANTS
const kPrimaryColor = Color(0xFFB366FF);
const kAccentColor = Color(0xFFFF66B2);
const kDarkGradient = [Color(0xFF1A0033), Color(0xFF2D0052), Color(0xFF1A0033)];
const kOnboardingCompleteKey = 'onboarding_complete';

const kAnimationFast = Duration(milliseconds: 200);
const kAnimationNormal = Duration(milliseconds: 500);
const kAnimationSlow = Duration(milliseconds: 600);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smooth Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: kPrimaryColor,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const LaunchDecider(),
    );
  }
}

class LaunchDecider extends StatelessWidget {
  const LaunchDecider({super.key});

  Future<Widget> _getInitialScreen() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isOnboardingComplete =
        prefs.getBool(kOnboardingCompleteKey) ?? false;
    if (!isOnboardingComplete) {
      return const OnboardingScreen();
    }
    return const AuthGate();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _getInitialScreen(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Splash();
        }
        return snapshot.data!;
      },
    );
  }
}

// 🔒 AUTH GATE: Listens to FirebaseAuth to decide screen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }
        final User? user = snapshot.data;
        if (user == null) {
          return const AuthScreen();
        }
        return const HomeScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

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
      child: const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      ),
    );
  }
}

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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

// 🧭 ONBOARDING
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageModel> _pages = const [
    _OnboardingPageModel(
      icon: Icons.psychology_alt,
      title: 'AI Tutor for Everyone',
      subtitle: 'Personalized learning aligned with SDG 4: Quality Education.',
    ),
    _OnboardingPageModel(
      icon: Icons.school,
      title: 'Master Concepts Faster',
      subtitle: 'Step-by-step explanations, quizzes, and real-time feedback.',
    ),
    _OnboardingPageModel(
      icon: Icons.auto_awesome,
      title: 'Learn Anywhere, Anytime',
      subtitle: 'Study on your schedule with progress tracking and insights.',
    ),
  ];

  Future<void> _completeOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompleteKey, true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  void _goNext() {
    if (_currentPage == _pages.length - 1) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: kAnimationNormal,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bool isLast = _currentPage == _pages.length - 1;

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final page = _pages[index];
                      return _OnboardingPage(page: page);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                _DotsIndicator(
                  count: _pages.length,
                  index: _currentPage,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: isLast ? 'Get Started' : 'Next',
                  onPressed: _goNext,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageModel {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingPageModel({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingPageModel page;
  const _OnboardingPage({required this.page});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(colors: [kPrimaryColor, kAccentColor]),
          ),
          child: Icon(page.icon, color: Colors.white, size: 64),
        ),
        const SizedBox(height: 32),
        Text(
          page.title,
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          page.subtitle,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final bool active = i == index;
        return AnimatedContainer(
          duration: kAnimationFast,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? kPrimaryColor : Colors.white24,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool isSignIn = true;
  late final AnimationController _fadeController = AnimationController(
    vsync: this,
    duration: kAnimationSlow,
  )..forward();

  late final AnimationController _slideController = AnimationController(
    vsync: this,
    duration: kAnimationNormal,
  )..forward();

  late final Animation<double> _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeOut,
  );

  late final Animation<Offset> _slideAnimation = Tween<Offset>(
    begin: const Offset(0.3, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

  void _toggleAuthMode() async {
    await _fadeController.reverse();
    setState(() => isSignIn = !isSignIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const AuthLogo(),
                      const SizedBox(height: 32),
                      Text(
                        isSignIn ? 'Welcome Back' : 'Create Account',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSignIn
                            ? 'Sign in to your account to continue'
                            : 'Join us and start your journey',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 40),
                      AnimatedSwitcher(
                        duration: kAnimationNormal,
                        child: isSignIn
                            ? const SignInForm(key: ValueKey('SignIn'))
                            : const SignUpForm(key: ValueKey('SignUp')),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            isSignIn
                                ? "Don't have an account? "
                                : "Already have an account? ",
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          GestureDetector(
                            onTap: _toggleAuthMode,
                            child: Text(
                              isSignIn ? 'Sign Up' : 'Sign In',
                              style: const TextStyle(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: TextButton(
            onPressed: () async {
              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();
              final bool isOnboardingComplete =
                  prefs.getBool(kOnboardingCompleteKey) ?? false;
              if (!isOnboardingComplete) {
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  (route) => false,
                );
              } else {
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Skip for now',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}

// 🔐 AUTH LOGO
class AuthLogo extends StatelessWidget {
  const AuthLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      height: 90,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [kPrimaryColor, kAccentColor]),
      ),
      child: const Icon(Icons.lock_outline, color: Colors.white, size: 42),
    );
  }
}

// ✉️ SIGN IN FORM
class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassTextField(
          controller: _emailController,
          hintText: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _passwordController,
          hintText: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'Forgot Password?',
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 28),
        GradientButton(
          label: 'Sign In',
          onPressed: _isLoading
              ? () {}
              : () async {
                  final String email = _emailController.text.trim();
                  final String password = _passwordController.text.trim();
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email and password required')),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Sign-in failed')),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unexpected error')),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
        ),
        const SizedBox(height: 24),
        const DividerWithText(label: 'Or continue with'),
        const SizedBox(height: 24),
        const SocialRow(),
      ],
    );
  }
}

// 🧾 SIGN UP FORM
class SignUpForm extends StatefulWidget {
  const SignUpForm({super.key});

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool _obscurePassword = true;
  bool _agreeToTerms = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GlassTextField(
          controller: _nameController,
          hintText: 'Full Name',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _emailController,
          hintText: 'Email Address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        GlassTextField(
          controller: _passwordController,
          hintText: 'Password',
          icon: Icons.lock_outline,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
              fillColor: MaterialStateProperty.all(kPrimaryColor),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Create Account',
          onPressed: _isLoading
              ? () {}
              : () async {
                  final String name = _nameController.text.trim();
                  final String email = _emailController.text.trim();
                  final String password = _passwordController.text.trim();
                  if (!_agreeToTerms) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please agree to the terms')),
                    );
                    return;
                  }
                  if (email.isEmpty || password.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Email and password required')),
                    );
                    return;
                  }
                  setState(() => _isLoading = true);
                  try {
                    final credential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: email,
                      password: password,
                    );
                    if (credential.user != null && name.isNotEmpty) {
                      await credential.user!.updateDisplayName(name);
                    }
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.message ?? 'Sign-up failed')),
                    );
                  } catch (_) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Unexpected error')),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
        ),
        const SizedBox(height: 24),
        const DividerWithText(label: 'Or continue with'),
        const SizedBox(height: 24),
        const SocialRow(),
      const SizedBox(height: 20),
      ],
    );
  }
}

// ✨ GLASS INPUT
class GlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;

  const GlassTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24, width: 1.2),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          prefixIcon: Icon(icon, color: Colors.white60),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

// 🟣 GRADIENT BUTTON
class GradientButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: kAnimationFast,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(
      begin: 1,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: scale,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [kPrimaryColor, kAccentColor],
            ),
            boxShadow: [
              BoxShadow(
                color: kPrimaryColor.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 🌐 SOCIAL BUTTONS ROW
class SocialRow extends StatelessWidget {
  const SocialRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SocialButton(
          icon: Icons.g_mobiledata,
          label: 'Google',
          onPressed: () async {
            if (!context.mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(
                child: CircularProgressIndicator(color: kPrimaryColor),
              ),
            );
            try {
              final googleProvider = GoogleAuthProvider();
              if (kIsWeb) {
                await FirebaseAuth.instance.signInWithPopup(googleProvider);
              } else {
                await FirebaseAuth.instance.signInWithProvider(googleProvider);
              }
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            } on FirebaseAuthException catch (e) {
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e.message ?? 'Google sign-in failed')),
              );
            } catch (_) {
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Google sign-in error')),
              );
            }
          },
        ),
        const SizedBox(width: 16),
        SocialButton(
          icon: Icons.apple_outlined,
          label: 'Apple',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Apple sign-in not implemented')),
            );
          },
        ),
      ],
    );
  }
}

class SocialButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const SocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  State<SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<SocialButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: kAnimationFast,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? kPrimaryColor : Colors.white24,
            width: 1.2,
          ),
          color: _isHovered
              ? kPrimaryColor.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(widget.label, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔸 DIVIDER TEXT
class DividerWithText extends StatelessWidget {
  final String label;

  const DividerWithText({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Colors.white24)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        const Expanded(child: Divider(color: Colors.white24)),
      ],
    );
  }
}

// ===============================
// DATA MODELS & REPOSITORY (Mock)
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

class LearningRepository {
  Future<UserProfile> fetchUserProfile() async {
    final String fallbackName = FirebaseAuth.instance.currentUser?.displayName ?? 'Learner';
    return Future<UserProfile>.delayed(
      const Duration(milliseconds: 400),
      () => UserProfile(
        name: fallbackName,
        avatarUrl:
            'https://api.dicebear.com/8.x/identicon/svg?seed=${Uri.encodeComponent(fallbackName)}',
        streakDays: 7,
        hasActiveLesson: true,
      ),
    );
  }

  Future<AdaptiveMetrics> fetchAdaptiveMetrics() async {
    return Future<AdaptiveMetrics>.delayed(
      const Duration(milliseconds: 380),
      () => const AdaptiveMetrics(
        level: 'Intermediate',
        mastery: 0.76,
        pace: 'Steady',
        weeklyTime: Duration(hours: 3, minutes: 20),
      ),
    );
  }

  Future<List<Recommendation>> fetchRecommendations() async {
    return Future<List<Recommendation>>.delayed(
      const Duration(milliseconds: 420),
      () => const [
        Recommendation(
          id: 'r1',
          title: 'Fractions Mastery',
          reason: 'Perfect for your pace and performance',
          estimatedTime: Duration(minutes: 18),
          difficultyMatch: 0.9,
          topic: 'Math',
        ),
        Recommendation(
          id: 'r2',
          title: 'Photosynthesis Basics',
          reason: 'Builds on your strengths in visuals',
          estimatedTime: Duration(minutes: 22),
          difficultyMatch: 0.8,
          topic: 'Biology',
        ),
        Recommendation(
          id: 'r3',
          title: 'Grammar: Complex Sentences',
          reason: 'Targets a small knowledge gap',
          estimatedTime: Duration(minutes: 15),
          difficultyMatch: 0.85,
          topic: 'English',
        ),
      ],
    );
  }

  Future<ActiveLesson?> fetchActiveLesson() async {
    // Return an active lesson to show the Continue card
    return Future<ActiveLesson?>.delayed(
      const Duration(milliseconds: 360),
      () => const ActiveLesson(
        id: 'L123',
        title: 'Fractions: Numerators & Denominators',
        topic: 'Math',
        progress: 0.42,
        timeSpent: Duration(minutes: 26),
      ),
    );
  }

  Future<WeeklyActivity> fetchWeeklyActivity() async {
    return Future<WeeklyActivity>.delayed(
      const Duration(milliseconds: 410),
      () => const WeeklyActivity(
        lessonsPerDay: [0, 2, 1, 3, 2, 1, 2],
        avgTimePerLessonMinutes: [0, 14, 16, 18, 15, 17, 16],
        paceTrend: 'accelerating',
        fasterVsLastWeek: 0.20,
      ),
    );
  }

  Future<List<Achievement>> fetchAchievements() async {
    return Future<List<Achievement>>.delayed(
      const Duration(milliseconds: 300),
      () => const [
        Achievement(
          id: 'a1',
          title: 'First Lesson Master',
          description: 'Completed first lesson with 90%+ score',
          earned: true,
          icon: Icons.emoji_events_outlined,
        ),
        Achievement(
          id: 'a2',
          title: 'Pace Setter',
          description: 'Maintained a 7-day streak',
          earned: true,
          icon: Icons.speed,
        ),
        Achievement(
          id: 'a3',
          title: 'Topic Expert',
          description: 'Mastered entire topic',
          earned: false,
          icon: Icons.auto_awesome,
        ),
        Achievement(
          id: 'a4',
          title: 'Speed Learner',
          description: 'Completed lessons faster than average',
          earned: false,
          icon: Icons.flash_on,
        ),
      ],
    );
  }

  Future<DailyChallenge> fetchDailyChallenge() async {
    return Future<DailyChallenge>.delayed(
      const Duration(milliseconds: 350),
      () => const DailyChallenge(
        id: 'c1',
        title: "Today's Challenge (Personalized for You)",
        description: 'Complete 2 lessons at your pace today to earn XP',
        difficulty: 'Matched to your pace',
        estimatedTime: Duration(minutes: 30),
        rewardXp: 50,
      ),
    );
  }

  Future<List<Insight>> fetchInsights() async {
    return Future<List<Insight>>.delayed(
      const Duration(milliseconds: 280),
      () => const [
        Insight(id: 'i1', text: 'You excel at visual learning. Try more diagram-based lessons.'),
        Insight(id: 'i2', text: "You're progressing faster in Math. Consider advanced topics."),
        Insight(id: 'i3', text: "Take a break! You've been learning for 2 hours."),
      ],
    );
  }

  Future<List<NextTopic>> fetchNextTopics() async {
    return Future<List<NextTopic>>.delayed(
      const Duration(milliseconds: 390),
      () => const [
        NextTopic(
          id: 't1',
          title: 'Algebra Foundations',
          prerequisiteCompletion: 80,
          estimatedTime: Duration(hours: 3),
          difficulty: 'Intermediate',
        ),
        NextTopic(
          id: 't2',
          title: 'Human Anatomy Basics',
          prerequisiteCompletion: 60,
          estimatedTime: Duration(hours: 2, minutes: 30),
          difficulty: 'Beginner',
        ),
        NextTopic(
          id: 't3',
          title: 'Essay Writing Techniques',
          prerequisiteCompletion: 40,
          estimatedTime: Duration(hours: 2),
          difficulty: 'Beginner',
        ),
      ],
    );
  }
}

// Providers
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

// ===============================
// HOME TAB CONTENT
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

// ===============================
// SECTIONS
// ===============================

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
        final String greetingName = profile.name.isEmpty ? 'Learner' : profile.name;
        String sub;
        if (profile.streakDays > 0) {
          sub = "You're on a ${profile.streakDays}-day learning streak! Keep it up!";
        } else if (profile.hasActiveLesson) {
          sub = 'Ready to continue where you left off?';
        } else {
          sub = "Let's start something new today!";
        }

        return Stack(
          children: [
            Container(
              height: 140,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2E0A4A), Color(0xFF1D0838)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, $greetingName!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          sub,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.schedule, size: 18, color: Colors.white60),
                            const SizedBox(width: 6),
                            Text(dateStr, style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Semantics(
                    label: 'User profile avatar',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        width: 56,
                        height: 56,
                        color: Colors.white10,
                        child: Image.network(
                          profile.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Sign out',
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const _Skeleton(height: 120),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Continue Learning'),
        const SizedBox(height: 12),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [kPrimaryColor, kAccentColor]),
                ),
                child: const Icon(Icons.play_circle_fill, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'You were learning about ${lesson.topic}. Ready to continue?',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    _ProgressBar(progress: lesson.progress),
                    const SizedBox(height: 6),
                    Text(
                      'Time spent: ${lesson.timeSpent.inMinutes}m',
                      style:
                          Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                label: 'Resume Lesson',
                child: SizedBox(
                  width: 140,
                  height: 48,
                  child: GradientButton(
                    label: 'Resume',
                    onPressed: () {
                      Navigator.of(context).push(_fadeRoute(
                        _LessonDetailPage(title: lesson.title, topic: lesson.topic),
                      ));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        const _SectionTitle('Your Learning Pattern'),
        const SizedBox(height: 12),
        async.when(
          data: (w) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 200,
                    child: _WeeklyBarChart(values: w.lessonsPerDay),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      w.paceTrend == 'accelerating'
                          ? Icons.trending_up
                          : (w.paceTrend == 'slowing down'
                              ? Icons.trending_down
                              : Icons.trending_flat),
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "You're learning ${(w.fasterVsLastWeek * 100).round()}% faster than last week!",
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => const _Skeleton(height: 220),
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
        const _SectionTitle('Achievements Unlocked'),
        const SizedBox(height: 12),
        async.when(
          data: (ach) {
            return SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: ach.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _AchievementCard(a: ach[i]),
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
        const _SectionTitle("Today's Challenge"),
        const SizedBox(height: 12),
        async.when(
          data: (c) {
            return _GradientCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.stars_rounded, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(c.description,
                            style: const TextStyle(color: Colors.white70)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _Pill(label: 'Difficulty: ${c.difficulty}'),
                            _Pill(label: 'Time: ${c.estimatedTime.inMinutes}m'),
                            _Pill(label: 'Reward: ${c.rewardXp} XP'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    height: 48,
                    child: GradientButton(
                      label: 'Start',
                      onPressed: () {
                        Navigator.of(context).push(_fadeRoute(
                          _ChallengePage(challenge: c),
                        ));
                      },
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const _Skeleton(height: 120),
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
        const _SectionTitle("AI Tutor's Insights"),
        const SizedBox(height: 12),
        async.when(
          data: (ins) {
            return Row(
              children: ins
                  .map(
                    (i) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GlassCard(
                          borderRadius: 16,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline,
                                  color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(i.text,
                                    style: const TextStyle(color: Colors.white70)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
          loading: () => const _Skeleton(height: 80),
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
        const _SectionTitle("What's Next?"),
        const SizedBox(height: 12),
        async.when(
          data: (topics) {
            return SizedBox(
              height: 160,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: topics.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _TopicCard(topic: topics[i]),
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

// ===============================
// WIDGETS (Cards, Helpers, Chart)
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
                  child: GradientButton(
                    label: 'Start',
                    onPressed: () {
                      Navigator.of(context).push(_fadeRoute(
                          _LessonDetailPage(title: rec.title, topic: rec.topic)));
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement a;
  const _AchievementCard({required this.a});
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: a.title,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(a.icon, color: a.earned ? Colors.amber : Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(
              a.title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final NextTopic topic;
  const _TopicCard({required this.topic});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            _ProgressBar(progress: topic.prerequisiteCompletion / 100),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(label: 'Prereq: ${topic.prerequisiteCompletion}%'),
                _Pill(label: 'Time: ${topic.estimatedTime.inHours}h'),
                _Pill(label: topic.difficulty),
              ],
            )
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
  final List<int> values; // 7 values
  const _WeeklyBarChart({required this.values});
  @override
  Widget build(BuildContext context) {
    // Minimal custom bar chart without fl_chart to avoid runtime dependency during dev env
    // Replace with fl_chart BarChart when running on device.
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
                gradient: const LinearGradient(colors: [kPrimaryColor, kAccentColor], begin: Alignment.bottomCenter, end: Alignment.topCenter),
              ),
            ),
          ),
        );
      }),
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

// ===============================
// Navigation targets
// ===============================

PageRoute _fadeRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, anim, __, child) {
      return FadeTransition(opacity: anim, child: child);
    },
    transitionDuration: kAnimationNormal,
  );
}

class _LessonDetailPage extends StatelessWidget {
  final String title;
  final String topic;
  const _LessonDetailPage({required this.title, required this.topic});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: Center(
          child: Text('AI Tutor intro for $topic',
              style: Theme.of(context).textTheme.titleLarge),
        ),
      ),
    );
  }
}

class _ChallengePage extends StatelessWidget {
  final DailyChallenge challenge;
  const _ChallengePage({required this.challenge});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Today's Challenge")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: Center(
          child: Text(
            '${challenge.title}\nReward: ${challenge.rewardXp} XP',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
      ),
    );
  }
}
