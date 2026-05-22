// lib/widgets/custom/gradient_background.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.navy, AppTheme.navyLight], // ✅ fixed
        ),
      ),
      child: child,
    );
  }
}