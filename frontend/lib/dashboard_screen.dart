import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/chats_view.dart';
import 'package:frontend/friends_view.dart';
import 'package:frontend/profile_view.dart';
import 'package:frontend/socket_service.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

final log = Logger('DashboardScreen');

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final List<Widget> _views = [
    const ChatsView(),
    const FriendsView(),
    const ProfileView(),
  ];

  @override
  void dispose() {
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Chat App', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => Navigator.pushNamed(context, '/search_users'),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  Provider.of<AuthService>(context, listen: false).logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: IndexedStack(
            index: _selectedIndex,
            children: _views,
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: 'Chats',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Friends',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            elevation: 10,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}