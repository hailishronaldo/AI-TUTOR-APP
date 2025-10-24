import 'package:flutter/material.dart';

// 🌈 THEME CONSTANTS
const kPrimaryColor = Color(0xFFB366FF);
const kAccentColor = Color(0xFFFF66B2);
const kDarkGradient = [Color(0xFF1A0033), Color(0xFF2D0052), Color(0xFF1A0033)];
const onboarding_complete_v2 = 'onboarding_complete';

// 🔑 AI PROVIDER CONFIG
// Read at runtime from dart-define; keep empty default in constants
const String kGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

// ⏱️ ANIMATION DURATIONS
const kAnimationFast = Duration(milliseconds: 200);
const kAnimationNormal = Duration(milliseconds: 500);
const kAnimationSlow = Duration(milliseconds: 600);
