import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get userData => _userData;

  AuthService() {
    _loadUserData();
  }

  // Load user data from SharedPreferences on app start
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

      if (isLoggedIn && userDataString != null) {
        _userData = json.decode(userDataString);
        _isAuthenticated = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Save user data to SharedPreferences
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', json.encode(userData));
      await prefs.setBool('is_logged_in', true);
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  // Clear user data from SharedPreferences
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      await prefs.setBool('is_logged_in', false);
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Check if email already exists
  Future<bool> _emailExists(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredEmails = prefs.getStringList('registered_emails') ?? [];
      return registeredEmails.contains(email.toLowerCase());
    } catch (e) {
      debugPrint('Error checking email existence: $e');
      return false;
    }
  }

  // Save registered email
  Future<void> _saveRegisteredEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final registeredEmails = prefs.getStringList('registered_emails') ?? [];
      if (!registeredEmails.contains(email.toLowerCase())) {
        registeredEmails.add(email.toLowerCase());
        await prefs.setStringList('registered_emails', registeredEmails);
      }
    } catch (e) {
      debugPrint('Error saving registered email: $e');
    }
  }

  // Get stored user credentials for login validation
  Future<Map<String, dynamic>?> _getStoredCredentials(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentialsString = prefs.getString('credentials_$email');
      if (credentialsString != null) {
        return json.decode(credentialsString);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting stored credentials: $e');
      return null;
    }
  }

  // Save user credentials
  Future<void> _saveCredentials(
    String email,
    String password,
    Map<String, dynamic> userData,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentials = {'password': password, 'userData': userData};
      await prefs.setString('credentials_$email', json.encode(credentials));
    } catch (e) {
      debugPrint('Error saving credentials: $e');
    }
  }

  // Sign up with email and password (FIXED: No auto-login)
  Future<String?> signUp({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      // Check if email already exists
      if (await _emailExists(email)) {
        return 'An account with this email already exists';
      }

      // Create user data
      final userData = {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'createdAt': DateTime.now().toIso8601String(),
      };

      // Save credentials and registered email but DON'T auto-login
      await _saveCredentials(email, password, userData);
      await _saveRegisteredEmail(email);

      // DON'T set authentication state or save user data to current session
      // User needs to manually login after signup

      return null; // Success
    } catch (e) {
      debugPrint('Signup error: $e');
      return 'An error occurred during signup. Please try again.';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      // Get stored credentials
      final storedCredentials = await _getStoredCredentials(email);

      if (storedCredentials == null) {
        return 'No account found with this email';
      }

      // Validate password
      if (storedCredentials['password'] != password) {
        return 'Incorrect password';
      }

      // Load user data and set authentication state
      final userData = storedCredentials['userData'] as Map<String, dynamic>;
      await _saveUserData(userData);

      _userData = userData;
      _isAuthenticated = true;
      notifyListeners();

      return null; // Success
    } catch (e) {
      debugPrint('Login error: $e');
      return 'An error occurred during login. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _clearUserData();
    _userData = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Update user profile
  Future<String?> updateProfile({
    required String fullName,
    required String phone,
  }) async {
    try {
      if (_userData == null) return 'User not logged in';

      final updatedUserData = Map<String, dynamic>.from(_userData!);
      updatedUserData['fullName'] = fullName;
      updatedUserData['phone'] = phone;
      updatedUserData['updatedAt'] = DateTime.now().toIso8601String();

      await _saveUserData(updatedUserData);

      // Update stored credentials as well
      final email = _userData!['email'];
      final storedCredentials = await _getStoredCredentials(email);
      if (storedCredentials != null) {
        await _saveCredentials(
          email,
          storedCredentials['password'],
          updatedUserData,
        );
      }

      _userData = updatedUserData;
      notifyListeners();

      return null; // Success
    } catch (e) {
      debugPrint('Update profile error: $e');
      return 'Failed to update profile. Please try again.';
    }
  }
}
