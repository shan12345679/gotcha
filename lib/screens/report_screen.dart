// lib/screens/report_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/header_nav.dart';
import '../widgets/bottom_nav.dart';
import '../theme/app_theme.dart';  // we'll update this too

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool lostSelected = true;
  DateTime? selectedDate;
  XFile? selectedImage;
  String? imageBase64;
  bool _isSubmitting = false;

  final _formKey = GlobalKey<FormState>();
  final _itemNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();

  @override
  void dispose() {
    _itemNameCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.gold,         // gold accent
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await ImagePicker().pickImage(source: source, imageQuality: 75);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImage = image;
        imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: AppTheme.navy),
            title: const Text('Take a photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppTheme.navy),
            title: const Text('Choose from gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  bool _validate() {
    if (_itemNameCtrl.text.trim().isEmpty) return false;
    if (_descCtrl.text.trim().isEmpty) return false;
    if (_locationCtrl.text.trim().isEmpty) return false;
    if (selectedDate == null) return false;
    if (_contactCtrl.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      await FirebaseFirestore.instance.collection('reports').add({
        'type': lostSelected ? 'lost' : 'found',
        'itemName': _itemNameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'location': _locationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'date': Timestamp.fromDate(selectedDate!),
        'imageUrl': imageBase64 ?? '',
        'status': 'active',
        'userId': uid,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✨ Report posted successfully!')),
        );
        _clearForm();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _clearForm() {
    _itemNameCtrl.clear();
    _descCtrl.clear();
    _locationCtrl.clear();
    _contactCtrl.clear();
    setState(() {
      selectedDate = null;
      selectedImage = null;
      imageBase64 = null;
      lostSelected = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy, // deep navy background
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppTheme.navy, AppTheme.navyLight],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const HeaderNav(),
                const SizedBox(height: 30),
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Found or Lost Something?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Post details and help reunite items',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildTypeSelector(),
                const SizedBox(height: 28),
                _buildGlamorousTextField(_itemNameCtrl, 'Item name', Icons.tag),
                const SizedBox(height: 16),
                _buildGlamorousTextField(_descCtrl, 'Description', Icons.description, maxLines: 3),
                const SizedBox(height: 16),
                _buildGlamorousTextField(_locationCtrl, 'Location', Icons.location_on),
                const SizedBox(height: 16),
                _buildGlamorousTextField(_contactCtrl, 'Contact number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildDateTile()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildImageTile()),
                  ],
                ),
                if (imageBase64 != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.memory(
                            base64Decode(imageBase64!.split(',')[1]),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              selectedImage = null;
                              imageBase64 = null;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.close, size: 20, color: AppTheme.navy),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                _buildSubmitButton(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          Expanded(
            child: _typeOption('I lost an item', true, lostSelected, () => setState(() => lostSelected = true)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _typeOption('I found an item', false, !lostSelected, () => setState(() => lostSelected = false)),
          ),
        ],
      ),
    );
  }

  Widget _typeOption(String label, bool isLost, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (isLost ? AppTheme.gold : AppTheme.goldLight) : Colors.transparent,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppTheme.navy : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlamorousTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          prefixIcon: Icon(icon, color: AppTheme.gold, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDateTile() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month, color: AppTheme.gold, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedDate == null ? 'Select date' : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              style: TextStyle(color: selectedDate == null ? Colors.white.withOpacity(0.6) : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile() {
    return GestureDetector(
      onTap: _showImageOptions,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.image, color: AppTheme.gold, size: 20),
            const SizedBox(width: 12),
            Text(
              selectedImage == null ? 'Attach image' : 'Image selected ✓',
              style: TextStyle(color: selectedImage == null ? Colors.white.withOpacity(0.6) : Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.gold,
          foregroundColor: AppTheme.navy,
          elevation: 4,
          shadowColor: AppTheme.gold.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.navy,
          ),
        )
            : const Text(
          'Submit Report',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}