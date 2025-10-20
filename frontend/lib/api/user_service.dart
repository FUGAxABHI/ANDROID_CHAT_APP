import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/api/api_service.dart';
import 'dart:typed_data';
import 'package:logging/logging.dart';

final log = Logger('UserService');

class UserService with ChangeNotifier {
  final ApiService _apiService;

  UserService(this._apiService);

  Future<User> getUserProfile(String userId) async {
    log.info('Getting user profile for user ID: $userId');
    final response = await _apiService.get('/api/users/profile/$userId');
    if (response.containsKey('user')) {
      log.info('User profile received for user ID: $userId');
      return User.fromJson(response['user']);
    }
    log.severe('User data not found in response for user ID: $userId');
    throw Exception('User data not found in response');
  }

  Future<void> updateUserProfile(String bio, String avatar, String language) async {
    log.info('Updating user profile');
    await _apiService.put('/api/users/profile', {
      'bio': bio,
      'avatar': avatar,
      'language': language,
    });
    log.info('User profile updated successfully');
    notifyListeners();
  }

  Future<List<User>> searchUsers(String query) async {
    log.info('Searching for users with query: $query');
    final response = await _apiService.get('/api/users/search?query=$query');
    final List<dynamic> data = response;
    log.info('Found ${data.length} users');
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User?> getUserByUsername(String username) async {
    log.info('Getting user by username: $username');
    final response = await _apiService.get('/api/users/username/$username');
    if (response.containsKey('user')) {
      log.info('User found with username: $username');
      return User.fromJson(response['user']);
    }
    log.info('User not found with username: $username');
    return null;
  }

  Future<String> uploadAvatar(Uint8List fileBytes, String filename) async {
    log.info('Uploading avatar: $filename');
    final response = await _apiService.uploadFile('/api/upload/avatar', fileBytes, filename);
    log.info('Avatar uploaded successfully. Avatar URL: ${response['avatarUrl']}');
    return response['avatarUrl'];
  }
}
