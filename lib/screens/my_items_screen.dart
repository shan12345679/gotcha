// lib/screens/my_items_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header_nav.dart';
import '../providers/filter_state.dart';
import 'item_view_screen.dart';
import 'TrashScreen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const HeaderNav(),
                  const SizedBox(height: 22),
                  _buildSearchBar(context),
                  const SizedBox(height: 14),
                  _buildToggleTabs(context),
                  const SizedBox(height: 18),
                  Expanded(
                    child: uid.isEmpty
                        ? const Center(child: Text('Please log in', style: TextStyle(color: Colors.white54)))
                        : _buildStreamBuilder(context, uid),
                  ),
                ],
              ),
            ),
          ),
          // Trash FAB
          if (uid.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 20,
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('reports')
                    .where('userId', isEqualTo: uid)
                    .where('isDeleted', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  final deletedCount = snapshot.data?.docs.length ?? 0;
                  if (deletedCount == 0) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen()));
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.gold,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: Stack(
                        children: [
                          const Center(child: Icon(Icons.delete_outline, size: 26, color: AppTheme.navy)),
                          if (deletedCount > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: AppTheme.navy, width: 2)),
                                child: Center(
                                  child: Text(
                                    deletedCount > 9 ? '9+' : deletedCount.toString(),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 2),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final filterState = context.read<FilterState>();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: filterState.searchController,
        onChanged: (v) => filterState.setSearchQuery(v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search your items...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildToggleTabs(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Consumer<FilterState>(
        builder: (context, filterState, _) {
          return Row(
            children: [
              Expanded(
                child: _tabButton('MY LOST ITEMS', filterState.isLostSelected, () {
                  filterState.setLostSelected(true);
                }),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _tabButton('MY FOUND ITEMS', !filterState.isLostSelected, () {
                  filterState.setLostSelected(false);
                }),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppTheme.navy : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreamBuilder(BuildContext context, String uid) {
    return Consumer<FilterState>(
      builder: (context, filterState, _) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          key: ValueKey(filterState.isLostSelected),
          stream: FirebaseFirestore.instance
              .collection('reports')
              .where('type', isEqualTo: filterState.isLostSelected ? 'lost' : 'found')
              .where('userId', isEqualTo: uid)
              .where('isDeleted', isEqualTo: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.gold));
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading items', style: TextStyle(color: Colors.white54)));
            }
            final docs = _filterDocs(snapshot.data?.docs ?? [], filterState.searchQuery);
            if (docs.isEmpty) {
              return Center(
                child: Text(
                  filterState.searchQuery.isEmpty
                      ? 'No ${filterState.isLostSelected ? 'lost' : 'found'} items yet.'
                      : 'No results for "${filterState.searchQuery}"',
                  style: const TextStyle(color: Colors.white54),
                ),
              );
            }
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();
                final imageUrl = data['imageUrl'] ?? '';
                final docId = doc.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemViewScreen(report: doc),
                        ),
                      );
                    },
                    child: Card(
                      color: AppTheme.navyLight.withOpacity(0.7),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Hero(
                              tag: 'image_$docId',
                              child: _buildThumbnail(imageUrl),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (data['itemName'] ?? 'Unknown').toString().toUpperCase(),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(children: [
                                    const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.gold),
                                    const SizedBox(width: 4),
                                    Expanded(child: Text(data['location'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white70))),
                                  ]),
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    const Icon(Icons.calendar_month_outlined, size: 12, color: AppTheme.gold),
                                    const SizedBox(width: 4),
                                    Text(_formatDate(data['date']), style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, String searchQuery) {
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

  String _formatDate(dynamic ts) {
    if (ts == null) return 'No date';
    final dt = (ts as Timestamp).toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  // ✨ White border + shadow thumbnail (matches HomeScreen & TrashScreen)
  Widget _buildThumbnail(String imageUrl, {double size = 58, double radius = 12}) {
    Widget imageWidget;

    if (imageUrl.isEmpty) {
      imageWidget = _thumbPlaceholder(size: size, radius: radius);
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(bytes, width: size, height: size, fit: BoxFit.cover),
        );
      } catch (_) {
        imageWidget = _thumbPlaceholder(size: size, radius: radius);
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _thumbPlaceholder(size: size, radius: radius),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 1.8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
          BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _thumbPlaceholder({double size = 58, double radius = 12}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade800,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
    ),
    child: const Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.white38),
  );
}