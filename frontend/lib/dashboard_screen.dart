import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'dart:convert';
import 'package:frontend/friends_list_screen.dart';
import 'package:frontend/user_profile_screen.dart';
import 'package:frontend/chats_view.dart';
import 'package:frontend/friends_view.dart';
import 'package:frontend/profile_view.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  String? _username;
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadUsername() async {
    final token = await _authService.getToken();
    if (token != null) {
      try {
        final parts = token.split('.');
        if (parts.length != 3) {
          throw Exception('Invalid token');
        }
        final payload = json.decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
        setState(() {
          _username = payload['username'];
        });
      } catch (e) {
        print('Error decoding token: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, '/search_users'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chats'),
            Tab(icon: Icon(Icons.people), text: 'Friends'),
            Tab(icon: Icon(Icons.person), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ChatsView(),
          const FriendsView(),
          _username != null ? ProfileView(username: _username!) : const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _buildChatsView() {
    // Placeholder for chats view
    return const Center(
      child: Text('Recent chats will be displayed here.', style: TextStyle(color: Colors.white)),
    );
  }
}
