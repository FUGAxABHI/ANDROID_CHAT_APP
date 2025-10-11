class User {
  final String id;
  final String username;
  final String bio;
  final String avatar;
  final List<User> friends;

  User({
    required this.id,
    required this.username,
    required this.bio,
    required this.avatar,
    required this.friends,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<User> friendsList = [];
    if (json['friends'] != null) {
      for (var friendData in json['friends']) {
        if (friendData is Map<String, dynamic>) {
          friendsList.add(User.fromJson(friendData));
        } else if (friendData is String) {
          // Handle case where friend is just an ID string
          friendsList.add(User(id: friendData, username: '...', bio: '', avatar: '', friends: []));
        }
      }
    }

    return User(
      id: json['_id'],
      username: json['username'],
      bio: json['bio'] ?? '',
      avatar: json['avatar'] ?? '',
      friends: friendsList,
    );
  }
}
