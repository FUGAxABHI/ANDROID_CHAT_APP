import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/auth_service.dart'; // Import AuthService
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences

final log = Logger('SearchUsersScreen');

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  bool _isLoading = false;
  final AuthService _authService = AuthService(); // Instantiate AuthService

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/users/search?query=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((user) => user['username'] as String).toList();
        });
      } else {
        log.warning('Error searching users: ${response.statusCode}');
      }
    } catch (e) {
      log.severe('Failed to connect to server: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendFriendRequest(String receiverUsername) async {
    final token = await _authService.getToken();
    if (token == null) {
      log.info('You must be logged in to send friend requests.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/friends/request'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(<String, String>{'receiverUsername': receiverUsername}),
      );

      final responseBody = json.decode(response.body);
      if (response.statusCode == 200) {
        log.info(responseBody['message']);
      } else {
        log.warning('Failed to send friend request: ${responseBody['message']}');
      }
    } catch (e) {
      log.severe('Error sending friend request: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by username',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _performSearch(_searchController.text);
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _performSearch,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final username = _searchResults[index];
                        return ListTile(
                          title: Text(username),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.person_add),
                                onPressed: () {
                                  _sendFriendRequest(username);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.message),
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/private_chat',
                                    arguments: {'friendUsername': username},
                                  );
                                },
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/user_profile',
                              arguments: {'username': username},
                            );
                          },
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
