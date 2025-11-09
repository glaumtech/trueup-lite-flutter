import 'package:flutter_test/flutter_test.dart';
import 'package:trueup_lite_flutter/main.dart';

void main() {
  testWidgets('TrueUp Lite app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrueUpLiteApp());

    // Verify that the app starts with the home screen
    expect(find.text('TrueUp Lite - Order Management'), findsOneWidget);
    expect(find.text('Order Suggestions Management'), findsOneWidget);
    
    // Verify navigation cards are present
    expect(find.text('Order Suggestions'), findsOneWidget);
    expect(find.text('PO Basket'), findsOneWidget);
    expect(find.text('Order History'), findsOneWidget);
    expect(find.text('Weekly History'), findsOneWidget);
  });
}
