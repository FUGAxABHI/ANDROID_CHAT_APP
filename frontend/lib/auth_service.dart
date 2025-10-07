import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final log = Logger('AuthService');

class AuthService with ChangeNotifier {
  final String baseUrl = 'http://localhost:3000/api/auth';
  String? _token;

  String? get token => _token;

  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    notifyListeners();
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
      SocketService().init(_token!); // Initialize SocketService with the new token
      notifyListeners();
      return _token;
    } else {
      log.warning('Login failed: ${response.body}');
      return null;
    }
  }

  Future<void> logout() async {
    _token = null;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    notifyListeners();
    SocketService().init(null); // Reset SocketService on logout
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}