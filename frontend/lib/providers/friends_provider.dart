import 'package:flutter/material.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/friend_request.dart';
import 'package:frontend/api/friends_service.dart';
import 'dart:async';
import 'package:frontend/services/socket_service.dart';

class FriendsProvider with ChangeNotifier {
  final FriendsService _friendsService;
  final SocketService _socketService = SocketService();
  StreamSubscription? _friendRequestSubscription;

  List<FriendRequest> _friendRequests = [];
  List<User> _friends = [];
  List<User> _mutualFriends = [];

  bool _isLoadingFriends = false;
  String? _friendsError;

  bool _isLoadingFriendRequests = false;
  String? _friendRequestsError;

  bool _isLoadingMutualFriends = false;
  String? _mutualFriendsError;

  List<FriendRequest> get friendRequests => _friendRequests;
  List<User> get friends => _friends;
  List<User> get mutualFriends => _mutualFriends;

  bool get isLoadingFriends => _isLoadingFriends;
  String? get friendsError => _friendsError;

  bool get isLoadingFriendRequests => _isLoadingFriendRequests;
  String? get friendRequestsError => _friendRequestsError;

  bool get isLoadingMutualFriends => _isLoadingMutualFriends;
  String? get mutualFriendsError => _mutualFriendsError;

  FriendsProvider(this._friendsService) {
    _listenToFriendEvents();
  }

  void _listenToFriendEvents() {
    _friendRequestSubscription = _socketService.friendRequestStream.listen((event) {
      final eventType = event['event'];
      final data = event['data'];

      if (eventType == 'new_friend_request') {
        _friendRequests.add(FriendRequest.fromJson(data));
        notifyListeners();
      } else if (eventType == 'friend_request_accepted') {
        getFriends(); // Refresh friends list
        getFriendRequests(); // Refresh requests list
        notifyListeners();
      }
    });
  }

  Future<void> getFriends() async {
    _isLoadingFriends = true;
    _friendsError = null;
    notifyListeners();

    try {
      final fetchedFriends = await _friendsService.getFriends();
      final uniqueFriends = <User>[];
      final seenIds = <String>{};
      for (var friend in fetchedFriends) {
        if (!seenIds.contains(friend.id)) {
          uniqueFriends.add(friend);
          seenIds.add(friend.id);
        }
      }
      _friends = uniqueFriends;
    } catch (e) {
      _friendsError = e.toString();
    }

    _isLoadingFriends = false;
    notifyListeners();
  }

  Future<void> getFriendRequests() async {
    _isLoadingFriendRequests = true;
    _friendRequestsError = null;
    notifyListeners();

    try {
      _friendRequests = await _friendsService.getFriendRequests();
    } catch (e) {
      _friendRequestsError = e.toString();
    }

    _isLoadingFriendRequests = false;
    notifyListeners();
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _friendsService.acceptFriendRequest(requestId);
      _friendRequests.removeWhere((req) => req.id == requestId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    try {
      await _friendsService.declineFriendRequest(requestId);
      _friendRequests.removeWhere((req) => req.id == requestId);
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  Future<void> sendFriendRequest(String username) async {
    try {
      await _friendsService.sendFriendRequest(username);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> getMutualFriends(String userId) async {
    _isLoadingMutualFriends = true;
    _mutualFriendsError = null;
    notifyListeners();

    try {
      _mutualFriends = await _friendsService.getMutualFriends(userId);
    } catch (e) {
      _mutualFriendsError = e.toString();
    }

    _isLoadingMutualFriends = false;
    notifyListeners();
  }

  void reset() {
    _friendRequests = [];
    _friends = [];
    _mutualFriends = [];
    _isLoadingFriends = false;
    _friendsError = null;
    _isLoadingFriendRequests = false;
    _friendRequestsError = null;
    _isLoadingMutualFriends = false;
    _mutualFriendsError = null;
    _friendRequestSubscription?.cancel();
    notifyListeners();
  }

  @override
  void dispose() {
    _friendRequestSubscription?.cancel();
    super.dispose();
  }
}
