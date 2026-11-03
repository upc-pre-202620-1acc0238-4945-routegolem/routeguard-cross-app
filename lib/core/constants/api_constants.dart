class ApiConstants {
  static const String baseUrl = 'https://routeguard-web-services.onrender.com/api/v1';
  static const String localEmulatorUrl = 'http://10.0.2.2:5000/api/v1';

  static const String signInEndpoint = '/auth/sign-in';
  static const String activeTripEndpoint = '/trips/active';
  static const String stopsEndpoint = '/stops';
  static const String alertsEndpoint = '/notifications/alerts';

  static const Duration timeout = Duration(seconds: 25);
}
