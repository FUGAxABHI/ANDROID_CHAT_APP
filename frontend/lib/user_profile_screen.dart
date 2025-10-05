import 'package:flutter/material.dart';

class UserProfileScreen extends StatelessWidget {
  final String username;

  const UserProfileScreen({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${username}'s Profile"),
      ),
      body: Center(
        child: Text('This is the profile screen for $username'),
      ),
    );
  }
}
