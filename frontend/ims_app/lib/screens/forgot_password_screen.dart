import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isRequestingCode = false;
  bool _isResetting = false;
  bool _obscurePassword = true;
  String? _resetCodeHint;

  @override
  void dispose() {
    _emailController.dispose();
    _resetCodeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestResetCode() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter your email first')));
      return;
    }

    // Requesting a code and resetting the password are intentionally split so
    // the user can retry either step independently.
    setState(() {
      _isRequestingCode = true;
    });

    try {
      final resetCode = await AuthService.instance.requestPasswordReset(
        _emailController.text,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _resetCodeHint = resetCode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reset code generated: $resetCode')),
      );
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
          _isRequestingCode = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Keep the UI locked while the backend validates the reset code.
    setState(() {
      _isResetting = true;
    });

    try {
      await AuthService.instance.resetPassword(
        email: _emailController.text,
        resetCode: _resetCodeController.text,
        password: _passwordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please log in.')),
      );
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
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
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This screen keeps the reset code visible so the demo flow remains easy
    // to complete without email infrastructure.
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.lock_reset_rounded,
                      size: 54,
                      color: Color(0xFFF4A261),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Reset your password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Request a reset code, then create a new password.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
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
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isRequestingCode ? null : _requestResetCode,
                      icon: _isRequestingCode
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('Send reset code'),
                    ),
                    if (_resetCodeHint != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F4),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text('Reset code: $_resetCodeHint'),
                      ),
                    ],
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _resetCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Reset code',
                        prefixIcon: Icon(Icons.pin_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the reset code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'New password',
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
                        if (value == null || value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm new password',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isResetting ? null : _resetPassword,
                      child: _isResetting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reset password'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
