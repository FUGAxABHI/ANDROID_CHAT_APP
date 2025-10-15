import 'package:flutter/material.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/auth_service.dart';
import 'dart:convert';
import 'package:frontend/config.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ProfileProvider>(context, listen: false).getUserProfile(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Consumer2<ProfileProvider, FriendsProvider>(
        builder: (context, profileProvider, friendsProvider, child) {
          if (profileProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (profileProvider.error != null) {
            return Center(child: Text('Error: ${profileProvider.error}'));
          }

          if (profileProvider.user == null) {
            return const Center(child: Text('No user data'));
          }

          final user = profileProvider.user!;

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.purple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user.username,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.bio,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Friends: ${user.friends.length}',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 40),
                  FutureBuilder<String?>(
                    future: _getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      final currentUserId = snapshot.data;
                      final isCurrentUser = currentUserId == widget.userId;

                      return Column(
                        children: [
                          if (isCurrentUser)
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/profile_settings');
                              },
                              icon: const Icon(Icons.edit),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                            ) else ...[
                              // Check if already friends
                              // For now, just show Add Friend. Will implement friend check later.
                                ElevatedButton.icon(
                                  onPressed: () {
                                    friendsProvider.sendFriendRequest(user.username);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Friend request sent to ${user.username}')),
                                    );
                                  },
                                  icon: const Icon(Icons.person_add),
                                  label: const Text('Add Friend'),
                                ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/private_chat',
                                    arguments: {'friendUsername': user.username},
                                  );
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('Message'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/friends_list');
                            },
                            icon: const Icon(Icons.people),
                            label: const Text('View Friends'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/mutual_friends',
                                arguments: {'userId': user.id},
                              );
                            },
                            icon: const Icon(Icons.group),
                            label: const Text('View Mutual Friends'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<String?> _getCurrentUserId() async {
        final authService = Provider.of<AuthService>(context, listen: false);
    final token = await authService.getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token');
        }
        final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        return payload['id'];
      } catch (e) {
        print('Error decoding token: $e');
        return null;
      }
    }
    return null;
  }
}