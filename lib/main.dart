import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gotcha_app/screens/splash_screen.dart';
import 'package:gotcha_app/theme/app_theme.dart';
import 'package:gotcha_app/providers/filter_state.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const GotchaApp());
}

class GotchaApp extends StatelessWidget {
  const GotchaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 🔑 FilterState for HomeScreen & MyItemsScreen
        // Manages search query and lost/found tab selection
        ChangeNotifierProvider(create: (_) => FilterState()),
      ],
      child: MaterialApp(
        title: 'Gotcha',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}