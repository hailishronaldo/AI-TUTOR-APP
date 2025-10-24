# ai_tutor

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Configuration

Provide your Gemini API key at run/build time using a dart-define:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key_here
```

For release builds:

```bash
flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
flutter build ios --dart-define=GEMINI_API_KEY=your_key_here
```
