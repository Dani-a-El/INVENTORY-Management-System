import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class AuthUser {
  final int id;
  final String name;
  final String email;

  const AuthUser({required this.id, required this.name, required this.email});

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'].toString(),
      email: json['email'].toString(),
    );
  }
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _accessTokenKey = 'ims_access_token';
  static const _rememberMeKey = 'ims_remember_me';

  SharedPreferences? _prefs;
  AuthUser? _currentUser;
  String? _accessToken;
  bool _rememberMe = true;
  bool _initialized = false;

  bool get isAuthenticated => _currentUser != null;

  AuthUser? get currentUser => _currentUser;

  bool get rememberMePreference => _rememberMe;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Restore local preferences first, then try to hydrate the user from the
    // saved bearer token if one exists.
    _prefs = await SharedPreferences.getInstance();
    _rememberMe = _prefs?.getBool(_rememberMeKey) ?? true;

    final savedToken = _prefs?.getString(_accessTokenKey);
    if (savedToken != null && savedToken.isNotEmpty) {
      try {
        final response = await _client.get(
          Uri.parse('${ApiService.baseUrl}/auth/me'),
          headers: {'Authorization': 'Bearer $savedToken'},
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final decoded = jsonDecode(response.body) as Map<String, dynamic>;
          _accessToken = savedToken;
          _currentUser = AuthUser.fromJson(
            Map<String, dynamic>.from(decoded['user'] as Map),
          );
        } else {
          await _clearStoredSession();
        }
      } catch (_) {
        await _clearStoredSession();
      }
    }

    _initialized = true;
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    await initialize();

    // Login is delegated to FastAPI so the client only stores the token and
    // current user profile.
    final response = await _client.post(
      Uri.parse('${ApiService.baseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'remember_me': rememberMe,
      }),
    );

    _ensureSuccess(response, 'Login');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _currentUser = AuthUser.fromJson(
      Map<String, dynamic>.from(decoded['user'] as Map),
    );
    _accessToken = decoded['access_token'].toString();
    _rememberMe = rememberMe;

    await _prefs?.setBool(_rememberMeKey, rememberMe);
    if (rememberMe) {
      await _prefs?.setString(_accessTokenKey, _accessToken!);
    } else {
      await _prefs?.remove(_accessTokenKey);
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await initialize();

    // Registration only needs to create the server-side account.
    final response = await _client.post(
      Uri.parse('${ApiService.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    _ensureSuccess(response, 'Register');
  }

  Future<String> requestPasswordReset(String email) async {
    await initialize();

    // The backend returns a reset code for the current development flow.
    final response = await _client.post(
      Uri.parse('${ApiService.baseUrl}/auth/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    _ensureSuccess(response, 'Request password reset');
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['reset_code'].toString();
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String password,
    required String confirmPassword,
  }) async {
    await initialize();

    final response = await _client.post(
      Uri.parse('${ApiService.baseUrl}/auth/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'reset_code': resetCode.trim(),
        'password': password,
        'confirm_password': confirmPassword,
      }),
    );

    _ensureSuccess(response, 'Reset password');
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String email,
  }) async {
    await initialize();

    // Keep the active session while updating the current user's public profile.
    final response = await _client.put(
      Uri.parse('${ApiService.baseUrl}/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null && _accessToken!.isNotEmpty)
          'Authorization': 'Bearer $_accessToken',
      },
      body: jsonEncode({'name': name.trim(), 'email': email.trim()}),
    );

    _ensureSuccess(response, 'Update profile');

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final updatedUser = AuthUser.fromJson(
      Map<String, dynamic>.from(decoded['user'] as Map),
    );
    _currentUser = updatedUser;
    return updatedUser;
  }

  Future<void> signOut() async {
    await initialize();

    try {
      if (_accessToken != null && _accessToken!.isNotEmpty) {
        await _client.post(
          Uri.parse('${ApiService.baseUrl}/auth/logout'),
          headers: {'Authorization': 'Bearer $_accessToken'},
        );
      }
    } catch (_) {
      // Logout still succeeds locally even if the backend is unavailable.
    } finally {
      await _clearStoredSession();
    }
  }

  Future<void> updateRememberMePreference(bool value) async {
    await initialize();
    // Persist the preference separately from the token so the UI can toggle it
    // without forcing a sign-in.
    _rememberMe = value;
    await _prefs?.setBool(_rememberMeKey, value);
    if (!value) {
      await _prefs?.remove(_accessTokenKey);
    }
  }

  Future<void> _clearStoredSession() async {
    _currentUser = null;
    _accessToken = null;
    await _prefs?.remove(_accessTokenKey);
  }

  void _ensureSuccess(http.Response response, String action) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // Surface the backend message when available so UI errors stay readable.
    String details = response.body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        details = (decoded['detail'] ?? decoded['message'] ?? response.body)
            .toString();
      }
    } catch (_) {
      // Keep raw details when the response is not JSON.
    }

    throw Exception('$action failed (${response.statusCode}): $details');
  }

  http.Client get _client => ApiService.client;
}
