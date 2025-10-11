import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/models/user.dart';

import 'package:frontend/config.dart';

class UserService {
  final String _baseUrl = '${AppConfig.baseUrl}/api'; // Should be configurable

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<User> getUserProfile(String userId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/profile/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<void> updateUserProfile(String bio, String avatar) async {
    final token = await _getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/users/profile'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
      body: jsonEncode({
        'bio': bio,
        'avatar': avatar,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update user profile');
    }
  }

  Future<List<User>> searchUsers(String query) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/search?query=$query'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users');
    }
  }

  Future<User?> getUserByUsername(String username) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/users/username/$username'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token ?? '',
      },
    );

    if (response.statusCode == 200) {
      // The backend wraps the user object in a "user" key
      final data = jsonDecode(response.body);
      if (data.containsKey('user')) {
        return User.fromJson(data['user']);
      }
    }
    return null;
  }
}
