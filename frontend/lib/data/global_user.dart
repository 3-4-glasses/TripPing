class UserSession {
  static final UserSession _instance = UserSession._internal();

  // Factory constructor to return the same instance every time
  factory UserSession() => _instance;

  String uid = '';
  String name = '';

  // Private internal constructor
  UserSession._internal();

  // Add this getter to access the instance
  static UserSession get instance => _instance;
}
