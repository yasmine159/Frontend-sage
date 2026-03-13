
// Holds the logged-in user in memory for the session.
class AuthUser {
  final int    id;
  final String username;
  final String email;
  final String role;
  final String token;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.token,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
}

class AuthService {
  // Singleton
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  bool      get isLoggedIn  => _currentUser != null;

  void setUser(AuthUser user) => _currentUser = user;
  void logout()               => _currentUser = null;
}