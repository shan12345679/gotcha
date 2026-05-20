import 'package:flutter/material.dart';
import '../widgets/header_nav.dart';
import '../widgets/bottom_nav.dart';
import 'item_view_screen_home.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLostSelected = true;
  String searchQuery = '';

  final TextEditingController searchController = TextEditingController();

  // 🔹 SAMPLE FEED DATA (replace later with real data)
  final List<Map<String, String>> lostItems = [
    {
      'title': 'BROWN WALLET',
      'location': 'SPCB Room 202',
      'date': 'May 01, 2026',
      'image': 'images/wallet.jpg',
    },
    {
      'title': 'BLACK UMBRELLA',
      'location': 'Library',
      'date': 'May 02, 2026',
      'image': 'images/wallet.jpg',
    },
  ];

  final List<Map<String, String>> foundItems = [
    {
      'title': 'CELLPHONE',
      'location': 'OLFU Main Entrance',
      'date': 'May 01, 2026',
      'image': 'images/phone.jpg',
    },
    {
      'title': 'KEYCHAIN',
      'location': 'Cafeteria',
      'date': 'May 03, 2026',
      'image': 'images/phone.jpg',
    },
  ];

  List<Map<String, String>> get filteredItems {
    final items = isLostSelected ? lostItems : foundItems;

    if (searchQuery.isEmpty) return items;

    return items.where((item) {
      final query = searchQuery.toLowerCase();
      return item['title']!.toLowerCase().contains(query) ||
          item['location']!.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // 🔹 HEADER
              const HeaderNav(),

              const SizedBox(height: 20),

              // 🔍 SEARCH BAR (REAL-TIME)
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Search here...',
                    hintStyle: TextStyle(fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 10),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // 🔁 TOGGLE TABS
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
                            'LOST ITEMS',
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
                            'FOUND ITEMS',
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

              // 📃 FEED LIST / EMPTY STATE
              Expanded(
                child: items.isEmpty
                    ? const Center(
                  child: Text(
                    'No results available for this search',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                )
                    : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemViewScreenHome(
                                isLost: isLostSelected,
                              ),
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
                                  item['image']!,
                                  width: 58,
                                  height: 58,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title']!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.location_on_outlined,
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['location']!,
                                          style: const TextStyle(
                                              fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            size: 12),
                                        const SizedBox(width: 4),
                                        Text(
                                          item['date']!,
                                          style: const TextStyle(
                                              fontSize: 10),
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
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔽 BOTTOM NAV
      bottomNavigationBar: const BottomNav(currentIndex: 0),
    );
  }
}