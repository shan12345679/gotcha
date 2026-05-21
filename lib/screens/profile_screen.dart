import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/bottom_nav.dart';
import 'logout_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  Uint8List? _profileImageBytes;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (mounted) {
      final data = doc.data();
      final savedImage = data?['profileImageUrl'] ?? '';

      // Load saved profile image if exists
      if (savedImage.isNotEmpty && savedImage.startsWith('data:image')) {
        try {
          final bytes = base64Decode(savedImage.split(',')[1]);
          setState(() => _profileImageBytes = bytes);
        } catch (_) {}
      }

      setState(() {
        _userData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
        source: source, imageQuality: 70);
    if (image == null) return;

    final bytes = await image.readAsBytes();
    final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    setState(() {
      _profileImageBytes = bytes;
      if (!kIsWeb) _profileImage = File(image.path);
    });

    // Save to Firestore
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'profileImageUrl': base64Str});
  }

  ImageProvider? get _avatarImage {
    if (_profileImageBytes != null) return MemoryImage(_profileImageBytes!);
    if (!kIsWeb && _profileImage != null) return FileImage(_profileImage!);
    return null;
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_profileImageBytes != null)
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('View Profile Image'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      child: Image.memory(_profileImageBytes!),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LogoutScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _userData?['fullName'] ?? 'Loading...';
    final username = _userData?['username'] ?? '';
    final email = _userData?['email'] ?? '';
    final contact = _userData?['contact'] ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFD9E7FB),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const SizedBox(height: 40),

              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFF84AEEA),
                    backgroundImage: _avatarImage,
                    child: _avatarImage == null
                        ? const Icon(Icons.person,
                        size: 60, color: Colors.white)
                        : null,
                  ),
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 18),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                fullName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '@$username',
                style: const TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              profileTile(Icons.email_outlined, 'Email', email),
              profileTile(Icons.phone_outlined, 'Contact', contact),

              const SizedBox(height: 20),

              logoutTile(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  Widget profileTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  Widget logoutTile() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E).withOpacity(0.50),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 14),
            Text(
              'Logout',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}