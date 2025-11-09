import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/order_suggestions/order_suggestions_screen.dart';
import 'screens/order_suggestions/order_suggestions_basket_screen.dart';
import 'screens/order_suggestions/order_suggestions_history_screen.dart';
import 'screens/order_suggestions/weekly_purchase_history_screen.dart';
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
  ],
);
