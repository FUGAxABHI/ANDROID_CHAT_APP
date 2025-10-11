import 'package:frontend/models/user.dart';

class FriendRequest {
  final String id;
  final User sender;
  final String status;

  FriendRequest({
    required this.id,
    required this.sender,
    required this.status,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['_id'],
      sender: User.fromJson(json['sender']),
      status: json['status'],
    );
  }
}
