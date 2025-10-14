import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/config.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend/socket_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:frontend/models/user.dart';

import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:provider/provider.dart';

final log = Logger('AuthService');

enum AuthStatus { Uninitialized, Authenticated, Unauthenticated }

class AuthService with ChangeNotifier {
  final String baseUrl = '${AppConfig.baseUrl}/api/auth';
  String? _token;
  AuthStatus _status = AuthStatus.Uninitialized;

  User? get currentUser {
    if (_token == null) return null;
    try {
      final decodedToken = JwtDecoder.decode(_token!);
      return User(
        id: decodedToken['id'],
        username: decodedToken['username'],
        bio: '', // JWT might not contain bio
        avatar: '', // JWT might not contain avatar
        friends: [], // JWT might not contain friends
      );
    } catch (e) {
      log.severe('Error decoding token: $e');
      return null;
    }
  }

  AuthService() {
    log.info('[AuthService] - Constructor called.');
  }

  String? get token => _token;
  AuthStatus get status => _status;

  Future<void> init() async {
    log.info('[AuthService] - Initializing...');
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null) {
      _status = AuthStatus.Authenticated;
      SocketService().connect(_token!); // Connect socket on init if authenticated
      log.info('[AuthService] - Initialized: Authenticated. Token present.');
    } else {
      _status = AuthStatus.Unauthenticated;
      log.info('[AuthService] - Initialized: Unauthenticated. No token.');
    }
    log.info('[AuthService] - Calling notifyListeners() after init.');
    notifyListeners();
  }

  Future<String?> getToken() async {
    if (_token != null) {
      return _token;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token'); // Update _token if read from prefs
    return _token;
  }

  Future<bool> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'username': username, 'password': password}),
    );

    if (response.statusCode == 201) {
      return true;
    } else {
      log.warning('Registration failed: ${response.body}');
      return false;
    }
  }

  Future<String?> login(String username, String password) async {
    log.info('[AuthService] - Attempting login for user: $username');
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, String>{'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      _token = responseData['token'];
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', _token!);
      SocketService().connect(_token!); // Connect socket on login
      _status = AuthStatus.Authenticated;
      log.info('[AuthService] - Login successful. Status: Authenticated. Token: $_token');
      log.info('[AuthService] - Calling notifyListeners() after login.');
      notifyListeners();
      return _token;
    } else {
      log.warning('[AuthService] - Login failed: ${response.body}');
      return null;
    }
  }

  Future<void> logout(BuildContext context) async {
    log.info('[AuthService] - Logging out.');

    // Reset all providers
    Provider.of<ChatProvider>(context, listen: false).reset();
    Provider.of<FriendsProvider>(context, listen: false).reset();
    Provider.of<ProfileProvider>(context, listen: false).reset();

    _token = null;
    _status = AuthStatus.Unauthenticated;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    SocketService().disconnect();
    log.info('[AuthService] - Logout complete. Status: Unauthenticated.');
    log.info('[AuthService] - Calling notifyListeners() after logout.');
    notifyListeners();
  }
}