import 'package:flutter_test/flutter_test.dart';
import 'package:trueup_lite_flutter/main.dart';

void main() {
  testWidgets('TrueUp Lite app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TrueUpLiteApp());
    await tester.pumpAndSettle();

    expect(find.text('TrueUp Lite - Order Management'), findsOneWidget);
    expect(find.text('Order Suggestions Management'), findsOneWidget);
    expect(find.text('Order Suggestions'), findsOneWidget);
    expect(find.text('PO Basket'), findsOneWidget);
    expect(find.text('Online Orders'), findsOneWidget);
  });
}
