class ApiConstants {
  static const String baseUrl = 'https://routeguard-web-services.onrender.com/api/v1';
  static const String localEmulatorUrl = 'http://10.0.2.2:5000/api/v1';

  static const String signInEndpoint = '/users/sign-in';
  static const String signInFallbackEndpoint = '/auth/sign-in';
  static const String liveTripsEndpoint = '/trips/live';
  static const String activeTripEndpoint = '/trips/live';
  static const String tripsEndpoint = '/trips';
  static const String stopsEndpoint = '/stops';
  static const String alertsEndpoint = '/notifications';
  static const String driversEndpoint = '/drivers';
  static const String parentsEndpoint = '/parents';
  static const String studentGroupsEndpoint = '/student-groups';
  static const String routesEndpoint = '/routes';
  static const String vehiclesEndpoint = '/vehicles';
  static const String plansEndpoint = '/plans';
  static const String subscriptionsEndpoint = '/subscriptions';

  static const Duration timeout = Duration(seconds: 25);
}
