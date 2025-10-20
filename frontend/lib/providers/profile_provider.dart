import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/api/user_service.dart';
import 'dart:typed_data';
import 'package:logging/logging.dart';

final log = Logger('ProfileProvider');

class ProfileProvider with ChangeNotifier {
  final UserService _userService;

  ProfileProvider(this._userService);

  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getUserProfile(String userId) async {
    log.info('Getting user profile for user ID: $userId');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _userService.getUserProfile(userId);
      log.info('User profile loaded for user ID: $userId');
    } catch (e) {
      _error = e.toString();
      log.severe('Error getting user profile: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(String bio, String avatar, String language) async {
    log.info('Updating user profile');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(bio, avatar, language);
      log.info('User profile updated, refreshing user data');
      // After updating, refresh the user profile
      if (_user != null) {
        await getUserProfile(_user!.id);
      }
    } catch (e) {
      _error = e.toString();
      log.severe('Error updating user profile: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(Uint8List fileBytes, String filename) async {
    log.info('Uploading profile picture: $filename');
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final avatarUrl = await _userService.uploadAvatar(fileBytes, filename);
      log.info('Profile picture uploaded, new avatar URL: $avatarUrl');
      if (_user != null) {
        _user = _user!.copyWith(avatar: avatarUrl);
      }
    } catch (e) {
      _error = e.toString();
      log.severe('Error uploading profile picture: $_error');
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    log.info('Resetting profile provider');
    _user = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}