import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:patapoa/features/customer/customer_flow_screens.dart';
import 'package:patapoa/features/customer/customer_models.dart';
import 'package:patapoa/features/delivery_partner/delivery_partner_screens.dart';
import 'package:patapoa/features/merchant/merchant_flow_screens.dart';
import 'package:patapoa/features/role_selection/role_selection_screen.dart';
import 'package:patapoa/theme/app_theme.dart';
import 'package:patapoa/providers/auth_provider.dart';
import 'package:patapoa/providers/cart_provider.dart';
import 'package:patapoa/providers/location_provider.dart';
import 'package:patapoa/screens/auth/login_screen.dart';
import 'package:patapoa/screens/auth/register_screen.dart';
import 'package:patapoa/screens/auth/otp_screen.dart';
import 'package:patapoa/models/product.dart';
import 'package:patapoa/models/order.dart';

void main() {
  runApp(const PatapoaApp());
}

class PatapoaApp extends StatelessWidget {
  const PatapoaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(path: '/otp', builder: (context, state) => const OtpScreen()),
        GoRoute(
          path: '/role',
          builder: (context, state) => const RoleSelectionScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => CustomerShell(child: child),
          routes: [
            GoRoute(
              path: '/customer/explore',
              builder: (context, state) => const CustomerExploreScreen(),
            ),
            GoRoute(
              path: '/customer/orders',
              builder: (context, state) => const CustomerOrdersScreen(),
            ),
            GoRoute(
              path: '/customer/profile',
              builder: (context, state) => const CustomerProfileScreen(),
            ),
            GoRoute(
              path: '/customer/cart',
              builder: (context, state) => const CustomerCartScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/customer/product',
          builder: (context, state) {
            final product = state.extra as Product;
            return CustomerProductDetailsScreen(product: product);
          },
        ),
        GoRoute(
          path: '/customer/order-summary',
          builder: (context, state) {
            final draft = state.extra as CustomerOrderDraft;
            return CustomerOrderSummaryScreen(draft: draft);
          },
        ),
        GoRoute(
          path: '/customer/delivery-location',
          builder: (context, state) {
            final draft = state.extra as CustomerOrderDraft;
            return CustomerDeliveryLocationScreen(draft: draft);
          },
        ),
        GoRoute(
          path: '/customer/tracking',
          builder: (context, state) {
            final order = state.extra as Order;
            return CustomerTrackingScreen(order: order);
          },
        ),
        GoRoute(
          path: '/customer/payment-gateway',
          builder: (context, state) {
            final order = state.extra as CustomerPlacedOrder;
            return CustomerPaymentGatewayScreen(order: order);
          },
        ),
        GoRoute(
          path: '/customer/success',
          builder: (context, state) {
            final order = state.extra as CustomerPlacedOrder;
            return CustomerSuccessScreen(order: order);
          },
        ),
        ShellRoute(
          builder: (context, state, child) => MerchantShell(child: child),
          routes: [
            GoRoute(
              path: '/merchant/home',
              builder: (context, state) => const MerchantHomeScreen(),
            ),
            GoRoute(
              path: '/merchant/orders',
              builder: (context, state) => const MerchantOrdersScreen(),
            ),
            GoRoute(
              path: '/merchant/inventory',
              builder: (context, state) => const MerchantInventoryScreen(),
            ),
            GoRoute(
              path: '/merchant/payouts',
              builder: (context, state) => const MerchantPayoutScreen(),
            ),
            GoRoute(
              path: '/merchant/profile',
              builder: (context, state) => const MerchantProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/merchant/add-product',
          builder: (context, state) => const MerchantAddProductScreen(),
        ),
        GoRoute(
          path: '/merchant/edit-product',
          builder: (context, state) {
            final product = state.extra as Product;
            return MerchantEditProductScreen(product: product);
          },
        ),
        GoRoute(
          path: '/delivery-partner/login',
          builder: (context, state) => const DeliveryPartnerLoginScreen(),
        ),
        GoRoute(
          path: '/delivery-partner/register/step1',
          builder: (context, state) =>
              const DeliveryPartnerRegistrationStep1Screen(),
        ),
        GoRoute(
          path: '/delivery-partner/register/step2',
          builder: (context, state) =>
              const DeliveryPartnerRegistrationStep2Screen(),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              DeliveryPartnerShell(child: child),
          routes: [
            GoRoute(
              path: '/delivery-partner/home',
              builder: (context, state) => const DeliveryPartnerHomeScreen(),
            ),
            GoRoute(
              path: '/delivery-partner/orders',
              builder: (context, state) => const DeliveryPartnerOrdersScreen(),
            ),
            GoRoute(
              path: '/delivery-partner/route-assign',
              builder: (context, state) =>
                  const DeliveryPartnerRouteAssignScreen(),
            ),
            GoRoute(
              path: '/delivery-partner/earnings',
              builder: (context, state) =>
                  const DeliveryPartnerEarningsScreen(),
            ),
            GoRoute(
              path: '/delivery-partner/profile',
              builder: (context, state) => const DeliveryPartnerProfileScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/delivery-partner/withdraw',
          builder: (context, state) => const DeliveryPartnerWithdrawScreen(),
        ),
        GoRoute(
          path: '/delivery-partner/withdraw-success',
          builder: (context, state) =>
              const DeliveryPartnerWithdrawSuccessScreen(),
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
      ),
    );
  }
}
