import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/admin/AdminDashboardPage.dart';
import 'package:frontend_sage3/pages/auth/LoginPage.dart';
import 'package:frontend_sage3/pages/auth/RegisterPage.dart';
import 'package:frontend_sage3/pages/client/HomePage.dart';
import 'package:frontend_sage3/pages/client/MappingPage.dart';

void main() {
  runApp(SageX3App());
}

class SageX3App extends StatefulWidget {
  // Fixed the of method
  static _SageX3AppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_SageX3AppState>();
  }

  @override
  State<SageX3App> createState() => _SageX3AppState();
}

class _SageX3AppState extends State<SageX3App> {
  ThemeMode _themeMode = ThemeMode.light;

  // Method to get current theme mode
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SageX3 - Enterprise Management',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,

      // 🌞 LIGHT THEME
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),

        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1E3A8A),
          secondary: Color(0xFF3B82F6),
          surface: Colors.white,
          error: Color(0xFFEF4444),
        ),

        cardColor: Colors.white,
        dividerColor: Color(0xFFE2E8F0),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF60A5FA),
          surface: Color(0xFF1E293B),
          error: Color(0xFFEF4444),
        ),

        cardColor: const Color(0xFF1E293B),
        dividerColor: Color(0xFF334155),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF94A3B8),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E293B),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      routes: {
        '/': (context) => LoginPage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/admin': (context) => AdminDashboardPage(),
        'report' :(context) => RegisterPage(),
        '/mapping': (context) => MappingPage(),
      },

      initialRoute: '/',
    );
  }
}