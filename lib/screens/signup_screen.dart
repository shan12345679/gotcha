import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gotcha_app/screens/home_screen.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _contactCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => email.contains('@') && email.contains('.');

  Future<void> _onSignup() async {
    if (_firstNameCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _contactCtrl.text.length != 11 ||
        !_isValidEmail(_emailCtrl.text) ||
        _passwordCtrl.text.isEmpty ||
        _passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() => _errorMessage = 'Please check your inputs');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check your inputs')));
      return;
    }
    if (_passwordCtrl.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters')));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final String uid = userCredential.user!.uid;
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName': '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isLoggedIn': true,
        'profileImageUrl': '',
        'bio': '',
        'location': '',
      });
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'weak-password':
          msg = 'Password is too weak';
          break;
        case 'email-already-in-use':
          msg = 'Email is already registered';
          break;
        default:
          msg = 'Sign up failed. Please try again';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('An unexpected error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.navy,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.navy, AppTheme.navyLight],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      // ✨ Smaller circular logo (radius 45 instead of 60)
                      Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.gold, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                              BoxShadow(
                                color: AppTheme.gold.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'images/gotcha_logo.png',
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Hola!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lost something? Found something? Log in or sign up and let the community help.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade800.withOpacity(0.2),
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade100)),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _glamTextField(_firstNameCtrl, 'First Name')),
                          const SizedBox(width: 12),
                          Expanded(child: _glamTextField(_lastNameCtrl, 'Last Name')),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _glamTextField(_usernameCtrl, 'Username', onChanged: (val) {
                        final filtered = val.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
                        final trimmed = filtered.length > 20 ? filtered.substring(0, 20) : filtered;
                        if (trimmed != val) {
                          _usernameCtrl.text = trimmed;
                          _usernameCtrl.selection = TextSelection.fromPosition(TextPosition(offset: trimmed.length));
                        }
                      }),
                      const SizedBox(height: 16),
                      _glamTextField(_emailCtrl, 'Email Address', keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),
                      _glamTextField(_contactCtrl, 'Contact Number', keyboardType: TextInputType.phone, onChanged: (val) {
                        final digits = val.replaceAll(RegExp(r'\D'), '');
                        final trimmed = digits.length > 11 ? digits.substring(0, 11) : digits;
                        if (trimmed != val) {
                          _contactCtrl.text = trimmed;
                          _contactCtrl.selection = TextSelection.fromPosition(TextPosition(offset: trimmed.length));
                        }
                      }),
                      const SizedBox(height: 16),
                      _glamTextField(_passwordCtrl, 'Password', obscure: _obscurePassword, suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      )),
                      const SizedBox(height: 16),
                      _glamTextField(_confirmPasswordCtrl, 'Confirm Password', obscure: _obscureConfirmPassword, suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: AppTheme.gold),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      )),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _onSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.navy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.navy))
                              : const Text('Sign Up', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 13),
                              children: [
                                TextSpan(text: 'Have an account? ', style: TextStyle(color: Colors.white70)),
                                TextSpan(text: 'Log in', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('© 2026 Gotcha. All rights reserved.', style: TextStyle(fontSize: 11, color: Colors.white38)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glamTextField(TextEditingController ctrl, String hint, {bool obscure = false, TextInputType? keyboardType, ValueChanged<String>? onChanged, Widget? suffixIcon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}