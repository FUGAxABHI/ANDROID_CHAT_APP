import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:frontend/api/api_service.dart';
import 'package:frontend/api/chat_service.dart';
import 'package:frontend/api/friends_service.dart';
import 'package:frontend/api/user_service.dart';
import 'package:frontend/providers/call_provider.dart';
import 'package:frontend/providers/chat_provider.dart';
import 'package:frontend/providers/theme_provider.dart';
import 'package:frontend/providers/friends_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/screens/call_screen.dart';
import 'package:frontend/screens/chat_screen.dart';
import 'package:frontend/screens/dashboard_screen.dart';
import 'package:frontend/screens/friend_requests_screen.dart';
import 'package:frontend/screens/friends_list_screen.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/mutual_friends_screen.dart';
import 'package:frontend/screens/private_chat_screen.dart';
import 'package:frontend/screens/profile_settings_screen.dart';
import 'package:frontend/screens/registration_screen.dart';
import 'package:frontend/screens/search_users_screen.dart';
import 'package:frontend/screens/splash_screen.dart';
import 'package:frontend/screens/user_profile_screen.dart';
import 'package:frontend/services/auth_service.dart';
import 'package:frontend/services/socket_service.dart';
import 'package:frontend/theme.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import 'package:frontend/services/notification_service.dart';
import 'package:upgrader/upgrader.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'dart:io';

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
  final socketService = SocketService();
  socketService.init(navigatorKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider(
          create: (context) => ApiService(() => authService.getToken()),
        ),
        ChangeNotifierProvider(
          create: (context) => UserService(Provider.of<ApiService>(context, listen: false)),
        ),
        ChangeNotifierProvider.value(value: socketService),
        ChangeNotifierProvider(
          create: (context) => ProfileProvider(Provider.of<UserService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendsService(Provider.of<ApiService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatService(Provider.of<ApiService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(Provider.of<ApiService>(context, listen: false), authService, Provider.of<UserService>(context, listen: false)),
        ),
        ChangeNotifierProvider(
          create: (context) => FriendsProvider(Provider.of<FriendsService>(context, listen: false)),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(
          create: (context) => CallProvider(authService: Provider.of<AuthService>(context, listen: false)),
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isIOS = !kIsWeb && Platform.isIOS;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Flutter Chat App',
      theme: themeProvider.currentTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: UpgradeAlert(
        child: Container(
          decoration: themeProvider.backgroundImagePath != null
              ? BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(themeProvider.backgroundImagePath!)),
                    fit: BoxFit.cover,
                  ),
                )
              : const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/background.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
          child: themeProvider.currentTheme == AppTheme.glassTheme
              ? BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
                    child: const SplashScreen(),
                  ),
                )
              : const SplashScreen(),
        ),
      ),
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
        } else if (settings.name == '/call') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) {
              return CallScreen(
                friendUsername: args['friendUsername']!,
                offer: args['offer'],
              );
            },
          );
        }
        return MaterialPageRoute(builder: (context) => const Text('Error: Unknown Route'));
      },
    );
  }
}
