import 'package:flutter_test/flutter_test.dart';
import 'package:trueup_lite_flutter/models/admin_store_order.dart';
import 'package:trueup_lite_flutter/utils/whatsapp_formatter.dart';

AdminStoreOrder _sampleOrder({List<AdminOrderItem>? items}) {
  return AdminStoreOrder(
    id: 'ORD-7248',
    date: '2025-10-01',
    total: 360,
    shippingFee: 120,
    status: 'Pending',
    paymentMethod: 'Cash on Delivery',
    staffNotes: 'Internal only',
    shippingAddress: const ShippingAddress(
      name: 'Arjun bharathan',
      email: 'arjun@example.com',
      street: 'Green leaf resort, kaniyambeta',
      city: 'Wayanad',
      state: 'Kerala',
      zip: '673124',
      phone: '9769266253',
    ),
    items: items ??
        [
          const AdminOrderItem(name: 'Widget A', qty: 2, price: 120),
        ],
  );
}

void main() {
  group('formatCustomerOrderMessage', () {
    test('includes order id, status, payment, items, and bill summary', () {
      final text = WhatsAppFormatter.formatCustomerOrderMessage(_sampleOrder());

      expect(text, contains('ORD-7248'));
      expect(text, contains('Status: Pending'));
      expect(text, contains('Payment: Cash on Delivery'));
      expect(text, contains('Widget A'));
      expect(text, contains('Bill Summary'));
      expect(text, contains('Total'));
    });

    test('excludes shipping address and staff notes', () {
      final text = WhatsAppFormatter.formatCustomerOrderMessage(_sampleOrder());

      expect(text, isNot(contains('Green leaf')));
      expect(text, isNot(contains('673124')));
      expect(text, isNot(contains('Internal only')));
      expect(text, isNot(contains('9769266253')));
    });

    test('truncates long item lists with more-items line', () {
      final manyItems = List.generate(
        25,
        (i) => AdminOrderItem(name: 'Item $i', qty: 1, price: 10),
      );
      final text = WhatsAppFormatter.formatCustomerOrderMessage(
        _sampleOrder(items: manyItems),
      );

      expect(text, contains('+ 5 more items'));
    });
  });
}
