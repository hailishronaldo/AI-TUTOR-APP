import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  print('SharedPreferences cleared!');
}
