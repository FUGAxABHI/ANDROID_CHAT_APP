import 'package:flutter/material.dart';
import 'package:frontend/auth_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize auth service when the splash screen is first built
    Provider.of<AuthService>(context, listen: false).init();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        switch (authService.status) {
          case AuthStatus.Authenticated:
            // Navigate to home after a short delay to show splash screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/home');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.Unauthenticated:
            // Navigate to login after a short delay to show splash screen
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacementNamed(context, '/login');
            });
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          case AuthStatus.Uninitialized:
          default:
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
        }
      },
    );
  }
}
