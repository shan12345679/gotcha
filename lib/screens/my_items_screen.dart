import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header_nav.dart';
import 'item_view_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  bool isLostSelected = true;
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ─── FILTER + SORT IN DART (no composite index needed) ────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    // Sort by createdAt descending in Dart to avoid Firestore composite index
    final sorted = List.of(docs);
    sorted.sort((a, b) {
      final aTs = a.data()['createdAt'];
      final bTs = b.data()['createdAt'];
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;
      if (bTs == null) return -1;
      return (bTs as Timestamp).compareTo(aTs as Timestamp);
    });

    if (searchQuery.isEmpty) return sorted;
    final query = searchQuery.toLowerCase();
    return sorted.where((doc) {
      final name = (doc['itemName'] ?? '').toString().toLowerCase();
      final location = (doc['location'] ?? '').toString().toLowerCase();
      return name.contains(query) || location.contains(query);
    }).toList();
  }

  // ─── FORMAT TIMESTAMP FOR CARD ────────────────────────────────────
  String _formatDate(dynamic ts) {
    if (ts == null) return 'No date';
    final dt = (ts as Timestamp).toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 24,
        color: Colors.black26,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's UID
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // HEADER
              const HeaderNav(),

              const SizedBox(height: 20),

              // SEARCH BAR
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: (value) => setState(() => searchQuery = value),
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

              // TOGGLE TABS
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => isLostSelected = true),
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
                      onTap: () => setState(() => isLostSelected = false),
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

              // FIRESTORE FEED — filtered by current user's UID
              Expanded(
                child: uid.isEmpty
                    ? const Center(
                  child: Text(
                    'Please log in to see your items.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  key: ValueKey(isLostSelected),
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('type',
                      isEqualTo:
                      isLostSelected ? 'lost' : 'found')
                      .where('userId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Something went wrong. Please try again.',
                          style:
                          TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      );
                    }

                    final allDocs = snapshot.data?.docs ?? [];
                    final docs = _filterDocs(allDocs);

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? 'You have no ${isLostSelected ? 'lost' : 'found'} items posted yet.'
                              : 'No results found for "$searchQuery".',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final imageUrl = data['imageUrl'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemViewScreen(report: doc),
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
                                  // THUMBNAIL
                                  ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(10),
                                    child: imageUrl.isNotEmpty
                                        ? Image.network(
                                      imageUrl,
                                      width: 58,
                                      height: 58,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) =>
                                          _thumbPlaceholder(),
                                    )
                                        : _thumbPlaceholder(),
                                  ),

                                  const SizedBox(width: 12),

                                  // INFO
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['itemName'] ?? 'Unknown')
                                              .toString()
                                              .toUpperCase(),
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
                                                Icons
                                                    .location_on_outlined,
                                                size: 12),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                data['location'] ?? '',
                                                style: const TextStyle(
                                                    fontSize: 10),
                                                overflow:
                                                TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            const Icon(
                                                Icons
                                                    .calendar_month_outlined,
                                                size: 12),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(data['date']),
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
                    );
                  },
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