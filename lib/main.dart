import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
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
        fontFamily: 'Inter',
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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () => _signOut(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: kDarkGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_filled, color: Colors.white, size: 72),
              const SizedBox(height: 16),
              Text(
                'Welcome Home! 🎉',
                style: textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This is your main app screen.',
                style: textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
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
      MaterialPageRoute(builder: (_) => const AuthScreen()),
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
        const DividerWithText(label: 'Or sign up with'),
        const SizedBox(height: 24),
        const SocialRow(),
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
              final GoogleSignInAccount? googleUser =
                  await GoogleSignIn().signIn();
              if (googleUser == null) {
                // User cancelled the picker
                if (!context.mounted) return;
                Navigator.of(context, rootNavigator: true).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Google sign-in was cancelled')),
                );
                return;
              }

              final GoogleSignInAuthentication googleAuth =
                  await googleUser.authentication;
              final credential = GoogleAuthProvider.credential(
                accessToken: googleAuth.accessToken,
                idToken: googleAuth.idToken,
              );
              await FirebaseAuth.instance.signInWithCredential(credential);
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
          icon: Icons.phone,
          label: 'Phone',
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Phone sign-in not implemented')),
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
