import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const RunwayIQApp());

}

class RunwayIQApp extends StatelessWidget {
  const RunwayIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunwayIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
