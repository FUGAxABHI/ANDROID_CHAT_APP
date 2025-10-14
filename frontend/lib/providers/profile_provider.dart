import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/user_service.dart';

class ProfileProvider with ChangeNotifier {
  final UserService _userService = UserService();

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

  Future<void> updateUserProfile(String bio, String avatar) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.updateUserProfile(bio, avatar);
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

  void reset() {
    _user = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}