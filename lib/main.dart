import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// 🌈 THEME CONSTANTS
const kPrimaryColor = Color(0xFFB366FF);
const kAccentColor = Color(0xFFFF66B2);
const kDarkGradient = [Color(0xFF1A0033), Color(0xFF2D0052), Color(0xFF1A0033)];

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
      home: const AuthScreen(),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
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
        GradientButton(label: 'Sign In', onPressed: () {}),
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
        GradientButton(label: 'Create Account', onPressed: () {}),
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
      children: const [
        SocialButton(icon: Icons.g_mobiledata, label: 'Google'),
        SizedBox(width: 16),
        SocialButton(icon: Icons.phone, label: 'Phone'),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(widget.label, style: const TextStyle(color: Colors.white)),
          ],
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
