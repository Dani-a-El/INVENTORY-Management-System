import 'package:flutter/material.dart';

import '../routes.dart';
import '../services/app_settings_service.dart';
import '../services/auth_service.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GlobalKey<FormState> _profileFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _darkMode = false;
  bool _rememberMe = true;
  bool _loading = true;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    // Load persisted theme/session state and seed the profile form.
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Settings need both the theme service and auth service because the page
    // lets the user edit account data and app preferences in one place.
    await AppSettingsService.instance.initialize();
    await AuthService.instance.initialize();

    final currentUser = AuthService.instance.currentUser;

    if (!mounted) {
      return;
    }

    setState(() {
      _nameController.text = currentUser?.name ?? '';
      _emailController.text = currentUser?.email ?? '';
      _darkMode = AppSettingsService.instance.isDarkMode;
      _rememberMe = AuthService.instance.rememberMePreference;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) {
      return;
    }

    // Keep the button disabled while the backend updates the profile.
    setState(() {
      _savingProfile = true;
    });

    try {
      final updatedUser = await AuthService.instance.updateProfile(
        name: _nameController.text,
        email: _emailController.text,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _nameController.text = updatedUser.name;
        _emailController.text = updatedUser.email;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
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
          _savingProfile = false;
        });
      }
    }
  }

  Future<void> _toggleTheme(bool value) async {
    // Update local state immediately so the switch feels responsive.
    setState(() {
      _darkMode = value;
    });
    await AppSettingsService.instance.toggleDarkMode(value);
  }

  Future<void> _toggleRememberMe(bool value) async {
    // Remember-me only changes persistence policy, not the active session.
    setState(() {
      _rememberMe = value;
    });
    await AuthService.instance.updateRememberMePreference(value);
  }

  @override
  Widget build(BuildContext context) {
    // Show a back button when the page was pushed from another screen; the
    // drawer remains available for global navigation.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: canPop
            ? IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
      ),
      drawer: const AppDrawer(currentRouteName: AppRoutes.settings),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _profileFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFFE8F5F4),
                                child: Icon(Icons.person_rounded),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AuthService.instance.currentUser?.name ??
                                          'Signed in user',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      AuthService.instance.currentUser?.email ??
                                          'No email available',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Display name',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email address',
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
                          FilledButton.icon(
                            onPressed: _savingProfile ? null : _saveProfile,
                            icon: _savingProfile
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: const Text('Save profile'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: const Text('Dark mode'),
                    subtitle: const Text(
                      'Switch the app between light and dark themes.',
                    ),
                    value: _darkMode,
                    onChanged: _toggleTheme,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: SwitchListTile(
                    title: const Text('Remember me'),
                    subtitle: const Text(
                      'Keep the current session after app restart.',
                    ),
                    value: _rememberMe,
                    onChanged: _toggleRememberMe,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_reset_rounded),
                    title: const Text('Forgot password'),
                    subtitle: const Text(
                      'Send a reset code to your account email.',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.forgotPassword);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
