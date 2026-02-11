import 'dart:async';
import 'package:flutter/foundation.dart'; // ✅ REQUIRED FOR WEB
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'WelcomePage.dart';
import 'screens/login_page.dart';
import 'screens/candidate_dashboard.dart';

/// GLOBAL ScaffoldMessenger (useful for Snackbars)
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ REQUIRED for Flutter Web + SharedPreferences
  if (kIsWeb) {
    await SharedPreferences.getInstance();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'Admin App',
      theme: ThemeData(
        primaryColor: Colors.blue.shade700,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        useMaterial3: false,
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= SPLASH SCREEN =================

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');
    final role = prefs.getString('user_role');
    final loginTime = prefs.getInt('login_time');

    // 24 hours in milliseconds
    const sessionDuration = 24 * 60 * 60 * 1000;

    final delay = kIsWeb ? 1500 : 1200;

    Timer(Duration(milliseconds: delay), () async {
      if (!mounted) return;

      if (token != null &&
          token.isNotEmpty &&
          role == "CANDIDATE" &&
          loginTime != null) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final diff = now - loginTime;

        if (diff <= sessionDuration) {
          _navigateTo(const CandidateDashboard());
          return;
        }
      }

      // ❌ Session expired or invalid
      await prefs.clear();
      _navigateTo(const WelcomePage());
    });
  }

  void _navigateTo(Widget page) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ✅ Responsive sizes
    final logoSize = kIsWeb ? size.width.clamp(170, 250) : size.width * 0.28;

    final titleSize = kIsWeb ? size.width.clamp(28, 44) : size.width * 0.075;

    final subtitleSize = kIsWeb ? size.width.clamp(14, 18) : size.width * 0.04;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ===== BACKGROUND =====
          Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/india_bg.png', fit: BoxFit.cover),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.35),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ===== CONTENT =====
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/logo.png',
                    width: logoSize.toDouble(),
                    height: logoSize.toDouble(),
                    fit: BoxFit.cover,
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  "Admin Panel",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize.toDouble(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 2),
                        blurRadius: 6,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  "Monitor • Control • Analyze Elections",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleSize.toDouble(),
                    color: Colors.white70,
                    shadows: const [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
