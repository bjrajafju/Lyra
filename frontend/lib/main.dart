import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/audio_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/main_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const LyraApp());
}

class LyraApp extends StatelessWidget {
  const LyraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: MaterialApp(
        title: 'Lyra — Music Discovery',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        routes: {
          '/register': (context) => const RegisterScreen(),
        },
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            // Auto login check
            if (!auth.hasCheckedAuth) {
              auth.tryAutoLogin();
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'LYRA',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: AppTheme.primary,
                        ),
                      ),
                      SizedBox(height: 20),
                      CircularProgressIndicator(color: AppTheme.primary),
                    ],
                  ),
                ),
              );
            }
            return auth.isAuthenticated ? const MainScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
