// lib/screens/item_view_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/header_nav.dart';

class ItemViewScreen extends StatefulWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> report;
  const ItemViewScreen({super.key, required this.report});

  @override
  State<ItemViewScreen> createState() => _ItemViewScreenState();
}

class _ItemViewScreenState extends State<ItemViewScreen> {
  bool isEditing = false;
  bool isResolved = false;
  bool isDeleted = false;
  String? undoAction;

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _contactCtrl;

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
    isResolved = data['status'] == 'resolved';
    isDeleted = data['isDeleted'] ?? false;

    _nameCtrl = TextEditingController(text: data['itemName'] ?? '');
    _descCtrl = TextEditingController(text: data['description'] ?? '');
    _locationCtrl = TextEditingController(text: data['location'] ?? '');
    _contactCtrl = TextEditingController(text: data['contact'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  String _formatDate(dynamic ts) {
    if (ts == null) return 'No date';
    final dt = (ts as Timestamp).toDate();
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}, ${dt.year}';
  }

  Future<void> _saveChanges() async {
    try {
      await widget.report.reference.update({
        'itemName': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() => isEditing = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save')));
    }
  }

  Future<void> _softDeleteItem() async {
    try {
      setState(() { isDeleted = true; undoAction = 'delete'; });
      await widget.report.reference.update({ 'isDeleted': true, 'deletedAt': FieldValue.serverTimestamp() });
    } catch (e) {
      if (mounted) {
        setState(() { isDeleted = false; undoAction = null; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete')));
      }
    }
  }

  Future<void> _undoDelete() async {
    try {
      setState(() { isDeleted = false; undoAction = null; });
      await widget.report.reference.update({ 'isDeleted': false, 'deletedAt': FieldValue.delete() });
    } catch (e) {
      setState(() { isDeleted = true; undoAction = 'delete'; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to restore')));
    }
  }

  Future<void> _markResolved() async {
    try {
      setState(() { isResolved = true; undoAction = 'resolved'; });
      await widget.report.reference.update({ 'status': 'resolved', 'resolvedAt': FieldValue.serverTimestamp() });
    } catch (e) {
      setState(() { isResolved = false; undoAction = null; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update')));
    }
  }

  Future<void> _undoResolved() async {
    try {
      setState(() { isResolved = false; undoAction = null; });
      await widget.report.reference.update({ 'status': 'active', 'resolvedAt': FieldValue.delete() });
    } catch (e) {
      setState(() { isResolved = true; undoAction = 'resolved'; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to undo')));
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete item?', style: TextStyle(color: AppTheme.navy)),
        content: const Text('This item will be moved to trash. You can restore it later.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _softDeleteItem(); },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmMark() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm action'),
        content: Text('Mark this item as ${_isLost ? 'found' : 'claimed'}? It will no longer appear on the main feed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _markResolved(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.navy),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeImage(String imageUrl) {
    Widget imageWidget;
    if (imageUrl.isEmpty) {
      imageWidget = _imagePlaceholder();
    } else if (imageUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(imageUrl.split(',')[1]);
        imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.memory(bytes, width: 220, height: 220, fit: BoxFit.cover),
        );
      } catch (_) {
        imageWidget = _imagePlaceholder();
      }
    } else {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          imageUrl,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.9), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.white.withOpacity(0.15), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: imageWidget,
    );
  }

  Widget _imagePlaceholder() => Container(
    width: 220,
    height: 220,
    decoration: BoxDecoration(
      color: AppTheme.navyLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
    ),
    child: const Icon(Icons.image_not_supported_outlined, size: 48, color: Colors.white38),
  );

  @override
  Widget build(BuildContext context) {
    if (isDeleted) {
      return Scaffold(
        backgroundColor: AppTheme.navy,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16), // ✅ added top spacing
              const Padding(padding: EdgeInsets.symmetric(horizontal: 26), child: HeaderNav()),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Row(
                    children: [
                      Icon(Icons.arrow_back, color: AppTheme.gold, size: 18),
                      SizedBox(width: 6),
                      Text('Back', style: TextStyle(fontSize: 12, color: AppTheme.gold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete_outline, size: 80, color: Colors.white38),
                      const SizedBox(height: 20),
                      const Text('Item Deleted', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 10),
                      const Text('You can restore it from trash.', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _undoDelete,
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.gold,
                          foregroundColor: AppTheme.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16), // ✅ added top spacing
            const Padding(padding: EdgeInsets.symmetric(horizontal: 26), child: HeaderNav()),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_back, color: AppTheme.gold, size: 18),
                    SizedBox(width: 6),
                    Text('Back', style: TextStyle(fontSize: 12, color: AppTheme.gold)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Center(
                      child: Hero(
                        tag: 'image_${widget.report.id}',
                        child: _buildLargeImage(_imageUrl),
                      ),
                    ),
                    const SizedBox(height: 24),
                    isEditing
                        ? _editField(_nameCtrl, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white))
                        : Text(_nameCtrl.text.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                    const SizedBox(height: 18),
                    _detail(icon: Icons.chat_bubble_outline, label: 'Description', controller: _descCtrl, editable: isEditing),
                    _detail(icon: Icons.location_on_outlined, label: _isLost ? 'Last seen location' : 'Found at', controller: _locationCtrl, editable: isEditing),
                    _detailStatic(icon: Icons.calendar_month_outlined, label: _isLost ? 'Date lost' : 'Date found', value: _dateDisplay),
                    _detail(icon: Icons.phone_in_talk_outlined, label: 'Contact', controller: _contactCtrl, editable: isEditing),
                    const SizedBox(height: 40),
                    if (isResolved)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                          child: Text(_isLost ? 'Item has been found' : 'Item has been claimed', style: const TextStyle(color: AppTheme.gold)),
                        ),
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            if (!isResolved)
              Container(
                padding: const EdgeInsets.fromLTRB(26, 12, 26, 22),
                color: AppTheme.navy,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _actionButton(
                            label: isEditing ? 'Save' : 'Edit',
                            icon: isEditing ? Icons.check : Icons.edit,
                            onTap: isEditing ? _saveChanges : () => setState(() => isEditing = true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _actionButton(
                            label: isEditing ? 'Cancel' : 'Delete',
                            icon: isEditing ? Icons.close : Icons.delete,
                            onTap: isEditing ? () => setState(() => isEditing = false) : _confirmDelete,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (!isEditing)
                      _actionButton(
                        label: _isLost ? 'Mark as found' : 'Mark as claimed',
                        icon: Icons.check_circle,
                        onTap: _confirmMark,
                        fullWidth: true,
                        color: AppTheme.gold,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _detail({required IconData icon, required String label, required TextEditingController controller, required bool editable}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 4),
                editable ? _editField(controller) : Text(controller.text, style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailStatic({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.gold),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 12, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(TextEditingController controller, {TextStyle? style}) {
    return TextField(
      controller: controller,
      style: style ?? const TextStyle(fontSize: 12, color: Colors.white),
      decoration: const InputDecoration(
        isDense: true,
        border: UnderlineInputBorder(),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.gold)),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    bool fullWidth = false,
    Color color = AppTheme.gold,
  }) {
    return SizedBox(
      height: 44,
      width: fullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: color == AppTheme.gold ? AppTheme.navy : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}