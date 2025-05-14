class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;

  String uid = '';
  String name = '';

  UserSession._internal();
}
