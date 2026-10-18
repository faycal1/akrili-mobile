class ApiEndpoints {
  // Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String me = '/api/me';
  static const String deviceTokens = '/api/device-tokens';

  // V1 Shared
  static const String properties = '/api/v1/properties';
  static String property(int id) => '/api/v1/properties/$id';
  static String propertyAvailability(int id) => '/api/v1/properties/$id/availability';

  // V1 Guest
  static const String bookings = '/api/v1/bookings';
  static String booking(int id) => '/api/v1/bookings/$id';
  static const String favorites = '/api/v1/favorites';
  static String toggleFavorite(int propertyId) => '/api/v1/favorites/$propertyId/toggle';
  static const String reviews = '/api/v1/reviews';

  // V1 Host
  static const String hostProperties = '/api/v1/host/properties';
  static const String hostBookings = '/api/v1/host/bookings';
  static String acceptBooking(int id) => '/api/v1/bookings/$id/accept';
  static String rejectBooking(int id) => '/api/v1/bookings/$id/reject';

  // V1 Notifications
  static const String notifications = '/api/v1/notifications';
  static String readNotification(String id) => '/api/v1/notifications/$id/read';
  static const String readAllNotifications = '/api/v1/notifications/read-all';
}
