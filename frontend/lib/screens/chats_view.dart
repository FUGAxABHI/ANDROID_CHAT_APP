import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/api/chat_service.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'package:frontend/widgets/glassmorphic_container.dart';

final log = Logger('ChatsView');

class ChatsView extends StatefulWidget {
  const ChatsView({super.key});

  @override
  State<ChatsView> createState() => _ChatsViewState();
}

class _ChatsViewState extends State<ChatsView> {
  late Future<List<dynamic>> _allConversationsFuture;
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    log.info('[ChatsView] initState: Fetching all conversations.');
    _allConversationsFuture = _fetchAllConversations();

    _messageSubscription = SocketService().messageStream.listen((_) {
      log.info('[ChatsView] Received new message, refreshing chat list.');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            log.info('[ChatsView] Refreshing all conversations after message.');
            _allConversationsFuture = _fetchAllConversations();
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

  Future<List<dynamic>> _fetchAllConversations() async {
    log.info('[ChatsView] _fetchAllConversations called.');
    final authService = Provider.of<AuthService>(context, listen: false);
    final chatService = Provider.of<ChatService>(context, listen: false);
    final userId = authService.currentUser?.id;

    if (userId != null) {
      log.info('[ChatsView] Fetching all conversations for userId: $userId');
      final chats = await chatService.getAllConversations(userId);
      log.info('[ChatsView] Fetched ${chats.length} conversations.');
      return chats;
    } else {
      log.warning('[ChatsView] No current user ID found. Returning empty chat list.');
      return Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _allConversationsFuture,
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
          log.info('[ChatsView] FutureBuilder: No conversations found.');
          return const Center(child: Text('No conversations yet.'));
        }

        final allConversations = snapshot.data!;
        log.info('[ChatsView] FutureBuilder: Displaying ${allConversations.length} conversations.');

        return ListView.builder(
          itemCount: allConversations.length,
          itemBuilder: (context, index) {
            final chat = allConversations[index];
            final unreadCount = chat['unreadCount'] ?? 0;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      chat['username'][0].toUpperCase(),
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    chat['username'],
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  subtitle: Text(
                    chat['lastMessage']?['message'] ?? 'Media message',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(color: Colors.white70),
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
                ),
              ),
            );
          },
        );
      },
    );
  }
}