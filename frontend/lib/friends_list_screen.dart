import 'package:flutter/material.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen> {
  // Placeholder for friends list. In a real app, this would come from backend.
  final List<String> _friends = ['user1', 'user2', 'testuser'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
      ),
      body: ListView.builder(
        itemCount: _friends.length,
        itemBuilder: (context, index) {
          final friendUsername = _friends[index];
          return ListTile(
            title: Text(friendUsername),
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
    );
  }
}
