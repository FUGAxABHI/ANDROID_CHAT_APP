import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/friend_request.dart';
import 'package:frontend/api/api_service.dart';

class FriendsService with ChangeNotifier {
  final ApiService _api;

  FriendsService(this._api);

  Future<void> sendFriendRequest(String username) async {
    await _api.post('/api/friends/request', {'receiverUsername': username});
    notifyListeners();
  }

  Future<List<FriendRequest>> getFriendRequests() async {
    final data = await _api.get('/api/friends/requests');
    return (data as List).map((json) => FriendRequest.fromJson(json)).toList();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    await _api.post('/api/friends/requests/$requestId/accept', {});
    notifyListeners();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _api.post('/api/friends/requests/$requestId/decline', {});
    notifyListeners();
  }

  Future<List<User>> getFriends() async {
    final data = await _api.get('/api/friends');
    return (data as List).map((json) => User.fromJson(json)).toList();
  }

  Future<List<User>> getMutualFriends(String userId) async {
    final data = await _api.get('/api/friends/mutual/$userId');
    return (data as List).map((json) => User.fromJson(json)).toList();
  }
}
