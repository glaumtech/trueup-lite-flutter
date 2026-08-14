import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'screens/order_suggestions/order_suggestions_screen.dart';
import 'screens/order_suggestions/order_suggestions_basket_screen.dart';
import 'screens/store_orders/staff_login_screen.dart';
import 'screens/store_orders/online_orders_list_screen.dart';
import 'screens/store_orders/online_order_detail_screen.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/fcm_service.dart';
import 'services/notification_service.dart';
import 'widgets/staff_session_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await FcmService.instance.init();
  runApp(const ProviderScope(child: TrueUpLiteApp()));
}

class TrueUpLiteApp extends StatefulWidget {
  const TrueUpLiteApp({super.key});

  @override
  State<TrueUpLiteApp> createState() => _TrueUpLiteAppState();
}

class _TrueUpLiteAppState extends State<TrueUpLiteApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _createRouter();
    NotificationService.instance.setNavigationHandler((payload) {
      if (payload != null && payload.isNotEmpty) {
        _router.go(payload);
      }
    });
    FcmService.instance.setNavigationHandler((route) {
      _router.go(route);
    });
    NotificationService.instance.handleLaunchNotification();
    FcmService.instance.handleInitialMessage();
  }

  @override
  Widget build(BuildContext context) {
    return StaffSessionWatcher(
      child: MaterialApp.router(
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
      ),
    );
  }
}

GoRouter _createRouter() {
  return GoRouter(
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
        path: '/online-orders/login',
        builder: (context, state) => const StaffLoginScreen(),
      ),
      GoRoute(
        path: '/online-orders',
        builder: (context, state) => const OnlineOrdersListScreen(),
      ),
      GoRoute(
        path: '/online-orders/:orderRef',
        builder: (context, state) {
          final orderRef = state.pathParameters['orderRef'];
          return OnlineOrderDetailScreen(orderRef: orderRef);
        },
      ),
    ],
  );
}
