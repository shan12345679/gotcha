import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header_nav.dart';

class ItemViewScreen extends StatefulWidget {
  /// The Firestore document for this report (owned by the current user).
  final QueryDocumentSnapshot<Map<String, dynamic>> report;

  const ItemViewScreen({super.key, required this.report});

  @override
  State<ItemViewScreen> createState() => _ItemViewScreenState();
}

class _ItemViewScreenState extends State<ItemViewScreen> {
  bool isEditing = false;
  bool isResolved = false;
  bool isDeleted = false;
  String? undoAction; // 'delete', 'resolved', or null

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── EDITABLE FIELD CONTROLLERS ───────────────────────────────────
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _contactCtrl;

  // ─── READ-ONLY DERIVED VALUES ─────────────────────────────────────
  late bool _isLost;
  late String _imageUrl;
  late String _dateDisplay;

  @override
  void initState() {
    super.initState();
    final data = widget.report.data();

    _isLost = (data['type'] ?? 'lost') == 'lost';
    _imageUrl = data['imageUrl'] ?? '';
    _dateDisplay = _formatDate(data['date']);
    _checkResolved(data['status']);
    isDeleted = data['isDeleted'] ?? false;

    _nameCtrl =
        TextEditingController(text: data['itemName'] ?? '');
    _descCtrl =
        TextEditingController(text: data['description'] ?? '');
    _locationCtrl =
        TextEditingController(text: data['location'] ?? '');
    _contactCtrl =
        TextEditingController(text: data['contact'] ?? '');
  }

  void _checkResolved(dynamic status) {
    isResolved = status == 'resolved';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  // ─── FORMAT TIMESTAMP ─────────────────────────────────────────────
  String _formatDate(dynamic ts) {
    if (ts == null) return 'No date';
    final dt = (ts as Timestamp).toDate();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  // ─── FIRESTORE SAVE ───────────────────────────────────────────────
  Future<void> _saveChanges() async {
    try {
      await widget.report.reference.update({
        'itemName': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Please try again.')),
        );
      }
    }
  }

  // ─── FIRESTORE SOFT DELETE (COMPLETELY SILENT) ────────────────────────────────────
  Future<void> _softDeleteItem() async {
    try {
      setState(() {
        isDeleted = true;
        undoAction = 'delete';
      });

      await widget.report.reference.update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isDeleted = false;
          undoAction = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete. Please try again.')),
        );
      }
    }
  }

