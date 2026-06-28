class ApiConfig {
  static const bool isProduction = false;

  // For Android Emulator - use 10.0.2.2 to access localhost
  // For iOS Simulator - use 127.0.0.1
  // For Physical Device - use your computer's IP address
  static String get baseUrl => isProduction
      ? 'https://api.patapoa.co.tz/api/v1'
      : 'http://10.0.2.2:9000/api/v1';

  // Auth Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authOtpSend = '/auth/otp/send';
  static const String authOtpVerify = '/auth/otp/verify';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authMe = '/auth/me';

  // User Endpoints
  static const String users = '/users';
  static String userUpdate(int id) => '/users/$id';
  static String userUpdateLocation(int id) => '/users/$id/location';
  static String userUpdateFcmToken(int id) => '/users/$id/fcm-token';

  // Addresses Endpoints
  static const String addresses = '/addresses';
  static String address(int id) => '/addresses/$id';
  static String addressSetDefault(int id) => '/addresses/$id/default';

  // Categories Endpoints
  static const String categories = '/categories';
  static String category(int id) => '/categories/$id';

  // Product Endpoints
  static const String products = '/products';
  static String product(int id) => '/products/$id';

  // Order Endpoints
  static const String customerOrders = '/customer/orders';
  static String customerOrder(int id) => '/customer/orders/$id';
  static String orderTracking(int id) => '/orders/$id/tracking';
  static String orderCancel(int id) => '/orders/$id/cancel';

  // Payment Endpoints
  static const String paymentsInitiate = '/payments/initiate';
  static const String paymentsCallback = '/payments/callback';

  // Merchant Endpoints
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantOrders = '/merchant/orders';
  static const String merchantProducts = '/merchant/products';
  static String merchantProduct(int id) => '/merchant/products/$id';
  static String merchantUpdateOrderStatus(int id) =>
      '/merchant/orders/$id/status';

  // Rider Endpoints
  static const String riderLocation = '/rider/location';
  static const String riderOnline = '/rider/online';
  static const String riderOffline = '/rider/offline';
  static const String riderAvailableOrders = '/rider/available-orders';
  static String riderAcceptOrder(int id) => '/rider/orders/$id/accept';
  static String riderUpdateOrderStatus(int id) => '/rider/orders/$id/status';
  static const String riderEarnings = '/rider/earnings';
  static const String riderPayoutRequest = '/rider/payout/request';
  static const String riderOrders = '/rider/orders';
  static const String riderProfile = '/rider/profile';

  // Wallet & Transactions
  static const String wallet = '/wallet';
  static const String transactions = '/transactions';

  // Upload Endpoints
  static const String uploadImage = '/uploads/image';

  // Notifications
  static const String notifications = '/notifications';
  static String notificationMarkRead(int id) => '/notifications/$id/read';
  static const String notificationsMarkAllRead = '/notifications/read-all';
}
