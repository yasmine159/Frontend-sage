import 'package:flutter/material.dart';
import 'package:frontend_sage3/pages/admin/AdminDashboardPage.dart';
import 'package:frontend_sage3/pages/auth/LoginPage.dart';
import 'package:frontend_sage3/pages/auth/RegisterPage.dart';
import 'package:frontend_sage3/pages/client/HomePage.dart';
import 'package:frontend_sage3/pages/client/MappingPage.dart';
import 'package:frontend_sage3/pages/auth/ResetPasswordPage.dart';
import 'package:frontend_sage3/app_strings.dart';

void main() {
  runApp(SageX3App());
}

// ══════════════════════════════════════════════════════════════════════════════
//  APP STATE — notifier observable par tous les descendants
// ══════════════════════════════════════════════════════════════════════════════
class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String    _lang      = 'fr';

  bool        get isDarkMode  => _themeMode == ThemeMode.dark;
  ThemeMode   get themeMode   => _themeMode;
  String      get currentLang => _lang;
  AppStrings  get strings     => AppStrings(_lang);

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setLang(String lang) {
    if (_lang == lang) return;
    _lang = lang;
    notifyListeners();
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  INHERITED NOTIFIER — propagé dans tout l'arbre
// ══════════════════════════════════════════════════════════════════════════════
class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  // ✅ Tout widget qui appelle .of(context) se rebuild quand AppState change
  static AppState of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateScope>()!
        .notifier!;
  }

  // Pour la compatibilité avec l'ancien SageX3App.of(context)
  static AppState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AppStateScope>()
        ?.notifier;
  }
}

// ══════════════════════════════════════════════════════════════════════════════
//  SAGE X3 APP
// ══════════════════════════════════════════════════════════════════════════════
class SageX3App extends StatefulWidget {
  // Compatibilité avec l'ancien code : SageX3App.of(context)
  static AppState? of(BuildContext context) => AppStateScope.maybeOf(context);

  @override
  State<SageX3App> createState() => _SageX3AppState();
}

class _SageX3AppState extends State<SageX3App> {
  final _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // AnimatedBuilder se rebuild quand _appState notifie
    return AnimatedBuilder(
      animation: _appState,
      builder: (context, _) {
        return AppStateScope(
          state: _appState,
          child: MaterialApp(
            title: 'SageX3 - Enterprise Management',
            debugShowCheckedModeBanner: false,
            themeMode: _appState.themeMode,

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
                headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Color(0xFF0F172A), elevation: 0),
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
                headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
              ),
              appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1E293B), foregroundColor: Colors.white, elevation: 0),
            ),

            routes: {
              '/':        (context) => LoginPage(),
              '/login':   (context) => LoginPage(),
              '/register':(context) => RegisterPage(),
              '/home':    (context) => HomePage(),
              '/admin':   (context) => AdminDashboardPage(),
              '/mapping': (context) => MappingPage(),
            },

            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '');
              if (uri.path == '/reset-password') {
                final token = uri.queryParameters['token'] ?? '';
                final email = uri.queryParameters['email'] ?? '';
                return MaterialPageRoute(
                  builder: (_) => ResetPasswordPage(token: token, email: email),
                );
              }
              return null;
            },

            initialRoute: '/',
          ),
        );
      },
    );
  }
}