  // ─── UNDO DELETE (COMPLETELY SILENT) ──────────────────────────────────────
  Future<void> _undoDelete() async {
    try {
      setState(() {
        isDeleted = false;
        undoAction = null;
      });

      await widget.report.reference.update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isDeleted = true;
          undoAction = 'delete';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore. Please try again.')),
        );
      }
    }
  }

  // ─── FIRESTORE MARK AS RESOLVED (COMPLETELY SILENT) ───────────────────────────────────
  Future<void> _markResolved() async {
    try {
      setState(() {
        isResolved = true;
        undoAction = 'resolved';
      });

      await widget.report.reference.update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isResolved = false;
          undoAction = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update. Please try again.')),
        );
      }
    }
  }

  // ─── UNDO RESOLVED (COMPLETELY SILENT) ────────────────────────────────────
  Future<void> _undoResolved() async {
    try {
      setState(() {
        isResolved = false;
        undoAction = null;
      });

      await widget.report.reference.update({
        'status': 'active',
        'resolvedAt': FieldValue.delete(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isResolved = true;
          undoAction = 'resolved';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to undo. Please try again.')),
        );
      }
    }
  }

  // ─── CONFIRM DIALOGS ──────────────────────────────────────────────

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?'),
        content:
        const Text('Are you sure you want to delete this item? You can restore it later.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _softDeleteItem();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Delete')),
        ],
      ),
    );
  }

  void _confirmMark() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm action'),
        content: Text(
          'Clicking yes would mark this item as '
              '${_isLost ? 'found' : 'claimed'} '
              'and it will no longer show on the main feed. You can undo this.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _markResolved();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text('Yes')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ───────────────────────────────────────────────────────────────
    // IF ITEM IS DELETED, SHOW DELETED SCREEN
    // ───────────────────────────────────────────────────────────────
    if (isDeleted) {
      return Scaffold(
        backgroundColor: const Color(0xFFD9E7FB),
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 26),
                child: HeaderNav(),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(26),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.delete_outline, size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        const Text(
                          'This item has been deleted',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'You can restore it or permanently delete it from your trash.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: _undoDelete,
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Go Back'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ───────────────────────────────────────────────────────────────
    // NORMAL ITEM VIEW SCREEN
    // ───────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 26),
              child: HeaderNav(),
            ),

            const SizedBox(height: 8),

            // BACK BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Back',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),

            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // IMAGE — handles base64 and network URLs
                    Center(child: _buildImage(_imageUrl)),

                    const SizedBox(height: 24),

                    // TITLE (editable)
                    isEditing
                        ? _editField(
                      controller: _nameCtrl,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    )
                        : Text(
                      _nameCtrl.text.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900),
                    ),

                    const SizedBox(height: 18),

                    _detail(
                      icon: Icons.chat_bubble_outline,
                      label: 'Description',
                      controller: _descCtrl,
                      editable: isEditing,
                    ),

                    _detail(
                      icon: Icons.location_on_outlined,
                      label: _isLost ? 'Last seen location' : 'Found at',
                      controller: _locationCtrl,
                      editable: isEditing,
                    ),

                    // Date is never editable
                    _detailStatic(
                      icon: Icons.calendar_month_outlined,
                      label: _isLost ? 'Date lost' : 'Date found',
                      value: _dateDisplay,
                    ),

                    _detail(
                      icon: Icons.phone_in_talk_outlined,
                      label: 'Contact',
                      controller: _contactCtrl,
                      editable: isEditing,
                    ),

                    const SizedBox(height: 40),

                    // RESOLVED BADGE
                    if (isResolved)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9ED6B8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isLost
                                ? 'Item has been found'
                                : 'Item has been claimed',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // FIXED BOTTOM ACTION BAR (hidden when resolved)
            if (!isResolved)
              Container(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
                color: const Color(0xFFD9E7FB),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: isEditing ? 'Save' : 'Edit',
                            icon: isEditing ? Icons.check : Icons.edit,
                            color: const Color(0xFF9EC1F7),
                            onTap: isEditing ? _saveChanges : () => setState(() => isEditing = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            label: isEditing ? 'Cancel' : 'Delete',
                            icon: isEditing ? Icons.close : Icons.delete,
                            color: const Color(0xFFE59A9A),
                            onTap: isEditing
                                ? () => setState(() => isEditing = false)
                                : _confirmDelete,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    if (!isEditing)
                      _actionButton(
                        label: _isLost
                            ? 'Mark as found'
                            : 'Mark as claimed',
                        icon: Icons.check_circle,
                        color: const Color(0xFF9ED6B8),
                        onTap: _confirmMark,
                        fullWidth: true,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── UI HELPERS ───────────────────────────────────────────────────

  // ─── SMART IMAGE (base64 OR network URL) ──────────────────────────
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) return _imagePlaceholder();

    if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            bytes,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          ),
        );
      } catch (_) {
        return _imagePlaceholder();
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        imageUrl,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 48,
        color: Colors.black26,
      ),
    );
  }

  Widget _detail({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool editable,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                editable
                    ? _editField(controller: controller)
                    : Text(controller.text,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStatic({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    TextStyle? style,
  }) {
    return TextField(
      controller: controller,
      style: style ?? const TextStyle(fontSize: 12),
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool fullWidth = false,
  }) {
    return SizedBox(
      height: 44,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label,
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}