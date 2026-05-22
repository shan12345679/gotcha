// lib/widgets/custom/custom_button.dart
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final bool isLoading;
  final bool fullWidth;

  const CustomButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.backgroundColor = AppTheme.gold, // gold by default
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox(
          width: 18, height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy))
          : Icon(icon, size: 18, color: AppTheme.navy),
      label: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.navy),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: AppTheme.navy,
        disabledBackgroundColor: backgroundColor.withOpacity(0.5),
        minimumSize: fullWidth ? const Size(double.infinity, 48) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );

    if (fullWidth) return button;
    return SizedBox(width: 140, child: button);
  }
}