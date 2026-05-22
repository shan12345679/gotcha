// lib/screens/profile_screen.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';
import '../widgets/header_nav.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (mounted) {
      final data = doc.data();
      final savedImage = data?['profileImageUrl'] ?? '';
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
    final image = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    setState(() {
      _profileImageBytes = bytes;
      if (!kIsWeb) _profileImage = File(image.path);
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({'profileImageUrl': base64Str});
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  showDialog(context: context, builder: (_) => Dialog(child: Image.memory(_profileImageBytes!)));
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

  Future<void> _updateField(String field, String currentValue) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field == 'email' ? 'Email' : 'Contact'}'),
        content: TextField(
          controller: controller,
          keyboardType: field == 'email' ? TextInputType.emailAddress : TextInputType.phone,
          decoration: InputDecoration(
            hintText: field == 'email' ? 'Enter email' : 'Enter 11-digit number',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != currentValue) {
      if (field == 'email' && (!result.contains('@') || !result.contains('.'))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid email')));
        return;
      }
      if (field == 'contact' && (result.length != 11 || !RegExp(r'^\d+$').hasMatch(result))) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact must be 11 digits')));
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({field: result});
        setState(() {
          _userData?[field] = result;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$field updated'), backgroundColor: AppTheme.gold),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
      }
    }
  }

  Future<void> _changePassword() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmNewPasswordCtrl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmNewPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (newPasswordCtrl.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
                return;
              }
              if (newPasswordCtrl.text != confirmNewPasswordCtrl.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New passwords do not match')));
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPasswordCtrl.text,
    );
    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPasswordCtrl.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully'), backgroundColor: AppTheme.gold),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Change failed';
      if (e.code == 'wrong-password') message = 'Current password is incorrect';
      if (e.code == 'weak-password') message = 'New password is too weak';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An error occurred')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LogoutScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fullName = _userData?['fullName'] ?? 'Loading...';
    final username = _userData?['username'] ?? '';
    final email = _userData?['email'] ?? '';
    final contact = _userData?['contact'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const HeaderNav(),
              const SizedBox(height: 24),
              // Profile picture
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.gold, width: 2.5),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4)),
                        BoxShadow(color: AppTheme.gold.withOpacity(0.3), blurRadius: 12, spreadRadius: 2),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppTheme.gold,
                      backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
                      child: _profileImageBytes == null
                          ? const Icon(Icons.person, size: 70, color: AppTheme.navy)
                          : null,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showImageOptions,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: AppTheme.gold, shape: BoxShape.circle),
                      child: const Icon(Icons.edit, size: 18, color: AppTheme.navy),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(fullName, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Text('@$username', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
              const SizedBox(height: 40),

              // Email tile (entire tile tappable)
              _buildInfoTileWithEdit(
                icon: Icons.email_outlined,
                title: 'Email',
                value: email,
                onEdit: () => _updateField('email', email),
              ),
              const SizedBox(height: 20),

              // Contact tile (entire tile tappable)
              _buildInfoTileWithEdit(
                icon: Icons.phone_outlined,
                title: 'Contact',
                value: contact,
                onEdit: () => _updateField('contact', contact),
              ),
              const SizedBox(height: 20),

              // Change Password tile (already tappable)
              _buildActionTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: _changePassword,
              ),
              const SizedBox(height: 20),

              // Logout tile
              _buildLogoutTile(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNav(currentIndex: 3),
    );
  }

  // ✅ Entire tile is tappable, shows "Edit" + chevron instead of pencil icon
  Widget _buildInfoTileWithEdit({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.navyLight.withOpacity(0.7),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppTheme.gold),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              // Edit label + chevron
              Row(
                children: [
                  Text('Edit', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 18, color: AppTheme.gold),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.navyLight.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutTile() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.gold.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
        ),
        child: const Row(
          children: [
            Icon(Icons.logout, color: AppTheme.gold),
            SizedBox(width: 14),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
          ],
        ),
      ),
    );
  }
}