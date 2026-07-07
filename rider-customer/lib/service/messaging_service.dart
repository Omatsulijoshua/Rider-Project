import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:rider/service/shared_pref.dart';
import 'package:rider/service/api_client.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      recipientId: json['recipientId'] ?? '',
      message: json['message'] ?? '',
      timestamp:
          DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'recipientId': recipientId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}

class MessagingService {
  late io.Socket _socket;
  final String baseUrl = ApiClient.baseUrl.replaceAll('/api', '');

  Function(Message)? onMessageReceived;
  Function(List<Message>)? onMessagesLoaded;
  Function(String)? onUserTyping;
  Function()? onConnected;
  Function(dynamic)? onError;

  Future<void> initialize() async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();

      _socket = io.io(
        baseUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .build(),
      );

      _socket.onConnect((_) {
        debugPrint('✅ Chat connected');
        _socket.emit('joinChat', {'userId': userId});
        onConnected?.call();
      });

      _socket.on('newMessage', (data) {
        try {
          final message = Message.fromJson(Map<String, dynamic>.from(data));
          onMessageReceived?.call(message);
        } catch (e) {
          debugPrint('❌ Error parsing message: $e');
        }
      });

      _socket.on('messagesHistory', (data) {
        try {
          final messages = (data as List)
              .map((m) => Message.fromJson(Map<String, dynamic>.from(m)))
              .toList();
          onMessagesLoaded?.call(messages);
        } catch (e) {
          debugPrint('❌ Error parsing messages: $e');
        }
      });

      _socket.on('userTyping', (data) {
        onUserTyping?.call(data['userName'] ?? 'User');
      });

      _socket.onError((error) {
        debugPrint('❌ Chat error: $error');
        onError?.call(error);
      });

      _socket.connect();
    } catch (e) {
      debugPrint('❌ Failed to initialize messaging: $e');
      onError?.call(e);
    }
  }

  Future<void> sendMessage(String recipientId, String message) async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();
      final userName = await SharedpreferenceHelper().getUserName();

      _socket.emit('sendMessage', {
        'senderId': userId,
        'senderName': userName ?? 'Customer',
        'recipientId': recipientId,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'rideId': recipientId,
      });
    } catch (e) {
      debugPrint('❌ Failed to send message: $e');
      onError?.call(e);
    }
  }

  Future<void> loadChatHistory(String recipientId) async {
    try {
      final userId = await SharedpreferenceHelper().getUserID();
      _socket.emit('getChatHistory', {
        'userId': userId,
        'recipientId': recipientId,
      });
    } catch (e) {
      debugPrint('❌ Failed to load chat history: $e');
      onError?.call(e);
    }
  }

  void notifyTyping(String recipientId) {
    _socket.emit('typing', {
      'recipientId': recipientId,
      'userName': 'Customer',
    });
  }

  void markAsRead(String messageId) {
    _socket.emit('markAsRead', {'messageId': messageId});
  }

  void disconnect() {
    _socket.disconnect();
  }

  bool get isConnected => _socket.connected;
}
