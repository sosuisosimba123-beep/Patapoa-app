import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const bool isProduction = true;

  // For Android Emulator - use 10.0.2.2 to access localhost
  // For iOS Simulator - use 127.0.0.1
  // For Physical Device - use your computer's IP address
  static String get baseUrl {
    if (isProduction) {
      return 'https://patapoa.online/api/v1';
    }

    if (kIsWeb) {
      // Use the same host that is serving the web app to avoid origin mismatches
      final host = Uri.base.host;
      return 'http://$host:8000/api/v1';
    }

    // Use 10.0.2.2 for Android Emulator, 127.0.0.1 for others
    return 'http://10.0.2.2:8000/api/v1';
  }

  static const String imageBaseUrl = 'https://patapoa.online/storage/3d_categories';

  // Auth Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String authSocialLogin = '/auth/social-login';
  static const String authSocialComplete = '/auth/social-complete';
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
  static const String masterProducts = '/master-products';
  static String product(int id) => '/products/$id';

  // Order Endpoints
  static const String customerOrders = '/customer/orders';
  static String customerOrder(int id) => '/customer/orders/$id';
  static String orderTracking(int id) => '/orders/$id/tracking';
  static String orderCancel(int id) => '/orders/$id/cancel';

  // Payment Endpoints
  static const String paymentsInitiate = '/payments/initiate';
  static String paymentsStatus(int orderId) => '/payments/$orderId/status';
  static const String paymentsCallback = '/payments/callback';

  // Merchant Endpoints
  static const String merchantDashboard = '/merchant/dashboard';
  static const String merchantOrders = '/merchant/orders';
  static const String merchantPayoutRequest = '/merchant/payout/request';
  static const String merchantProducts = '/merchant/products';
  static String merchantProduct(int id) => '/merchant/products/$id';
  static String merchantUpdateOrderStatus(int id) =>
      '/merchant/orders/$id/status';

  // Delivery Partner Endpoints
  static const String riderLocation = '/delivery-partner/location';
  static const String riderOnline = '/delivery-partner/online';
  static const String riderOffline = '/delivery-partner/offline';
  static const String riderAvailableOrders = '/delivery-partner/available-orders';
  static String riderAcceptOrder(int id) => '/delivery-partner/orders/$id/accept';
  static String riderUpdateOrderStatus(int id) => '/delivery-partner/orders/$id/status';
  static const String riderEarnings = '/delivery-partner/earnings';
  static const String riderPayoutRequest = '/delivery-partner/payout/request';
  static const String riderOrders = '/delivery-partner/orders';
  static const String riderProfile = '/delivery-partner/profile';

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
