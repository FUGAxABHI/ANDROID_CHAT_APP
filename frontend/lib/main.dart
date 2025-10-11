import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:frontend/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:frontend/chat_screen.dart';
import 'package:frontend/dashboard_screen.dart';
import 'package:frontend/friends_list_screen.dart';
import 'package:frontend/login_screen.dart';
import 'package:frontend/private_chat_screen.dart';
import 'package:frontend/profile_settings_screen.dart';
import 'package:frontend/registration_screen.dart';
import 'package:frontend/search_users_screen.dart';
import 'package:frontend/friend_requests_screen.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:frontend/socket_service.dart';
import 'package:frontend/api_service.dart';
import 'package:frontend/auth_service.dart';
import 'package:frontend/user_service.dart';
import 'package:frontend/notification_service.dart';
import 'package:frontend/friends_service.dart';
import 'package:frontend/user_profile_screen.dart';
import 'package:frontend/mutual_friends_screen.dart';
import 'package:frontend/socket_service.dart';
import 'package:frontend/splash_screen.dart';
import 'package:frontend/chat_service.dart';
import 'package:frontend/api_service.dart'; // Added import for ApiService

final log = Logger('main');

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Setup logging
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  // Initialize services
  final authService = AuthService();
  await authService.init();

  final notificationService = NotificationService();
  notificationService.init(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        Provider<ApiService>(
          create: (context) => ApiService(() => Provider.of<AuthService>(context, listen: false).getToken()),
        ),
        Provider<UserService>(
          create: (context) => UserService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(
            Provider.of<ApiService>(context, listen: false),
            Provider.of<AuthService>(context, listen: false),
            Provider.of<UserService>(context, listen: false),
          ),
        ),
        ChangeNotifierProvider(create: (context) => ProfileProvider()),
        Provider<FriendsService>(
          create: (context) => FriendsService(Provider.of<ApiService>(context, listen: false)),
        ),
        Provider<ChatService>(
          create: (context) => ChatService(Provider.of<ApiService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendsProvider(Provider.of<FriendsService>(context, listen: false)),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Chat App',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.orbitronTextTheme(Theme.of(context).textTheme).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/home': (context) => const DashboardScreen(),
        '/chat': (context) => const ChatScreen(),
        '/profile_settings': (context) => const ProfileSettingsScreen(),
        '/friends_list': (context) => const FriendsListScreen(),
        '/search_users': (context) => const SearchUsersScreen(),
        '/friend_requests': (context) => const FriendRequestsScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user_profile') {
          final log = Logger('main');
          log.info('Navigating to /user_profile with arguments: ${settings.arguments}');
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return UserProfileScreen(userId: args['userId']!);
            },
          );
        } else if (settings.name == '/private_chat') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return PrivateChatScreen(friendUsername: args['friendUsername']!);
            },
          );
        } else if (settings.name == '/mutual_friends') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return MutualFriendsScreen(userId: args['userId']!);
            },
          );
        }
        return MaterialPageRoute(builder: (context) => const Text('Error: Unknown Route'));
      },
    );
  }
}
