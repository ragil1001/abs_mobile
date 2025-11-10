class AppConfig {
  // API Configuration
  // static const String baseUrl = 'http://10.0.2.2:8000/api'; // Android emulator
  //   static const String baseUrl =
  //       'http://10.70.173.254:8000/api'; // iOS simulator
  static const String baseUrl =
      'https://irreparable-arnav-creamier.ngrok-free.dev/api'; // Production

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

  static const String storeFcmTokenEndpoint = '/mobile/notifications/fcm-token';
  static const String deleteFcmTokenEndpoint =
      '/mobile/notifications/fcm-token';
  static const String notificationsEndpoint = '/mobile/notifications';
  static const String notificationUnreadCountEndpoint =
      '/mobile/notifications/unread-count';
  static const String informasiEndpoint = '/mobile/informasi';
}
