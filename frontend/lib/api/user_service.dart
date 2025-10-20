import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/api/api_service.dart';
import 'dart:typed_data';

class UserService with ChangeNotifier {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<User> getUserProfile(String userId) async {
    final response = await _apiService.get('/api/users/profile/$userId');
    if (response.containsKey('user')) {
      return User.fromJson(response['user']);
    }
    throw Exception('User data not found in response');
  }

  Future<void> updateUserProfile(String bio, String avatar, String language) async {
    await _apiService.put('/api/users/profile', {
      'bio': bio,
      'avatar': avatar,
      'language': language,
    });
    notifyListeners();
  }

  Future<List<User>> searchUsers(String query) async {
    final response = await _apiService.get('/api/users/search?query=$query');
    final List<dynamic> data = response;
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User?> getUserByUsername(String username) async {
    final response = await _apiService.get('/api/users/username/$username');
    if (response.containsKey('user')) {
      return User.fromJson(response['user']);
    }
    return null;
  }

  Future<String> uploadAvatar(Uint8List fileBytes, String filename) async {
    final response = await _apiService.uploadFile('/api/upload/avatar', fileBytes, filename);
    return response['avatarUrl'];
  }
}
