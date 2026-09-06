import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;

// Theme
import 'package:patapoa/theme/app_theme.dart';

// Providers
import 'package:patapoa/providers/auth_provider.dart';
import 'package:patapoa/providers/cart_provider.dart';
import 'package:patapoa/providers/location_provider.dart';

// Models
import 'package:patapoa/models/product.dart';
import 'package:patapoa/models/order.dart';

// Auth Screens
import 'package:patapoa/features/auth/login_screen.dart';
import 'package:patapoa/features/auth/register_screen.dart';
import 'package:patapoa/features/auth/forgot_password_screen.dart';
import 'package:patapoa/features/role_selection/role_selection_screen.dart';

// Customer Screens
import 'package:patapoa/screens/customer/customer_shell.dart';
import 'package:patapoa/screens/customer/explore_screen.dart';
import 'package:patapoa/screens/customer/product_detail_screen.dart';
import 'package:patapoa/features/cart/presentation/cart_screen.dart';
import 'package:patapoa/screens/customer/order_summary_screen.dart';
import 'package:patapoa/screens/customer/tracking_screen.dart';
import 'package:patapoa/screens/customer/payment_gateway_screen.dart';
import 'package:patapoa/screens/customer/success_screen.dart';
import 'package:patapoa/screens/customer/orders_screen.dart';
import 'package:patapoa/screens/customer/customer_profile_screen.dart';

// Merchant Screens
import 'package:patapoa/screens/merchant/merchant_shell.dart';
import 'package:patapoa/screens/merchant/merchant_homepage_screen.dart';
import 'package:patapoa/screens/merchant/merchant_orders_screen.dart';
import 'package:patapoa/screens/merchant/merchant_inventory_screen.dart';
import 'package:patapoa/screens/merchant/merchant_payout_screen.dart';
import 'package:patapoa/screens/merchant/merchant_profile_screen.dart';
import 'package:patapoa/screens/merchant/merchant_withdraw_screen.dart';
import 'package:patapoa/screens/merchant/merchant_onboarding_screen.dart';
import 'package:patapoa/screens/merchant/add_product_screen.dart';
import 'package:patapoa/screens/merchant/barcode_scanner_screen.dart';
import 'package:patapoa/screens/merchant/inventory_editing_screen.dart';
import 'package:patapoa/features/onboarding/presentation/store_location_picker_screen.dart';

// Rider Screens
import 'package:patapoa/screens/rider/rider_shell.dart';
import 'package:patapoa/screens/rider/rider_homepage_screen.dart';
import 'package:patapoa/screens/rider/rider_login_screen.dart';
import 'package:patapoa/screens/rider/rider_registration1_screen.dart';
import 'package:patapoa/screens/rider/rider_registration2_screen.dart';
import 'package:patapoa/screens/rider/rider_orders_screen.dart';
import 'package:patapoa/screens/rider/route_assign_screen.dart';
import 'package:patapoa/screens/rider/rider_earnings_screen.dart';
import 'package:patapoa/screens/rider/rider_withdraw_screen.dart';
import 'package:patapoa/screens/rider/rider_profile_screen.dart';
import 'package:patapoa/screens/rider/rider_cash_received_screen.dart';
import 'package:patapoa/screens/rider/rider_withdraw_procedures_screen.dart';
import 'package:patapoa/screens/rider/rider_withdraw_success_screen.dart';

// Admin Screens removed as they shifted to Web
import 'package:patapoa/utils/osm_tester.dart';
import 'package:patapoa/services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:patapoa/services/pocketbase_services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:patapoa/utils/analytics_service.dart';
import 'package:patapoa/firebase_options.dart';
import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    // Global Error Handler
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      debugPrint("CRITICAL ERROR: ${details.exception}");
    };

    WidgetsFlutterBinding.ensureInitialized();

    // Set up asynchronous error handling
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    try {
      await initPocketBase();
    } catch (e) {
      debugPrint("PocketBase init failed: $e");
    }

    // Fix for potential login/auth sync issues
    if (kDebugMode) {
      debugPrint("Clearing local storage for clean test...");
      // const storage = FlutterSecureStorage();
      // await storage.deleteAll();
    }

    // 1. Load Env
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env file missing: $e");
    }

    // 2. Initialize Firebase
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Enable Crashlytics collection in non-debug mode or as per requirement
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (e) {
      debugPrint("Firebase init failed: $e");
    }

    // 3. Initialize Push Notifications (Only if supported)
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final ns = NotificationService();
        await ns.initialize().timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("Notification Service failed (skipping): $e");
    }

    // 3. Optional Diagnostics (non-blocking)
    if (kDebugMode) {
      OsmTester.runFullDiagnostic().catchError((e) => debugPrint("OSM test failed: $e"));
    }

    runApp(
      const riverpod.ProviderScope(
        child: PatapoaApp(),
      ),
    );
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

