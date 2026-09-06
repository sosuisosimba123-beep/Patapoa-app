import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(analytics: analytics);

  /// Logs when a user selects a store/merchant.
  static Future<void> logStoreSelected({
    required String storeId,
    required String storeName,
    String? city,
  }) async {
    await analytics.logEvent(
      name: 'store_selected',
      parameters: {
        'store_id': storeId,
        'store_name': storeName,
        if (city != null) 'city': city,
      },
    );
  }

  /// Logs when a user views a specific product.
  static Future<void> logItemViewed({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
  }) async {
    await analytics.logViewItem(
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: category,
          price: price,
        ),
      ],
    );
  }

  /// Logs when a user adds an item to their cart.
  static Future<void> logAddToCart({
    required String itemId,
    required String itemName,
    required String category,
    required double price,
    required int quantity,
  }) async {
    await analytics.logAddToCart(
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: category,
          price: price,
          quantity: quantity,
        ),
      ],
    );
  }

  /// Logs the completion of a checkout/order.
  static Future<void> logOrderCompleted({
    required String orderId,
    required double totalAmount,
    required String paymentMethod,
  }) async {
    await analytics.logPurchase(
      transactionId: orderId,
      value: totalAmount,
      currency: 'TZS',
    );
    // Also log payment info separately since logPurchase doesn't take it
    await logAddPaymentInfo(paymentType: paymentMethod);
  }

  /// Logs when a user starts the checkout process.
  static Future<void> logBeginCheckout({
    required double value,
    required List<AnalyticsEventItem> items,
  }) async {
    await analytics.logBeginCheckout(
      value: value,
      currency: 'TZS',
      items: items,
    );
  }

  /// Logs when a user selects a payment method.
  static Future<void> logAddPaymentInfo({
    required String paymentType,
  }) async {
    await analytics.logAddPaymentInfo(
      paymentType: paymentType,
    );
  }
}
