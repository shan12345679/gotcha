import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  File? selectedImage;

  final ImagePicker imgPicker = ImagePicker();

  // DATE PICKER
  Future<void> pickDate() async {
    DateTime today = DateTime.now();

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(2000),
      lastDate: today,
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // IMAGE PICKER
  Future<void> pickImage(ImageSource source) async {
    XFile? image = await imgPicker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  // IMAGE OPTIONS
  void showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return Column(
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
        );
      },
    );
  }

  // ─── CONFIRM SUBMIT ────────────────────────────────────────────────
  void _confirmSubmit() {
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
              Navigator.pop(context); // close confirm dialog
              _showSuccessDialog();
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  // ─── SUCCESS DIALOG ────────────────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Your report has been submitted successfully.'),
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
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
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

                const Text(
                  'Report Type',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                            onChanged: (_) {
                              setState(() {
                                lostSelected = true;
                              });
                            },
                          ),
                          const Text('I lost an item', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: !lostSelected,
                            onChanged: (_) {
                              setState(() {
                                lostSelected = false;
                              });
                            },
                          ),
                          const Text('I found an item', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text('Item Name',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Enter item name...'),

                const SizedBox(height: 16),

                const Text('Description',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Describe the item...', maxLines: 4),

                const SizedBox(height: 16),

                const Text('Location',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                inputField('Enter the exact location'),

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
                                    fontWeight: FontWeight.w800, fontSize: 15)),
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
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 8),
                            _smallBox(
                              Icons.image_outlined,
                              selectedImage == null
                                  ? 'Select image'
                                  : 'Image selected',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (selectedImage != null) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        selectedImage!,
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 26),

                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _confirmSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF84AEEA),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style:
                      TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

  Widget inputField(String hint, {int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
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
          Text(text, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}