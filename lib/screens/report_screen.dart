import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header_nav.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool lostSelected = true;

  DateTime? selectedDate;
  XFile? selectedImage;
  Uint8List? selectedImageBytes;
  bool _isSubmitting = false;

  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  final ImagePicker imgPicker = ImagePicker();

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // ─── DATE PICKER ───────────────────────────────────────────────────
  Future<void> pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: today,
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ─── IMAGE PICKER ──────────────────────────────────────────────────
  Future<void> pickImage(ImageSource source) async {
    final image = await imgPicker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        selectedImage = image;
        selectedImageBytes = bytes;
      });
    }
  }

  // ─── IMAGE OPTIONS BOTTOM SHEET ────────────────────────────────────
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              pickImage(ImageSource.gallery);
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ─── VALIDATE FIELDS ───────────────────────────────────────────────
  bool _validateFields() {
    if (_itemNameController.text.trim().isEmpty) {
      _showError('Please enter the item name.');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description.');
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _showError('Please enter the location.');
      return false;
    }
    if (selectedDate == null) {
      _showError('Please select a date.');
      return false;
    }
    if (_contactController.text.trim().isEmpty) {
      _showError('Please enter a contact number.');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  // ─── CONFIRM SUBMIT DIALOG ─────────────────────────────────────────
  void _confirmSubmit() {
    if (!_validateFields()) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirm submission'),
        content: const Text(
          'Please confirm that all details are correct before submitting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitReport();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ─── CONVERT IMAGE TO BASE64 ───────────────────────────────────────
  Future<String?> _getBase64Image(XFile image) async {
    try {
      final bytes = await image.readAsBytes();
      final base64Str = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64Str';
    } catch (_) {
      return null;
    }
  }

  // ─── SUBMIT TO FIRESTORE ───────────────────────────────────────────
  Future<void> _submitReport() async {
    setState(() => _isSubmitting = true);

    try {
      // Get current user — required so MyItemsScreen can filter by owner
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser?.uid ?? '';

      String? imageUrl;
      if (selectedImage != null) {
        imageUrl = await _getBase64Image(selectedImage!);
      }

      await FirebaseFirestore.instance.collection('reports').add({
        'type': lostSelected ? 'lost' : 'found',
        'itemName': _itemNameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'contact': _contactController.text.trim(),
        'date': selectedDate != null
            ? Timestamp.fromDate(selectedDate!)
            : null,
        'imageUrl': imageUrl ?? '',
        'hasImage': imageUrl != null,
        'status': 'active',                    // used by resolved filter
        'userId': uid,                          // owner — used by MyItemsScreen
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _showSuccessDialog();
        _clearForm();
      }
    } catch (e) {
      if (mounted) _showError('Failed to submit report. Please try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── CLEAR FORM ────────────────────────────────────────────────────
  void _clearForm() {
    _itemNameController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _contactController.clear();
    setState(() {
      selectedDate = null;
      selectedImage = null;
      selectedImageBytes = null;
      lostSelected = true;
    });
  }

  // ─── SUCCESS DIALOG ────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content:
        const Text('Your report has been submitted successfully.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 22),

                const HeaderNav(),

                const SizedBox(height: 36),

                const Center(
                  child: Text(
                    'Found or Lost Something?',
                    style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900),
                  ),
                ),

                const SizedBox(height: 10),

                const Center(
                  child: Text(
                    'Post the details and help reunite items with their owners.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                ),

                const SizedBox(height: 28),

                const Text('Report Type',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800)),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: lostSelected,
                            onChanged: (_) =>
                                setState(() => lostSelected = true),
                          ),
                          const Text('I lost an item',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: !lostSelected,
                            onChanged: (_) =>
                                setState(() => lostSelected = false),
                          ),
                          const Text('I found an item',
                              style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Item Name',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Enter item name...',
                    controller: _itemNameController),

                const SizedBox(height: 16),

                const Text('Description',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Describe the item...',
                    maxLines: 4,
                    controller: _descriptionController),

                const SizedBox(height: 16),

                const Text('Location',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Enter the exact location',
                    controller: _locationController),

                const SizedBox(height: 16),

                const Text('Contact Number',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('e.g. 0912 345 6789',
                    controller: _contactController,
                    keyboardType: TextInputType.phone),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: pickDate,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Date',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            _smallBox(
                              Icons.calendar_month_outlined,
                              selectedDate == null
                                  ? 'Select date'
                                  : '${selectedDate!.month}-${selectedDate!.day}-${selectedDate!.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: showImageOptions,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Attach Image',
                                style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15)),
                            const SizedBox(height: 8),
                            _smallBox(
                              Icons.image_outlined,
                              selectedImage == null
                                  ? 'Select image'
                                  : 'Image selected ✓',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // IMAGE PREVIEW
                if (selectedImageBytes != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            selectedImageBytes!,
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                        ),
                        // Remove image button
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() {
                              selectedImage = null;
                              selectedImageBytes = null;
                            }),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(Icons.close,
                                  size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                // PROGRESS INDICATOR while submitting
                if (_isSubmitting) ...[
                  const Text(
                    'Uploading your report, please wait...',
                    textAlign: TextAlign.center,
                    style:
                    TextStyle(fontSize: 11, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(
                    backgroundColor: Colors.white54,
                    color: Color(0xFF2E5FA7),
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84AEEA),
                      foregroundColor: Colors.black,
                      disabledBackgroundColor:
                      const Color(0xFF84AEEA).withOpacity(0.5),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black54),
                    )
                        : const Text(
                      'Submit',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 1),
    );
  }

  Widget inputField(
      String hint, {
        int maxLines = 1,
        required TextEditingController controller,
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 11),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 10, color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withOpacity(0.75),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _smallBox(IconData icon, String text) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}