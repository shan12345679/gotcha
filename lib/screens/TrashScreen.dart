import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header_nav.dart';

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  String searchQuery = '';
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  Future<void> _restoreItem(String docId) async {
    await FirebaseFirestore.instance.collection('reports').doc(docId).update({'isDeleted': false});
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item restored'),
          backgroundColor: AppTheme.gold,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

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

  Widget _thumbPlaceholder({double size = 58, double radius = 12}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: const Icon(Icons.image_not_supported_outlined, size: 24, color: Colors.white38),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (v) => setState(() => searchQuery = v),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search trash...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, color: AppTheme.gold),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const HeaderNav(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18, color: AppTheme.gold),
                      SizedBox(width: 6),
                      Text('Back', style: TextStyle(fontSize: 12, color: AppTheme.gold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TRASH',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSearchBar(),
              const SizedBox(height: 20),
              Expanded(
                child: uid.isEmpty
                    ? const Center(child: Text('Please log in', style: TextStyle(color: Colors.white54)))
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('userId', isEqualTo: uid)
                      .where('isDeleted', isEqualTo: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.gold));
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Error', style: TextStyle(color: Colors.white54)));
                    }
                    final docs = _filterDocs(snapshot.data?.docs ?? []);
                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_sweep_outlined, size: 64, color: Colors.white.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              searchQuery.isEmpty ? 'Trash is empty' : 'No results for "$searchQuery"',
                              style: const TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data();
                        final imageUrl = data['imageUrl'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Card(
                            color: AppTheme.navyLight.withOpacity(0.7),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  _buildThumbnail(imageUrl),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['itemName'] ?? 'Unknown').toString().toUpperCase(),
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.gold),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                data['location'] ?? '',
                                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.calendar_month_outlined, size: 12, color: AppTheme.gold),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(data['date']),
                                              style: const TextStyle(fontSize: 11, color: Colors.white70),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  OutlinedButton(
                                    onPressed: () => _restoreItem(doc.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppTheme.gold,
                                      side: BorderSide(color: AppTheme.gold.withOpacity(0.6), width: 1.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.restore, size: 18),
                                        SizedBox(width: 6),
                                        Text('Restore', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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