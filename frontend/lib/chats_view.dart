import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/chat_service.dart';
import 'package:frontend/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

final log = Logger('ChatsView');

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  late Future<List<dynamic>> _recentChatsFuture;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    log.info('[ChatsView] initState: Fetching recent chats.');
    _recentChatsFuture = _fetchRecentChats();

    // Listen for incoming messages to refresh the chat list
    _messageSubscription = SocketService().messageStream.listen((_) {
      log.info('[ChatsView] Received new message, refreshing chat list.');
      // When a new message comes in, refresh the recent chats.
      // A delay is added to avoid excessive refreshes during initial message load.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            log.info('[ChatsView] Refreshing recent chats after message.');
            _recentChatsFuture = _fetchRecentChats();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    log.info('[ChatsView] dispose: Message subscription cancelled.');
    super.dispose();
  }

  Future<List<dynamic>> _fetchRecentChats() async {
    log.info('[ChatsView] _fetchRecentChats called.');
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId != null) {
      log.info('[ChatsView] Fetching recent chats for userId: $userId');
      final chats = await chatService.getRecentChats(userId);
      log.info('[ChatsView] Fetched ${chats.length} recent chats.');
      return chats;
    } else {
      log.warning('[ChatsView] No current user ID found. Returning empty chat list.');
      // Return an empty future if there's no user ID
      return Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _recentChatsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          log.info('[ChatsView] FutureBuilder: ConnectionState.waiting.');
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          log.severe('[ChatsView] FutureBuilder: Error loading chats: ${snapshot.error}');
          return Center(child: Text('Error loading chats: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          log.info('[ChatsView] FutureBuilder: No recent chats found.');
          return const Center(child: Text('No recent chats.'));
        }

        final recentChats = snapshot.data!;
        log.info('[ChatsView] FutureBuilder: Displaying ${recentChats.length} recent chats.');

        return ListView.builder(
          itemCount: recentChats.length,
          itemBuilder: (context, index) {
            final chat = recentChats[index];
            final unreadCount = chat['unreadCount'] ?? 0;

            return ListTile(
              leading: CircleAvatar(
                child: Text(chat['username'][0].toUpperCase()),
              ),
              title: Text(chat['username']),
              subtitle: Text(chat['lastMessage']?['message'] ?? 'Media message'),
              trailing: unreadCount > 0
                  ? CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    )
                  : null,
              onTap: () async {
                await Navigator.pushNamed(
                  context,
                  '/private_chat',
                  arguments: {'friendUsername': chat['username']},
                );
              },
            );
          },
        );
      },
    );
  }
}