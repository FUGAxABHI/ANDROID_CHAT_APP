import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/screens/call_screen.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/screens/call_screen.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/theme.dart';
import 'package:frontend/widgets/stylish_message_bubble.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:record/record.dart';
import 'dart:io';

final log = Logger('PrivateChatScreen');

class PrivateChatScreen extends StatefulWidget {
  final String friendUsername;

  const PrivateChatScreen({super.key, required this.friendUsername});

  @override
  State<PrivateChatScreen> createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  late AnimationController _bgAnimationController;
  late Animation<double> _bgAnimation;

  @override
  void initState() {
    super.initState();
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.init(widget.friendUsername);

    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgAnimationController, curve: Curves.easeInOut),
    );

    SocketService().on('call-made', (data) {
      // Handle incoming call
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _sendMessage(ChatProvider chatProvider) {
    if (_messageController.text.isNotEmpty) {
      chatProvider.sendMessage(_messageController.text);
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleVoiceRecording(ChatProvider chatProvider) async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      if (path != null) {
        final file = File(path);
        final bytes = await file.readAsBytes();
        chatProvider.sendVoiceMessage(bytes);
      }
      setState(() => _isRecording = false);
    } else {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/recording.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.messages.isNotEmpty) {
          _scrollToBottom();
        }
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(),
          body: _buildBody(chatProvider),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            title: Text(widget.friendUsername, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.black.withOpacity(0.2),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.videocam),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(friendUsername: widget.friendUsername))),
              ),
              IconButton(
                icon: const Icon(Icons.call),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CallScreen(friendUsername: widget.friendUsername))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ChatProvider chatProvider) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          decoration: themeProvider.backgroundImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(themeProvider.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(const Color(0xFF0a0f21), const Color(0xFF10002b), _bgAnimation.value)!,
                      Color.lerp(const Color(0xFF10002b), const Color(0xFF0a0f21), _bgAnimation.value)!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
          child: child,
        );
      },
      child: Column(
        children: [
          Expanded(
            child: chatProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : chatProvider.error != null
                    ? Center(child: Text('Error: ${chatProvider.error}'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: chatProvider.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatProvider.messages[index];
                          final isMe = message['sender']?['username'] != widget.friendUsername;
                          return StylishMessageBubble(message: message, isMe: isMe);
                        },
                      ),
          ),
          _buildMessageInputField(chatProvider),
        ],
      ),
    );
  }

  Widget _buildMessageInputField(ChatProvider chatProvider) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(12.0),
          color: Colors.black.withOpacity(0.2),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.attach_file, color: Theme.of(context).colorScheme.primary),
                onPressed: () => chatProvider.sendFile(),
              ),
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.poppins(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.mic, color: _isRecording ? Colors.cyan : Colors.white70),
                onPressed: () => _handleVoiceRecording(chatProvider),
              ),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                onPressed: () => _sendMessage(chatProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
