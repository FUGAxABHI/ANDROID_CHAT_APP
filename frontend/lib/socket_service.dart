import 'dart:async';
import 'package:frontend/config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:frontend/notification_service.dart';
import 'package:logging/logging.dart';

final log = Logger('SocketService');

class SocketService {
  // --- Singleton Setup ---
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  // --- Private Properties ---
  IO.Socket? _socket;
  String? _activeChatUsername;
  final NotificationService _notificationService = NotificationService();
  late StreamController<Map<String, dynamic>> _messageController;
  late StreamController<Map<String, dynamic>> _friendRequestController;
  late StreamController<Map<String, dynamic>> _readStatusController;
  late StreamController<List<dynamic>> _historyController;
  List<dynamic>? _cachedHistory;

  // --- Public Properties ---
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get friendRequestStream => _friendRequestController.stream;
  Stream<Map<String, dynamic>> get readStatusStream => _readStatusController.stream;
  Stream<List<dynamic>> get historyStream => _historyController.stream;
  bool get isConnected => _socket?.connected ?? false;

  // Internal constructor
  SocketService._internal();

  // --- Public Methods ---

  void connect(String token) {

    // Disconnect any existing socket before creating a new one
    if (_socket != null && _socket!.connected) {
      log.info('A socket is already connected. Disconnecting before creating a new one.');
      disconnect();
    }

    log.info('Connecting socket with token...');

    // Create a new socket instance
    _socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true, // Automatically connect after initialization
      'auth': {
        'token': token,
      },
    });

    // Create new stream controllers for this session
    _messageController = StreamController.broadcast();
    _friendRequestController = StreamController.broadcast();
    _readStatusController = StreamController.broadcast();
    _historyController = StreamController.broadcast();

    _registerSocketEvents();
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.dispose();
      _socket = null;

      // Close all stream controllers to clean up
      _messageController.close();
      _friendRequestController.close();
      _readStatusController.close();
      _historyController.close();

      log.info('Socket disconnected and all streams closed.');
    }
  }

  void setActiveChat(String? username) {
    _activeChatUsername = username;
    log.info('Active chat set to: $username');
  }

  // --- Event Emitters ---

  void sendMessage(String to, String message, {String? mediaUrl, String? mediaType}) {
    if (_socket == null || !_socket!.connected) {
      log.warning('Cannot send message. Socket not connected.');
      return;
    }
    _socket!.emit('private message', {
      'to': to,
      'message': message,
      'isVoice': false,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
    });
  }

  void sendVoiceMessage(String to, List<int> voiceData) {
    if (_socket == null || !_socket!.connected) {
      log.warning('Cannot send voice message. Socket not connected.');
      return;
    }
    _socket!.emit('private message', {
      'to': to,
      'message': 'Voice Message', // Placeholder text
      'isVoice': true,
      'voiceData': voiceData,
    });
  }

  void sendTyping(String to) {
    _socket?.emit('typing', {'to': to});
  }

  void sendStopTyping(String to) {
    _socket?.emit('stop typing', {'to': to});
  }

  String? _lastHistoryUser;

  void getMessageHistory(String withUser) {
    log.info('Getting message history for $withUser');
    if (_lastHistoryUser == withUser && _cachedHistory != null) {
      log.info('Using cached history for $withUser');
      _historyController.add(_cachedHistory!);
    }
    _lastHistoryUser = withUser;
     _socket?.emit('get private messages', {'withUser': withUser});
  }

  void markMessagesAsRead(String withUser) {
    _socket?.emit('mark messages as read', {'withUser': withUser});
  }

  // --- Private Methods ---

  void _registerSocketEvents() {
    _socket!.onConnect((_) => log.info('Socket connected successfully: ${_socket!.id}'));
    _socket!.onDisconnect((_) => log.info('Socket disconnected.'));
    _socket!.onError((data) => log.severe('Socket Error: $data'));
    _socket!.on('connect_error', (data) => log.warning('Socket Connection Error: $data'));

    // Listen for incoming private messages
    _socket!.on('private message', (data) {
      final message = data['message'];
      _messageController.add(message);

      // Show a notification if the message is not for the currently active chat
      final senderUsername = message['sender']?['username'];
      if (senderUsername != null && _activeChatUsername != senderUsername) {
        _notificationService.showNotification(
          id: senderUsername.hashCode,
          title: 'New message from $senderUsername',
          body: message['message'] ?? 'Media message',
          payload: senderUsername, // To navigate to the chat on tap
        );
      }
    });





    // Listen for historical private messages (array of messages)
    _socket!.on('private messages', (data) {
      log.info('Received private messages from socket');
      if (data is List) {
        _cachedHistory = data.cast<Map<String, dynamic>>();
        _historyController.add(_cachedHistory!);
      }
    });
    // Listen for friend-related events
    _socket!.on('new_friend_request', (data) {
      log.info('Received new friend request: $data');
      _friendRequestController.add({'event': 'new_friend_request', 'data': data});
    });

    _socket!.on('friend_request_accepted', (data) {
      log.info('Friend request accepted: $data');
      _friendRequestController.add({'event': 'friend_request_accepted', 'data': data});
    });

    _socket!.on('messages marked as read', (data) {
      log.info('Messages marked as read: $data');
      _readStatusController.add(data);
    });
  }


}