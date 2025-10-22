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

import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'constants/app_constants.dart';

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
    // Allow guest access after onboarding without requiring sign-in
    return const HomeScreen();
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

// Keep all the remaining code from your original main.dart file
