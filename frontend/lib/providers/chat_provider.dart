import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/auth_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logging/logging.dart';
import 'package:frontend/socket_service.dart';
import 'package:frontend/user_service.dart';

// Assuming Message and User models are defined somewhere, for now using Map<String, dynamic>
// import 'package:frontend/models/message.dart';
// import 'package:frontend/models/user.dart';

import 'package:frontend/api_service.dart';
import 'package:file_picker/file_picker.dart';

class ChatProvider with ChangeNotifier {
  final log = Logger('ChatProvider');
  final SocketService _socketService = SocketService();
  final ApiService _apiService;
  final AuthService _authService;
  final UserService _userService;

  ChatProvider(this._apiService, this._authService, this._userService);
  StreamSubscription? _messageSubscription;
  StreamSubscription? _readStatusSubscription;
  StreamSubscription? _historySubscription;

  List<dynamic> _messages = [];
  bool _isTyping = false;
  Set<String> _onlineUsers = {};
  String? _currentChatPartner;
  String? _chatPartnerId;
  bool _isLoading = false;
  String? _error;

  List<dynamic> get messages => _messages;
  bool get isTyping => _isTyping;
  Set<String> get onlineUsers => _onlineUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> init(String chatPartner) async {
    log.info('Initializing ChatProvider for: $chatPartner');
    _messages = [];
    _currentChatPartner = chatPartner;
    _isLoading = true;
    _error = null;
    log.info('ChatProvider: Setting _isLoading to true in init.');
    // Delay notification to avoid calling it during build
    Future.delayed(Duration.zero, () => notifyListeners());

    try {
      final user = await _userService.getUserByUsername(chatPartner);
      if (user != null) {
        _chatPartnerId = user.id;
      } else {
        _error = 'Could not find user: $chatPartner';
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _error = 'Error fetching user: $e';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Clean up any previous subscriptions
    _messageSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _historySubscription?.cancel();

    _historySubscription = _socketService.historyStream.listen((history) {
      log.info('Received message history with ${history.length} messages.');
      _messages = history;
      _messages.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
      _isLoading = false;
      notifyListeners();
    });

    // Listen to the global message stream for real-time updates
    _messageSubscription = _socketService.messageStream.listen((message) {
      log.info('ChatProvider: Received message from stream: $message');
      // Check if the message belongs to the current chat
      final senderData = message['sender'];
      String? sender;
      if (senderData is Map) {
        sender = senderData['username'];
      }

      final recipient = message['recipient']; // Recipient is an ID string

      // This logic needs to be robust. For now, we check if the sender or recipient matches
      // the chat partner. This is a simplified example.
      final currentUserId = _authService.currentUser?.id; // Assuming currentUser has an ID

      if (currentUserId == null || _chatPartnerId == null) {
        log.warning('ChatProvider: currentUserId or _chatPartnerId is null. Cannot filter message.');
        return;
      }

      if ((sender == _currentChatPartner && recipient == currentUserId) || // Message from chat partner to current user
          (recipient == _chatPartnerId && sender == _authService.currentUser?.username)) { // Message from current user to chat partner
         log.info('ChatProvider: Message is for current chat. Adding/updating message.');
         _addOrUpdateMessage(message);
      }
    }, onError: (error) {
      log.severe('Error on message stream: $error');
      _error = 'Connection lost.';
      _isLoading = false;
      log.info('ChatProvider: Setting _isLoading to false on stream error.');
      notifyListeners();
    });

    _readStatusSubscription = _socketService.readStatusStream.listen((data) {
      final byUser = data['byUser'];
      final withUser = data['withUser']; // The user whose messages were read

      // Check if the read receipt is relevant for the current chat
      if (byUser == _currentChatPartner && withUser == _authService.currentUser?.username) {
        log.info('Received read receipt from $_currentChatPartner');
        bool changed = false;
        for (var msg in _messages) {
          // Mark messages sent by the current user as read
          if (msg['sender']?['username'] == _authService.currentUser?.username && msg['isRead'] == false) {
            msg['isRead'] = true;
            changed = true;
          }
        }
        if (changed) {
          log.info('Messages updated with read status. Notifying listeners.');
          notifyListeners();
        }
      }
    });

    // Tell the socket service to fetch the history for this user
    _socketService.getMessageHistory(chatPartner);

    // Mark messages as read
    _socketService.markMessagesAsRead(chatPartner);
    
    // Set the active chat in the socket service to handle notifications correctly
    _socketService.setActiveChat(chatPartner);
  }

  void _addOrUpdateMessage(Map<String, dynamic> message) {
    log.info('ChatProvider: _addOrUpdateMessage called for message ID: ${message['_id']}');
    // Simple add for now. Optimistic UI can be improved here.
    final existingIndex = _messages.indexWhere((m) => m['_id'] == message['_id']);
    if (existingIndex == -1) {
        _messages.add(message);
        log.info('ChatProvider: Added new message. Total messages: ${_messages.length}');
    } else {
        _messages[existingIndex] = message;
        log.info('ChatProvider: Updated existing message ID: ${message['_id']}');
    }
    _messages.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
    if (_isLoading) {
      _isLoading = false;
      log.info('ChatProvider: Setting _isLoading to false after processing message.');
    }
    notifyListeners();
    log.info('ChatProvider: notifyListeners called in _addOrUpdateMessage.');
  }

  void sendMessage(String message, {String? mediaUrl, String? mediaType}) {
    if (_currentChatPartner == null) return;
    if (!_socketService.isConnected) {
      log.warning('Cannot send message. Socket not connected.');
      return;
    }
    log.info('ChatProvider: Sending message to $_currentChatPartner: $message');
    _socketService.sendMessage(_currentChatPartner!, message, mediaUrl: mediaUrl, mediaType: mediaType);
  }

  void sendVoiceMessage(List<int> voiceData) {
    if (_currentChatPartner == null) return;
    if (!_socketService.isConnected) {
      log.warning('Cannot send voice message. Socket not connected.');
      return;
    }
    _socketService.sendVoiceMessage(_currentChatPartner!, voiceData);
  }

  Future<void> sendFile() async {
    if (!_socketService.isConnected) {
      log.warning('Cannot send file. Socket not connected.');
      return;
    }
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      final path = result.files.single.path;
      if (path != null) {
        try {
          final response = await _apiService.uploadFile('/api/upload', path);
          final url = response['url'];
          // Determine media type based on file extension
          final mediaType = _getMediaType(path);
          _socketService.sendMessage(_currentChatPartner!, url, mediaType: mediaType);
        } catch (e) {
          log.severe('Failed to upload file: $e');
        }
      }
    }
  }

  String _getMediaType(String path) {
    final extension = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif'].contains(extension)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi'].contains(extension)) {
      return 'video';
    } else {
      return 'file';
    }
  }

  void sendTyping() {
    if (_currentChatPartner == null) return;
    _socketService.sendTyping(_currentChatPartner!);
  }

  void sendStopTyping() {
    if (_currentChatPartner == null) return;
    _socketService.sendStopTyping(_currentChatPartner!);
  }

  void reset() {
    log.info('Resetting ChatProvider');
    _messages = [];
    _isTyping = false;
    _onlineUsers = {};
    _currentChatPartner = null;
    _chatPartnerId = null;
    _isLoading = false;
    _error = null;
    _messageSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _historySubscription?.cancel();
    _socketService.setActiveChat(null);
    notifyListeners();
  }

  @override
  void dispose() {
    log.info('Disposing ChatProvider for $_currentChatPartner');
    _messageSubscription?.cancel();
    _readStatusSubscription?.cancel();
    _historySubscription?.cancel();
    _socketService.setActiveChat(null); // Clear active chat when leaving the screen
    super.dispose();
  }
}
