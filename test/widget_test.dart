import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:trueup_lite_flutter/main.dart';

void main() {
  testWidgets('TrueUp Lite app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TrueUpLiteApp());
    await tester.pumpAndSettle();

    // The home page uses a grid; with more cards, some tiles may be outside
    // the initial viewport. Scroll a bit to ensure all expected texts render.
    final grid = find.byType(GridView);
    if (grid.evaluate().isNotEmpty) {
      // We'll scroll later (after first-row assertions) to avoid
      // unmounting those tiles from the viewport.
    }

    // Verify that the app starts with the home screen
    expect(find.text('TrueUp Lite - Order Management'), findsOneWidget);
    expect(find.text('Order Suggestions Management'), findsOneWidget);
    
    // Verify navigation cards are present
    expect(find.text('Order Suggestions'), findsOneWidget);
    expect(find.text('PO Basket'), findsOneWidget);

    // Scroll to bring the second row into view.
    if (grid.evaluate().isNotEmpty) {
      await tester.drag(grid, const Offset(0, -200));
      await tester.pumpAndSettle();
    }

    expect(find.text('Order History'), findsOneWidget);
    expect(find.text('Weekly History'), findsOneWidget);
  });
}
