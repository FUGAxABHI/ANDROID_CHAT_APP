import 'package:frontend/config.dart';

class User {
  final String id;
  final String username;
  final String bio;
  final String avatar;
  final List<User> friends;
  final String language;

  User({
    required this.id,
    required this.username,
    required this.bio,
    required this.avatar,
    required this.friends,
    required this.language,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<User> friendsList = [];
    if (json['friends'] != null) {
      for (var friendData in json['friends']) {
        if (friendData is Map<String, dynamic>) {
          friendsList.add(User.fromJson(friendData));
        } else if (friendData is String) {
          // Handle case where friend is just an ID string
          friendsList.add(User(id: friendData, username: '...', bio: '', avatar: '', friends: [], language: 'en'));
        }
      }
    }

    String avatarUrl = json['avatar'] ?? '';
    if (avatarUrl.startsWith('/')) {
      avatarUrl = '${AppConfig.baseUrl}$avatarUrl';
    }

    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? 'Unknown User',
      bio: json['bio'] ?? '',
      avatar: avatarUrl,
      friends: friendsList,
      language: json['language'] ?? 'en',
    );
  }

  User copyWith({
    String? id,
    String? username,
    String? bio,
    String? avatar,
    List<User>? friends,
    String? language,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      friends: friends ?? this.friends,
      language: language ?? this.language,
    );
  }
}
