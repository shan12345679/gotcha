import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import 'item_view_screen.dart';
import '../widgets/header_nav.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  bool isLostSelected = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // TOP SECTION
              const HeaderNav(),

              const SizedBox(height: 20),

              // SEARCH BAR
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Search here...',
                    hintStyle: TextStyle(fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 10),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // TOGGLE BUTTONS
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isLostSelected = true;
                        });
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isLostSelected
                              ? const Color(0xFF2E5FA7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'MY LOST ITEMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isLostSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isLostSelected = false;
                        });
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: !isLostSelected
                              ? const Color(0xFF2E5FA7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'MY FOUND ITEMS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: !isLostSelected
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ITEM CARD
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ItemViewScreen(isLost: isLostSelected),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          isLostSelected
                              ? 'images/wallet.jpg'
                              : 'images/phone.jpg',
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'BROWN WALLET',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'SPCB Room 202',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Icon(Icons.calendar_month_outlined, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'May 01, 2026',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }
}