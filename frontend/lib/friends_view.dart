import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:http/http.dart' as http;

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  List<dynamic> _friendRequests = [];
  List<dynamic> _friends = [];
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _getFriendRequests();
    _getFriends();
  }

  Future<void> _getFriendRequests() async {
    final token = await _authService.getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:3000/api/friends/requests'),
      headers: {'x-auth-token': token},
    );

    if (response.statusCode == 200) {
      setState(() {
        _friendRequests = json.decode(response.body);
      });
    }
  }

  Future<void> _getFriends() async {
    final token = await _authService.getToken();
    if (token == null) return;

    final response = await http.get(
      Uri.parse('http://localhost:3000/api/friends'),
      headers: {'x-auth-token': token},
    );

    if (response.statusCode == 200) {
      setState(() {
        _friends = json.decode(response.body);
      });
    }
  }

  Future<void> _acceptFriendRequest(String requestId) async {
    final token = await _authService.getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/friends/requests/$requestId/accept'),
      headers: {'x-auth-token': token},
    );

    if (response.statusCode == 200) {
      _getFriendRequests();
      _getFriends();
    }
  }

  Future<void> _declineFriendRequest(String requestId) async {
    final token = await _authService.getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/friends/requests/$requestId/decline'),
      headers: {'x-auth-token': token},
    );

    if (response.statusCode == 200) {
      _getFriendRequests();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.purple.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_friendRequests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Friend Requests', style: Theme.of(context).textTheme.headlineSmall),
            ),
          if (_friendRequests.isNotEmpty)
            Expanded(
              flex: 1,
              child: ListView.builder(
                itemCount: _friendRequests.length,
                itemBuilder: (context, index) {
                  final request = _friendRequests[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(request['sender']['username'][0].toUpperCase()),
                    ),
                    title: Text(request['sender']['username']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () => _acceptFriendRequest(request['_id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => _declineFriendRequest(request['_id']),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Friends', style: Theme.of(context).textTheme.headlineSmall),
          ),
          Expanded(
            flex: 2,
            child: ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final friendUsername = _friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Text(friendUsername[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  title: Text(friendUsername, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/private_chat',
                      arguments: {'friendUsername': friendUsername},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}