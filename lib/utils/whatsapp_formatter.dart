import 'package:intl/intl.dart';
import '../models/po_basket_item.dart';
import '../models/ordered_item.dart';

/// Utility class for formatting basket items for WhatsApp sharing
class WhatsAppFormatter {
  /// Format a list of basket items for a supplier as WhatsApp-ready text
  static String formatSupplierList({
    required String supplierName,
    required List<POBasketItem> items,
    DateTime? orderDate,
    String? orderNumber,
  }) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Supplier: $supplierName');
    if (orderNumber != null) {
      buffer.writeln('Order #: $orderNumber');
    }
    buffer.writeln('Date: ${DateFormat('dd MMM yyyy').format(orderDate ?? DateTime.now())}');
    buffer.writeln(''); // Empty line

    // Items
    int itemNumber = 1;
    int totalItems = 0;
    int totalCost = 0;

    for (var item in items) {
      final qty = item.quantity ?? 0;
      final price = item.price ?? 0;
      final subtotal = qty * price;
      
      totalItems += qty;
      totalCost += subtotal;

      // Format: "1) Brand - Product Name — Qty: X — ₹Y each — Subtotal: ₹Z"
      final brand = item.name?.split(' - ').first ?? '';
      final productName = item.name ?? 'Unknown Product';
      
      buffer.writeln(
        '$itemNumber) $productName — Qty: $qty ${item.unit ?? ''} — ₹$price each — Subtotal: ₹$subtotal',
      );
      
      itemNumber++;
    }

    // Footer
    buffer.writeln('');
    buffer.writeln('Total items: $totalItems   Total cost: ₹$totalCost');

    return buffer.toString();
  }

  /// Format ordered items for a supplier
  static String formatOrderedSupplierList({
    required String supplierName,
    required List<OrderedItem> items,
  }) {
    final buffer = StringBuffer();
    
    // Group by order date
    final groupedByDate = <DateTime, List<OrderedItem>>{};
    for (var item in items) {
      final date = DateTime(
        item.orderedDate.year,
        item.orderedDate.month,
        item.orderedDate.day,
      );
      groupedByDate.putIfAbsent(date, () => []).add(item);
    }

    // Sort dates descending
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (var date in sortedDates) {
      final dateItems = groupedByDate[date]!;
      
      buffer.writeln('Supplier: $supplierName');
      buffer.writeln('Date: ${DateFormat('dd MMM yyyy').format(date)}');
      if (dateItems.first.orderNumber != null) {
        buffer.writeln('Order #: ${dateItems.first.orderNumber}');
      }
      buffer.writeln('');

      int itemNumber = 1;
      int totalItems = 0;
      int totalCost = 0;

      for (var item in dateItems) {
        final qty = item.quantity ?? 0;
        final price = item.price ?? 0;
        final subtotal = qty * price;
        
        totalItems += qty;
        totalCost += subtotal;

        buffer.writeln(
          '$itemNumber) ${item.name ?? 'Unknown'} — Qty: $qty ${item.unit ?? ''} — ₹$price each — Subtotal: ₹$subtotal',
        );
        
        itemNumber++;
      }

      buffer.writeln('');
      buffer.writeln('Total items: $totalItems   Total cost: ₹$totalCost');
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  /// Format all basket items grouped by supplier
  static Map<String, String> formatAllSuppliers(List<POBasketItem> items) {
    final grouped = <String, List<POBasketItem>>{};
    
    for (var item in items) {
      final supplierName = item.supplierName ?? 'Unknown Supplier';
      grouped.putIfAbsent(supplierName, () => []).add(item);
    }

    final formatted = <String, String>{};
    for (var entry in grouped.entries) {
      formatted[entry.key] = formatSupplierList(
        supplierName: entry.key,
        items: entry.value,
      );
    }

    return formatted;
  }
}

