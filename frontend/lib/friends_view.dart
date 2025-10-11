import 'package:flutter/material.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';

class FriendsView extends StatefulWidget {
  const FriendsView({super.key});

  @override
  State<FriendsView> createState() => _FriendsViewState();
}

class _FriendsViewState extends State<FriendsView> {
  @override
  void initState() {
    super.initState();
    // Fetch initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FriendsProvider>(context, listen: false).getFriendRequests();
      Provider.of<FriendsProvider>(context, listen: false).getFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FriendsProvider>(
      builder: (context, provider, child) {
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
              if (provider.isLoadingFriendRequests)
                const Center(child: CircularProgressIndicator()),
              if (provider.friendRequests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Friend Requests', style: Theme.of(context).textTheme.headlineSmall),
                ),
              if (provider.friendRequests.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: provider.friendRequests.length,
                    itemBuilder: (context, index) {
                      final request = provider.friendRequests[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(request.sender.username[0].toUpperCase()),
                        ),
                        title: Text(request.sender.username),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => provider.acceptFriendRequest(request.id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => provider.declineFriendRequest(request.id),
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
              if (provider.isLoadingFriends)
                const Center(child: CircularProgressIndicator()),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: provider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = provider.friends[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: Text(friend.username[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      title: Text(friend.username, style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/private_chat',
                          arguments: {'friendUsername': friend.username},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
