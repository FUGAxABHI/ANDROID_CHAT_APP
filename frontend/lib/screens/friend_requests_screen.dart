import 'package:flutter/material.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<FriendsProvider>(context, listen: false).getFriendRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Requests'),
      ),
      body: Consumer<FriendsProvider>(
        builder: (context, friendsProvider, child) {
          if (friendsProvider.isLoadingFriendRequests) {
            return Center(child: CircularProgressIndicator());
          }

          if (friendsProvider.friendRequestsError != null) {
            return Center(child: Text('Error: ${friendsProvider.friendRequestsError}'));
          }

          if (friendsProvider.friendRequests.isEmpty) {
            return Center(child: Text('No friend requests'));
          }

          return ListView.builder(
            itemCount: friendsProvider.friendRequests.length,
            itemBuilder: (context, index) {
              final request = friendsProvider.friendRequests[index];
              return Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(request.sender.avatar),
                  ),
                  title: Text(request.sender.username),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () {
                          friendsProvider.acceptFriendRequest(request.id);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          friendsProvider.declineFriendRequest(request.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
