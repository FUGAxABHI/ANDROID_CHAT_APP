import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/api/user_service.dart';

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
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _userService.getUserProfile(userId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(String bio, String avatar, String language) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(bio, avatar, language);
      // After updating, refresh the user profile
      if (_user != null) {
        await getUserProfile(_user!.id);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(String imagePath) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final avatarUrl = await _userService.uploadAvatar(imagePath);
      if (_user != null) {
        _user = _user!.copyWith(avatar: avatarUrl);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void reset() {
    _user = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}