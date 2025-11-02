class Environment {
  // URL Backend API
  // Émulateur Android : utilisez 10.0.2.2 au lieu de localhost
  // Appareil physique : utilisez votre IP locale (192.168.X.X)
  // Production : URL cloud (Railway, Render, etc.)

  static const String BASE_URL = 'http://10.0.2.2:8000';

  // Endpoints
  static const String LOGIN_ENDPOINT = '/api/auth/login';
  static const String REGISTER_ENDPOINT = '/api/auth/register';
  static const String ATTENDANCES_ENDPOINT = '/api/attendances';
  static const String UNKNOWN_FACES_ENDPOINT = '/api/unknown-faces';
  static const String EMPLOYEES_ENDPOINT = '/api/employees';

  // Clés de stockage
  static const String TOKEN_KEY = 'auth_token';
  static const String USER_KEY = 'user_data';

  // Timeout
  static const Duration TIMEOUT = Duration(seconds: 30);
}