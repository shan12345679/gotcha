import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gotcha_app/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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