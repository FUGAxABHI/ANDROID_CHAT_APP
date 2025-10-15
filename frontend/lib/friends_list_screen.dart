import 'package:flutter/material.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/config.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<FriendsProvider>(context, listen: false).getFriends();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1),
            onPressed: () {
              Navigator.pushNamed(context, '/friend_requests');
            },
          ),
        ],
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoadingFriends) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendsProvider.friendsError != null) {
            return Center(child: Text('Error: ${friendsProvider.friendsError}'));
          }

          if (friendsProvider.friends.isEmpty) {
            return const Center(child: Text('No friends yet'));
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade800, Colors.purple.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ListView.builder(
              itemCount: friendsProvider.friends.length,
              itemBuilder: (context, index) {
                final friend = friendsProvider.friends[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(friend.avatar),
                  ),
                  title: Text(friend.username, style: const TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/user_profile',
                      arguments: {'userId': friend.id},
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/search_users');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