class PatapoaApp extends StatelessWidget {
  const PatapoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configure Router inside build to ensure it picks up context if needed
    final router = GoRouter(
      initialLocation: '/role',
      debugLogDiagnostics: true,
      observers: [AnalyticsService.observer],
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: '/register',
          builder: (context, state) {
            final role = state.extra is String ? state.extra as String : null;
            return RegisterScreen(initialRole: role);
          },
        ),
        GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
        GoRoute(path: '/role', builder: (context, state) => const RoleSelectionScreen()),

        // Customer
        ShellRoute(
          builder: (context, state, child) => CustomerShell(child: child),
          routes: [
            GoRoute(path: '/customer/explore', builder: (context, state) => const ExploreScreen()),
            GoRoute(path: '/customer/orders', builder: (context, state) => const CustomerOrdersScreen()),
            GoRoute(path: '/customer/profile', builder: (context, state) => const CustomerProfileScreen()),
            GoRoute(path: '/customer/cart', builder: (context, state) => const CartScreen()),
          ],
        ),
        GoRoute(path: '/customer/product', builder: (context, state) => ProductDetailScreen(product: state.extra as Product)),
        GoRoute(
          path: '/customer/order-summary',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return OrderSummaryScreen(addressId: extra?['address_id'] as int? ?? 0);
          }
        ),
        GoRoute(path: '/customer/tracking', builder: (context, state) => TrackingScreen(order: state.extra as Order)),
        GoRoute(path: '/customer/payment-gateway', builder: (context, state) => PaymentGatewayScreen(order: state.extra as Order)),
        GoRoute(path: '/customer/success', builder: (context, state) => SuccessScreen(order: state.extra as Order)),

        // Merchant
        ShellRoute(
          builder: (context, state, child) => MerchantShell(child: child),
          routes: [
            GoRoute(path: '/merchant/home', builder: (context, state) => const MerchantHomeScreen()),
            GoRoute(path: '/merchant/orders', builder: (context, state) => const MerchantOrdersScreen()),
            GoRoute(path: '/merchant/inventory', builder: (context, state) => const MerchantInventoryScreen()),
            GoRoute(path: '/merchant/payouts', builder: (context, state) => const MerchantPayoutScreen()),
            GoRoute(path: '/merchant/profile', builder: (context, state) => const MerchantProfileScreen()),
          ],
        ),
        GoRoute(path: '/merchant/onboarding', builder: (context, state) => const MerchantOnboardingScreen()),
        GoRoute(path: '/merchant/withdraw', builder: (context, state) => const MerchantWithdrawScreen()),
        GoRoute(path: '/merchant/barcode-scan', builder: (context, state) => const BarcodeScannerScreen()),
        GoRoute(
          path: '/merchant/add-product', 
          builder: (context, state) => AddProductScreen(initialData: state.extra as Map<String, dynamic>?)
        ),
        GoRoute(path: '/merchant/edit-product', builder: (context, state) => MerchantEditProductScreen(product: state.extra as Product)),
        GoRoute(path: '/merchant/location-setup', builder: (context, state) => const StoreLocationPickerScreen()),

        // Rider
        GoRoute(path: '/delivery-partner/login', builder: (context, state) => const RiderLoginScreen()),
        GoRoute(path: '/delivery-partner/register/step1', builder: (context, state) => const RiderRegistrationStep1Screen()),
        GoRoute(path: '/delivery-partner/register/step2', builder: (context, state) => RiderRegistrationStep2Screen(registrationData: state.extra as Map<String, dynamic>? ?? {})),
        ShellRoute(
          builder: (context, state, child) => RiderShell(child: child),
          routes: [
            GoRoute(path: '/delivery-partner/home', builder: (context, state) => const RiderHomeScreen()),
            GoRoute(path: '/delivery-partner/orders', builder: (context, state) => const RiderOrdersScreen()),
            GoRoute(path: '/delivery-partner/earnings', builder: (context, state) => const RiderEarningsScreen()),
            GoRoute(path: '/delivery-partner/profile', builder: (context, state) => const RiderProfileScreen()),
          ],
        ),
        GoRoute(path: '/delivery-partner/route-assign', builder: (context, state) => RouteAssignScreen(orderData: state.extra as Map<String, dynamic>?)),
        GoRoute(path: '/delivery-partner/withdraw', builder: (context, state) => const RiderWithdrawScreen()),
        GoRoute(path: '/delivery-partner/withdraw-procedures', builder: (context, state) => const RiderWithdrawProceduresScreen()),
        GoRoute(path: '/delivery-partner/withdraw-success', builder: (context, state) => const RiderWithdrawSuccessScreen()),
        GoRoute(
          path: '/delivery-partner/cash-confirmation',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>;
            return RiderCashReceivedScreen(
              orderId: extra['orderId'] as int,
              amount: extra['amount'] as double,
            );
          },
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp.router(
        title: 'Patapoa',
        theme: buildPatapoaTheme(),
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
