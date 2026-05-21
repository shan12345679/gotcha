import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Track deleted items for undo
  Map<String, Map<String, dynamic>> _deletedItems = {};

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ─── FILTER + SORT IN DART ────────────────────────────────────
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterDocs(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    // Sort by createdAt descending
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

  // ─── RESTORE ITEM (COMPLETELY SILENT) ────────────────────────────────────
  Future<void> _restoreItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(docId)
          .update({'isDeleted': false});
    } catch (e) {
      debugPrint('Error restoring item: $e');
    }
  }

  // ─── PERMANENTLY DELETE ITEM (COMPLETELY SILENT) ────────────────────────────────────
  Future<void> _deleteItemPermanently(String docId, String itemName) async {
    try {
      // Store deleted item data for undo
      final docSnapshot = await FirebaseFirestore.instance
          .collection('reports')
          .doc(docId)
          .get();

      _deletedItems[docId] = docSnapshot.data() ?? {};

      // Delete the document
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(docId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting item: $e');
    }
  }

  // ─── UNDO DELETE (COMPLETELY SILENT) ────────────────────────────────────
  Future<void> _undoDelete(String docId) async {
    try {
      if (_deletedItems.containsKey(docId)) {
        await FirebaseFirestore.instance
            .collection('reports')
            .doc(docId)
            .set(_deletedItems[docId]!);

        _deletedItems.remove(docId);
      }
    } catch (e) {
      debugPrint('Error undoing delete: $e');
    }
  }

  // ─── CONFIRM DELETE DIALOG ────────────────────────────────────
  void _showDeleteConfirmation(String docId, String itemName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Permanently?'),
        content: Text(
          'Permanently delete "$itemName"? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteItemPermanently(docId, itemName);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              const SizedBox(height: 24),

              // HEADER WITH BACK BUTTON
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // BACK BUTTON
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // CENTER: TITLE
                  const Expanded(
                    child: Center(
                      child: Text(
                        'TRASH',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),

                  // RIGHT: SPACER FOR ALIGNMENT
                  SizedBox(width: 40),
                ],
              ),

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
                    hintText: 'Search trash...',
                    hintStyle: TextStyle(fontSize: 11),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.only(top: 10),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // TRASH ITEMS LIST
              Expanded(
                child: uid.isEmpty
                    ? const Center(
                  child: Text(
                    'Please log in to view trash.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                )
                    : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('reports')
                      .where('userId', isEqualTo: uid)
                      .where('isDeleted', isEqualTo: true)
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
                              ? 'Your trash is empty.'
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
                        final docId = doc.id;
                        final itemName = data['itemName'] ?? 'Unknown';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
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
                                        itemName.toString().toUpperCase(),
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

                                const SizedBox(width: 8),

                                // ACTION BUTTONS
                                Column(
                                  children: [
                                    // RESTORE BUTTON
                                    GestureDetector(
                                      onTap: () =>
                                          _restoreItem(docId),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.restore,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    // DELETE BUTTON
                                    GestureDetector(
                                      onTap: () =>
                                          _showDeleteConfirmation(
                                              docId, itemName),
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                          BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.delete_forever,
                                          size: 18,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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