import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gotcha_app/screens/home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // ─── Firebase Instances ────────────────────────────────────────────────────
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Controllers ────────────────────────────────────────────────────────────
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

  // ─── Helpers ────────────────────────────────────────────────────────────────
  bool _isValidEmail(String email) {
    return email.contains('@') && email.contains('.');
  }

  Future<void> _onSignup() async {
    // Validate inputs
    if (_firstNameCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _usernameCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _contactCtrl.text.length != 11 ||
        !_isValidEmail(_emailCtrl.text) ||
        _passwordCtrl.text.isEmpty ||
        _passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() {
        _errorMessage = 'Please check your inputs';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your inputs')),
      );
      return;
    }

    // Check if passwords match
    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    // Check password length
    if (_passwordCtrl.text.length < 6) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create user in Firebase Auth
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      final String uid = userCredential.user!.uid;

      // Save user profile to Firestore
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'fullName':
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
        'username': _usernameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
        'isLoggedIn': true,
        'profileImageUrl': '', // Empty for now
        'bio': '', // Empty for now
        'location': '', // Empty for now
      });

      // Navigate to HomeScreen on success
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, animation, __) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getAuthErrorMessage(e.code);
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } on FirebaseException catch (e) {
      setState(() {
        _errorMessage = 'Database error: ${e.message}';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    }
  }

  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Password is too weak';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'operation-not-allowed':
        return 'Sign up is currently disabled';
      case 'user-disabled':
        return 'This account has been disabled';
      default:
        return 'Sign up failed. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD6E4F7),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // Logo
                    Center(
                      child: Image.asset(
                        'images/gotcha_logo.png',
                        width: 140,
                      ),
                    ),

                    const SizedBox(height: 40),

                    const Text(
                      'Hola!',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lost something? Found something? Log in or sign up and let the community help.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF555555)),
                    ),

                    const SizedBox(height: 28),

                    // Error Message Display
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),

                    // ─── First + Last Name ─────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _GotchaTextField(
                            hint: 'First Name',
                            controller: _firstNameCtrl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GotchaTextField(
                            hint: 'Last Name',
                            controller: _lastNameCtrl,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ─── Username ──────────────────────────────────────────────
                    _GotchaTextField(
                      hint: 'Username',
                      controller: _usernameCtrl,
                      onChanged: (value) {
                        final filtered =
                        value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');

                        final trimmed = filtered.length > 20
                            ? filtered.substring(0, 20)
                            : filtered;

                        if (trimmed != value) {
                          _usernameCtrl.text = trimmed;
                          _usernameCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: trimmed.length),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // ─── Email ────────────────────────────────────────────────
                    _GotchaTextField(
                      hint: 'Email Address',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailCtrl,
                    ),

                    const SizedBox(height: 12),

                    // ─── Contact Number ───────────────────────────────────────
                    _GotchaTextField(
                      hint: 'Contact Number',
                      keyboardType: TextInputType.phone,
                      controller: _contactCtrl,
                      onChanged: (value) {
                        final digits = value.replaceAll(RegExp(r'\D'), '');
                        final trimmed = digits.length > 11
                            ? digits.substring(0, 11)
                            : digits;

                        if (trimmed != value) {
                          _contactCtrl.text = trimmed;
                          _contactCtrl.selection = TextSelection.fromPosition(
                            TextPosition(offset: trimmed.length),
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 12),

                    // ─── Password ─────────────────────────────────────────────
                    _GotchaTextField(
                      hint: 'Password',
                      controller: _passwordCtrl,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ─── Confirm Password ─────────────────────────────────────
                    _GotchaTextField(
                      hint: 'Confirm Password',
                      controller: _confirmPasswordCtrl,
                      obscure: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Sign Up Button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _onSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          disabledBackgroundColor: const Color(0xFF888888),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
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
                              TextSpan(
                                text: 'Have an account? ',
                                style: TextStyle(
                                  color: Color(0xFF888888),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: 'Log in',
                                style: TextStyle(
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '© 2026 Gotcha. All rights reserved.',
                style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Text Field ─────────────────────────────────────────────────────────

class _GotchaTextField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;

  const _GotchaTextField({
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.controller,
    this.onChanged,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffixIcon,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
          const BorderSide(color: Color(0xFF3A6BB5), width: 1.5),
        ),
      ),
    );
  }
}