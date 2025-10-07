import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:frontend/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/chat_screen.dart';
import 'package:frontend/dashboard_screen.dart';
import 'package:frontend/friends_list_screen.dart';
import 'package:frontend/login_screen.dart';
import 'package:frontend/private_chat_screen.dart';
import 'package:frontend/profile_settings_screen.dart';
import 'package:frontend/registration_screen.dart';
import 'package:frontend/search_users_screen.dart';
import 'package:frontend/notification_service.dart';
import 'package:frontend/user_profile_screen.dart';
import 'package:frontend/socket_service.dart';

final log = Logger('main');

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final NotificationService notificationService = NotificationService();
  notificationService.init(navigatorKey);
  final AuthService authService = AuthService();
  await authService.init();
  final SocketService socketService = SocketService();
  final token = await authService.getToken();
  if (token != null) {
    socketService.init(token);
  }
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Flutter Chat App',
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: Colors.deepPurple,
            textTheme: GoogleFonts.orbitronTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
          ),
          home: authService.token != null ? const DashboardScreen() : const LoginScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegistrationScreen(),
            '/home': (context) => const DashboardScreen(),
            '/chat': (context) => const ChatScreen(),
            '/profile_settings': (context) => const ProfileSettingsScreen(),
            '/friends_list': (context) => const FriendsListScreen(),
            '/search_users': (context) => const SearchUsersScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/user_profile') {
              final log = Logger('main');
              log.info('Navigating to /user_profile with arguments: ${settings.arguments}');
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) {
                  return UserProfileScreen(username: args['username']!);
                },
              );
            } else if (settings.name == '/private_chat') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) {
                  return PrivateChatScreen(friendUsername: args['friendUsername']!);
                },
              );
            }
            return MaterialPageRoute(builder: (context) => const Text('Error: Unknown Route'));
          },
        );
      },
    );
  }
}