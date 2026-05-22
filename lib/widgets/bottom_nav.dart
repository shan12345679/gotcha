// lib/widgets/bottom_nav.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../screens/home_screen.dart';
import '../screens/report_screen.dart';
import '../screens/my_items_screen.dart';
import '../screens/profile_screen.dart';

// Global persistent subscriptions that stay alive across navigation
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalLostSub;
StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalFoundSub;

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({
    super.key,
    required this.currentIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const HomeScreen();
        break;
      case 1:
        targetScreen = const ReportScreen();
        break;
      case 2:
        targetScreen = const MyItemsScreen();
        break;
      case 3:
        targetScreen = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  static void _initializeGlobalSubscriptions() {
    // Only initialize once
    if (_globalLostSub != null && _globalFoundSub != null) {
      return;
    }

    // Start listening to lost items (GLOBAL)
    _globalLostSub = FirebaseFirestore.instance
        .collection('reports')
        .where('type', isEqualTo: 'lost')
        .where('status', isEqualTo: 'active')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen((_) {});

    // Start listening to found items (GLOBAL)
    _globalFoundSub = FirebaseFirestore.instance
        .collection('reports')
        .where('type', isEqualTo: 'found')
        .where('status', isEqualTo: 'active')
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .listen((_) {});
  }

  @override
  Widget build(BuildContext context) {
    // Initialize subscriptions if not already done
    _initializeGlobalSubscriptions();

    return Container(
      height: 75,
      decoration: BoxDecoration(
        color: AppTheme.navy,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          navItem(context, Icons.home_outlined, 'Home', 0),
          navItem(context, Icons.add_circle_outline, 'Report', 1),
          navItem(context, Icons.inventory_2_outlined, 'My Items', 2),
          navItem(context, Icons.person_outline, 'Profile', 3),
        ],
      ),
    );
  }

  Widget navItem(BuildContext context, IconData icon, String label, int index) {
    final bool active = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(context, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: active ? AppTheme.gold : Colors.white.withOpacity(0.6),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppTheme.gold : Colors.white.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}