import 'package:flutter/material.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:provider/provider.dart';

import 'package:frontend/widgets/glassmorphic_container.dart';

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (provider.isLoadingFriendRequests)
                Center(child: CircularProgressIndicator()),
              if (provider.friendRequests.isNotEmpty)
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Friend Requests', style: Theme.of(context).textTheme.headlineSmall),
                ),
              if (provider.friendRequests.isNotEmpty)
                Expanded(
                  flex: 1,
                  child: ListView.builder(
                    itemCount: provider.friendRequests.length,
                    itemBuilder: (context, index) {
                      final request = provider.friendRequests[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: GlassmorphicContainer(
                          borderRadius: BorderRadius.circular(15),
                          blurStrength: 10,
                          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                            width: 1.0,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(request.sender.username[0].toUpperCase()),
                            ),
                            title: Text(request.sender.username),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => provider.acceptFriendRequest(request.id),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => provider.declineFriendRequest(request.id),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Friends', style: Theme.of(context).textTheme.headlineSmall),
              ),
              if (provider.isLoadingFriends)
                Center(child: CircularProgressIndicator()),
              Expanded(
                flex: 2,
                child: ListView.builder(
                  itemCount: provider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = provider.friends[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: GlassmorphicContainer(
                        borderRadius: BorderRadius.circular(15),
                        blurStrength: 10,
                        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.3),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                          width: 1.0,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Text(friend.username[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          title: Text(friend.username, style: TextStyle(color: Colors.white)),
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/private_chat',
                              arguments: {'friendUsername': friend.username},
                            );
                          },
                        ),
                      ),
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