import 'package:flutter/material.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/auth_service.dart';
import 'dart:convert';
import 'package:frontend/config.dart';

import 'package:frontend/widgets/glassmorphic_container.dart';

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
        title: Text('User Profile'),
      ),
      body: Consumer2<ProfileProvider, FriendsProvider>(
        builder: (context, profileProvider, friendsProvider, child) {
          if (profileProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (profileProvider.error != null) {
            return Center(child: Text('Error: ${profileProvider.error}'));
          }

          if (profileProvider.user == null) {
            return Center(child: Text('No user data'));
          }

          final user = profileProvider.user!;

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GlassmorphicContainer(
                borderRadius: BorderRadius.circular(20),
                blurStrength: 10,
                backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                  width: 1.0,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: NetworkImage(user.avatar),
                  ),
                  SizedBox(height: 20),
                  Text(
                    user.username,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    user.bio,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Friends: ${user.friends.length}',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 40),
                  FutureBuilder<String?>(
                    future: _getCurrentUserId(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }
                      final currentUserId = snapshot.data;
                      final isCurrentUser = currentUserId == widget.userId;

                      return Column(
                        children: [
                          if (isCurrentUser)
                            GlassmorphicContainer(
                              borderRadius: BorderRadius.circular(15),
                              blurStrength: 5,
                              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                width: 1.0,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/profile_settings');
                                },
                                icon: Icon(Icons.edit, color: Colors.white),
                                label: Text('Edit Profile', style: TextStyle(color: Colors.white)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                  textStyle: TextStyle(fontSize: 18),
                                ),
                              ),
                            ) else ...[
                              // Check if already friends
                              // For now, just show Add Friend. Will implement friend check later.
                                GlassmorphicContainer(
                                  borderRadius: BorderRadius.circular(15),
                                  blurStrength: 5,
                                  backgroundColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.4),
                                    width: 1.0,
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      friendsProvider.sendFriendRequest(user.username);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Friend request sent to ${user.username}')),
                                      );
                                    },
                                    icon: Icon(Icons.person_add, color: Colors.white),
                                    label: Text('Add Friend', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                    ),
                                  ),
                                ),
                              SizedBox(height: 10),
                              GlassmorphicContainer(
                                borderRadius: BorderRadius.circular(15),
                                blurStrength: 5,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                                  width: 1.0,
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/private_chat',
                                      arguments: {'friendUsername': user.username},
                                    );
                                  },
                                  icon: Icon(Icons.message, color: Colors.white),
                                  label: Text('Message', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                    textStyle: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ],
                          SizedBox(height: 10),
                          GlassmorphicContainer(
                            borderRadius: BorderRadius.circular(15),
                            blurStrength: 5,
                            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              width: 1.0,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(context, '/friends_list');
                              },
                              icon: Icon(Icons.people, color: Colors.white),
                              label: Text('View Friends', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                textStyle: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          GlassmorphicContainer(
                            borderRadius: BorderRadius.circular(15),
                            blurStrength: 5,
                            backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                              width: 1.0,
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/mutual_friends',
                                  arguments: {'userId': user.id},
                                );
                              },
                              icon: Icon(Icons.group, color: Colors.white),
                              label: Text('View Mutual Friends', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                textStyle: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
                                              ),
                                            ),
                                          )));        },
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