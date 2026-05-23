import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    // Mirror the saved remember-me preference when the screen opens.
    _rememberMe = AuthService.instance.rememberMePreference;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Prevent duplicate submissions while the request is in flight.
    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Login intentionally uses a centered card layout to keep the first step
    // of the auth flow simple and focused.
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFDFF3F2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.inventory_2_rounded,
                          size: 54,
                          color: Color(0xFF2A9D8F),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome back',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Sign in to continue managing your inventory.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 6),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text('Remember me'),
                          value: _rememberMe,
                          onChanged: (value) {
                            setState(() {
                              _rememberMe = value ?? true;
                            });
                          },
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Login'),
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.register,
                                ),
                          child: const Text('Register new account'),
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.forgotPassword,
                                ),
                          child: const Text('Forgot password?'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
