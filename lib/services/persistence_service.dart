import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/po_basket_item.dart';
import '../models/ordered_item.dart';

/// Service for local persistence using Hive
/// Handles basket items and ordered items storage
class PersistenceService {
  static const String _basketBoxName = 'basket_items';
  static const String _orderedBoxName = 'ordered_items';

  Box<String>? _basketBox;
  Box<String>? _orderedBox;

  bool _initialized = false;

  /// Initialize Hive and open boxes
  Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Store as JSON strings since we don't have Hive adapters
    _basketBox = await Hive.openBox<String>(_basketBoxName);
    _orderedBox = await Hive.openBox<String>(_orderedBoxName);

    _initialized = true;
  }

  // ============ BASKET ITEMS ============

  /// Save basket items to local storage
  Future<void> saveBasketItems(List<POBasketItem> items) async {
    if (!_initialized) await init();

    await _basketBox!.clear();
    for (var item in items) {
      final key = item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _basketBox!.put(key, json.encode(item.toJson()));
    }
  }

  /// Load basket items from local storage
  Future<List<POBasketItem>> loadBasketItems() async {
    if (!_initialized) await init();

    return _basketBox!.values
        .map((jsonStr) => POBasketItem.fromJson(json.decode(jsonStr)))
        .toList();
  }

  /// Add a single basket item
  Future<void> addBasketItem(POBasketItem item) async {
    if (!_initialized) await init();

    final key = item.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _basketBox!.put(key, json.encode(item.toJson()));
  }

  /// Remove a basket item
  Future<void> removeBasketItem(String itemId) async {
    if (!_initialized) await init();

    await _basketBox!.delete(itemId);
  }

  /// Clear all basket items
  Future<void> clearBasketItems() async {
    if (!_initialized) await init();

    await _basketBox!.clear();
  }

  // ============ ORDERED ITEMS ============

  /// Save ordered items to local storage
  Future<void> saveOrderedItems(List<OrderedItem> items) async {
    if (!_initialized) await init();

    await _orderedBox!.clear();
    for (var item in items) {
      final key = item.id ??
          '${item.productId}_${item.orderedDate.millisecondsSinceEpoch}';
      await _orderedBox!.put(key, json.encode(item.toJson()));
    }
  }

  /// Load ordered items from local storage
  Future<List<OrderedItem>> loadOrderedItems() async {
    if (!_initialized) await init();

    return _orderedBox!.values
        .map((jsonStr) => OrderedItem.fromJson(json.decode(jsonStr)))
        .toList();
  }

  /// Add an ordered item
  Future<void> addOrderedItem(OrderedItem item) async {
    if (!_initialized) await init();

    final key = item.id ??
        '${item.productId}_${item.orderedDate.millisecondsSinceEpoch}';
    await _orderedBox!.put(key, json.encode(item.toJson()));
  }

  /// Remove an ordered item
  Future<void> removeOrderedItem(String itemId) async {
    if (!_initialized) await init();

    // Find and remove by item ID
    final allItems = await loadOrderedItems();
    final itemsToRemove = allItems.where((item) => item.id == itemId).toList();
    for (var item in itemsToRemove) {
      final key = item.id ??
          '${item.productId}_${item.orderedDate.millisecondsSinceEpoch}';
      await _orderedBox!.delete(key);
    }
  }

  /// Get ordered items by supplier
  Future<List<OrderedItem>> getOrderedItemsBySupplier(
      String supplierName) async {
    if (!_initialized) await init();

    final allItems = await loadOrderedItems();
    return allItems.where((item) => item.supplierName == supplierName).toList();
  }

  /// Get ordered items by date range
  Future<List<OrderedItem>> getOrderedItemsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    if (!_initialized) await init();

    final allItems = await loadOrderedItems();
    return allItems
        .where((item) =>
            item.orderedDate
                .isAfter(startDate.subtract(const Duration(days: 1))) &&
            item.orderedDate.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }

  /// Clear all ordered items
  Future<void> clearOrderedItems() async {
    if (!_initialized) await init();

    await _orderedBox!.clear();
  }

  /// Dispose resources
  void dispose() {
    _basketBox?.close();
    _orderedBox?.close();
  }
}
