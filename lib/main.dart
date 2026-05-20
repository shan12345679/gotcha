import 'package:flutter/material.dart';
import 'package:gotcha_app/screens/splash_screen.dart';

void main() {
  runApp(const GotchaApp());
}

class GotchaApp extends StatelessWidget {
  const GotchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gotcha',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A6BB5),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFD6E4F7),
      ),
      home: const SplashScreen(),
    );
  }
}