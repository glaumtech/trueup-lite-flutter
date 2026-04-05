import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/order_suggestions/order_suggestions_screen.dart';
import 'screens/order_suggestions/order_suggestions_basket_screen.dart';
import 'screens/order_suggestions/order_suggestions_history_screen.dart';
import 'screens/order_suggestions/weekly_purchase_history_screen.dart';
import 'screens/purchases/purchase_v2_create_screen.dart';
import 'screens/purchases/purchase_v2_history_screen.dart';
import 'screens/purchases/purchase_v2_detail_screen.dart';
import 'screens/inventory/inventory_abc_dsi_report_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: TrueUpLiteApp()));
}

class TrueUpLiteApp extends StatelessWidget {
  const TrueUpLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TrueUp Lite - Order Suggestions',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
        ),
      ),
      routerConfig: _router,
    );
  }
}

final GoRouter _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/order-suggestions',
      builder: (context, state) => const OrderSuggestionsScreen(),
    ),
    GoRoute(
      path: '/order-suggestions/basket',
      builder: (context, state) => const OrderSuggestionsBasketScreen(),
    ),
    GoRoute(
      path: '/order-suggestions/history',
      builder: (context, state) => const OrderSuggestionsHistoryScreen(),
    ),
    GoRoute(
      path: '/weekly-purchase-history',
      builder: (context, state) => const WeeklyPurchaseHistoryScreen(),
    ),
    GoRoute(
      path: '/purchase-v2',
      builder: (context, state) => const PurchaseV2CreateScreen(),
    ),
    GoRoute(
      path: '/purchase-v2/history',
      builder: (context, state) => const PurchaseV2HistoryScreen(),
    ),
    GoRoute(
      path: '/purchase-v2/:purchaseId',
      builder: (context, state) {
        final purchaseId = int.tryParse(state.pathParameters['purchaseId'] ?? '');
        return PurchaseV2DetailScreen(purchaseId: purchaseId);
      },
    ),
    GoRoute(
      path: '/inventory/abc-dsi',
      builder: (context, state) => const InventoryAbcDsiReportScreen(),
    ),
  ],
);
