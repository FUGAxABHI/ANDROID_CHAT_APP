import 'package:flutter/material.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class MutualFriendsScreen extends StatefulWidget {
  final String userId;

  const MutualFriendsScreen({super.key, required this.userId});

  @override
  State<MutualFriendsScreen> createState() => _MutualFriendsScreenState();
}

class _MutualFriendsScreenState extends State<MutualFriendsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<FriendsProvider>(context, listen: false).getMutualFriends(widget.userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutual Friends'),
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoadingMutualFriends) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendsProvider.mutualFriendsError != null) {
            return Center(child: Text('Error: ${friendsProvider.mutualFriendsError}'));
          }

          if (friendsProvider.mutualFriends.isEmpty) {
            return const Center(child: Text('No mutual friends'));
          }

          return ListView.builder(
            itemCount: friendsProvider.mutualFriends.length,
            itemBuilder: (context, index) {
              final friend = friendsProvider.mutualFriends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(friend.avatar),
                ),
                title: Text(friend.username),
                onTap: () {
                  // Navigate to mutual friend's profile
                  Navigator.pushNamed(
                    context,
                    '/user_profile',
                    arguments: {'userId': friend.id},
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
