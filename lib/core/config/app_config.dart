class AppConfig {
  // API Configuration
  static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  // static const String baseUrl =
  //     'http://10.70.173.254:8000/api'; // iOS simulator
  // static const String baseUrl = 'https://your-domain.com/api'; // Production

  static const String mobileApiPrefix = '/mobile';

  // Endpoints
  static const String loginEndpoint = '$mobileApiPrefix/login';
  static const String logoutEndpoint = '$mobileApiPrefix/logout';
  static const String meEndpoint = '$mobileApiPrefix/me';
  static const String changePasswordEndpoint =
      '$mobileApiPrefix/change-password';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
