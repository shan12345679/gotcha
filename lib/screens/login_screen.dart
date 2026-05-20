import 'package:flutter/material.dart';
import 'package:gotcha_app/screens/signup_screen.dart';
import 'package:gotcha_app/screens/home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Lost something? Found something? Log in or sign up and let the community help.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF555555),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 28),

                    const _GotchaTextField(hint: 'Username'),
                    const SizedBox(height: 12),

                    const _GotchaTextField(
                      hint: 'Password',
                      obscure: true,
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            PageRouteBuilder(
                              transitionDuration:
                              const Duration(milliseconds: 400),
                              pageBuilder: (_, animation, __) =>
                              const HomeScreen(),
                              transitionsBuilder:
                                  (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A1A2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              transitionDuration:
                              const Duration(milliseconds: 400),
                              pageBuilder: (_, animation, __) =>
                              const SignupScreen(),
                              transitionsBuilder:
                                  (_, animation, __, child) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOutCubic,
                                ));
                                return SlideTransition(
                                  position: slide,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF555555),
                            ),
                            children: [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Sign in',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                '© 2026 Gotcha. All rights reserved.',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GotchaTextField extends StatefulWidget {
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;

  const _GotchaTextField({
    required this.hint,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  State<_GotchaTextField> createState() => _GotchaTextFieldState();
}

class _GotchaTextFieldState extends State<_GotchaTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: _obscureText,
      keyboardType: widget.keyboardType,
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1A1A2E),
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

        // 👁 Eye toggle only for password
        suffixIcon: widget.obscure
            ? IconButton(
          icon: Icon(
            _obscureText
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF777777),
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        )
            : null,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
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