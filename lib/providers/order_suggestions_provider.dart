import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_order_suggestion.dart';
import '../models/po_basket_item.dart';
import '../models/ordered_item.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';
import '../services/api_service.dart';
import '../services/persistence_service.dart';
import '../models/weekly_purchase_history.dart';
import '../models/order_suggestion_history.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Persistence Service Provider
final persistenceServiceProvider = Provider<PersistenceService>((ref) {
  final service = PersistenceService();
  service.init(); // Initialize asynchronously
  return service;
});

// Filter State
class OrderSuggestionFilter {
  final String? searchTerm;
  final String? category;
  final String? brand;

  OrderSuggestionFilter({this.searchTerm, this.category, this.brand});
}

final orderSuggestionFilterProvider =
    StateProvider<OrderSuggestionFilter>((ref) {
  return OrderSuggestionFilter(
      searchTerm: '', category: 'All Categories', brand: 'All Brands');
});

// Order Suggestions State
final orderSuggestionsProvider = AsyncNotifierProvider<OrderSuggestionsNotifier,
    List<ProductOrderSuggestion>>(
  OrderSuggestionsNotifier.new,
);

class OrderSuggestionsNotifier
    extends AsyncNotifier<List<ProductOrderSuggestion>> {
  List<ProductOrderSuggestion>? _allSuggestions;

  @override
  Future<List<ProductOrderSuggestion>> build() async {
    // Load data only once
    if (_allSuggestions == null) {
      final apiService = ref.read(apiServiceProvider);
      _allSuggestions = await apiService.generateOrderSuggestions();
      print('📊 Loaded ${_allSuggestions?.length ?? 0} suggestions from API');
    }

    // Watch filter and apply it reactively
    final filter = ref.watch(orderSuggestionFilterProvider);
    final filtered = _applyFilters(_allSuggestions!, filter);
    print(
        '🔍 Filtered to ${filtered.length} suggestions (filter: category=${filter.category}, brand=${filter.brand}, search=${filter.searchTerm})');
    return filtered;
  }

  Future<void> loadOrderSuggestions() async {
    state = const AsyncValue.loading();
    final apiService = ref.read(apiServiceProvider);
    final suggestions = await apiService.generateOrderSuggestions();
    _allSuggestions = suggestions;

    // Apply current filter
    final filter = ref.read(orderSuggestionFilterProvider);
    state = AsyncValue.data(_applyFilters(suggestions, filter));
  }

  List<ProductOrderSuggestion> _applyFilters(
      List<ProductOrderSuggestion> suggestions, OrderSuggestionFilter filter) {
    final filtered = suggestions.where((suggestion) {
      final searchTermMatch = filter.searchTerm == null ||
          filter.searchTerm!.isEmpty ||
          (suggestion.productName
                  ?.toLowerCase()
                  .contains(filter.searchTerm!.toLowerCase()) ??
              false);
      final categoryMatch = filter.category == null ||
          filter.category == 'All Categories' ||
          suggestion.categoryName == filter.category;
      final brandMatch = filter.brand == null ||
          filter.brand == 'All Brands' ||
          suggestion.brandName == filter.brand;
      return searchTermMatch && categoryMatch && brandMatch;
    }).toList();
    
    // Sort by product name (case-insensitive)
    filtered.sort((a, b) {
      final nameA = (a.productName ?? '').toLowerCase();
      final nameB = (b.productName ?? '').toLowerCase();
      return nameA.compareTo(nameB);
    });
    
    return filtered;
  }
}

// Basket State
class BasketNotifier extends Notifier<List<POBasketItem>> {
  @override
  List<POBasketItem> build() {
    return [];
  }

  Future<void> loadBasketItems() async {
    try {
      final items = await ref.read(apiServiceProvider).getBasketItems();
      state = items;
    } catch (e) {
      rethrow;
    }
  }

  /// Set basket items directly without API call (useful when data comes from grouped API)
  void setItems(List<POBasketItem> items) {
    state = items;
  }

  Future<BasketOperationResponse> addItem(POBasketItem item) async {
    try {
      final response = await ref.read(apiServiceProvider).addToBasket(item);
      if (response.success) {
        await loadBasketItems(); // Refresh the list
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<BasketOperationResponse> removeItem(String itemId) async {
    try {
      final response =
          await ref.read(apiServiceProvider).removeFromBasket(itemId);
      if (response.success) {
        await loadBasketItems(); // Refresh the list
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<BasketOperationResponse> updateItem(POBasketItem item) async {
    try {
      final response =
          await ref.read(apiServiceProvider).updateBasketItem(item);
      if (response.success) {
        await loadBasketItems(); // Refresh the list
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<BasketOperationResponse> clearBasket() async {
    try {
      final response = await ref.read(apiServiceProvider).clearBasket();
      if (response.success) {
        state = [];
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<PurchaseOrderCreationResponse> createPurchaseOrderFromBasket(
    CreateBasketPurchaseOrderRequest request,
  ) async {
    try {
      final response = await ref
          .read(apiServiceProvider)
          .createPurchaseOrderFromBasket(request);
      if (response.success && request.clearBasketAfterOrder) {
        state = [];
      }
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getGroupedBasketItems() async {
    try {
      return await ref
          .read(apiServiceProvider)
          .getBasketItemsGroupedBySupplier();
    } catch (e) {
      rethrow;
    }
  }
}

final basketProvider = NotifierProvider<BasketNotifier, List<POBasketItem>>(
  BasketNotifier.new,
);

// Basket count provider
final basketCountProvider = Provider<int>((ref) {
  final basketItems = ref.watch(basketProvider);
  return basketItems.length;
});

// Basket total cost provider
final basketTotalProvider = Provider<int>((ref) {
  final basketItems = ref.watch(basketProvider);
  return basketItems.fold(0, (sum, item) => sum + item.totalCost);
});

// Weekly Purchase History State
class WeeklyPurchaseHistoryNotifier
    extends Notifier<List<WeeklyPurchaseHistory>> {
  @override
  List<WeeklyPurchaseHistory> build() {
    return [];
  }

  Future<void> loadWeeklyHistory({int weeks = 4}) async {
    final apiService = ref.read(apiServiceProvider);
    try {
      final history = await apiService.getWeeklyPurchaseHistory(weeks: weeks);
      state = history;
    } catch (e) {
      // The screen will handle the error. We just rethrow.
      rethrow;
    }
  }
}

final weeklyPurchaseHistoryProvider = NotifierProvider<
    WeeklyPurchaseHistoryNotifier, List<WeeklyPurchaseHistory>>(
  WeeklyPurchaseHistoryNotifier.new,
);

// Order Suggestion History State
class OrderSuggestionHistoryNotifier
    extends Notifier<List<OrderSuggestionHistory>> {
  int _page = 0;
  bool hasMore = true;
  bool isLoading = false;

  @override
  List<OrderSuggestionHistory> build() {
    return [];
  }

  Future<void> loadHistory({bool refresh = false}) async {
    if (isLoading) return;

    isLoading = true;
    if (refresh) {
      _page = 0;
      state = [];
      hasMore = true;
    }

    if (!hasMore) {
      isLoading = false;
      return;
    }

    final apiService = ref.read(apiServiceProvider);
    try {
      final result =
          await apiService.getOrderSuggestionHistory(page: _page, size: 20);
      if (result.content.isNotEmpty) {
        state = [...state, ...result.content];
        _page++;
        hasMore = !result.last;
      } else {
        hasMore = false;
      }
    } catch (e) {
      rethrow;
    } finally {
      isLoading = false;
    }
  }
}

final orderSuggestionHistoryProvider = NotifierProvider<
    OrderSuggestionHistoryNotifier, List<OrderSuggestionHistory>>(
  OrderSuggestionHistoryNotifier.new,
);

// Categories State
class CategoriesNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getCategories();
  }

  Future<void> loadCategories({int? brandId, int? supplierId}) async {
    state = const AsyncValue.loading();
    final apiService = ref.read(apiServiceProvider);
    state = await AsyncValue.guard(() => apiService.getCategories(
          brandId: brandId,
          supplierId: supplierId,
        ));
  }
}

final categoriesProvider =
    AsyncNotifierProvider<CategoriesNotifier, List<Map<String, dynamic>>>(
  CategoriesNotifier.new,
);

// Brands State
class BrandsNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final apiService = ref.read(apiServiceProvider);
    return await apiService.getBrands();
  }

  Future<void> loadBrands({int? categoryId, int? supplierId}) async {
    state = const AsyncValue.loading();
    final apiService = ref.read(apiServiceProvider);
    state = await AsyncValue.guard(() => apiService.getBrands(
          categoryId: categoryId,
          supplierId: supplierId,
        ));
  }
}

final brandsProvider =
    AsyncNotifierProvider<BrandsNotifier, List<Map<String, dynamic>>>(
  BrandsNotifier.new,
);

// Ordered Items State
class OrderedItemsNotifier extends Notifier<List<OrderedItem>> {
  @override
  List<OrderedItem> build() {
    // Load from persistence on build
    _loadFromPersistence();
    return [];
  }

  Future<void> _loadFromPersistence() async {
    try {
      final persistence = ref.read(persistenceServiceProvider);
      await persistence.init();
      final items = await persistence.loadOrderedItems();
      state = items;
    } catch (e) {
      print('Error loading ordered items from persistence: $e');
    }
  }

  /// Mark items as ordered
  Future<void> markAsOrdered(
    List<POBasketItem> items, {
    DateTime? orderedDate,
    String? orderNotes,
    String? orderNumber,
  }) async {
    final date = orderedDate ?? DateTime.now();
    final orderedItems = items.map((item) {
      return OrderedItem.fromBasketItem(
        item,
        orderedDate: date,
        orderNotes: orderNotes,
        orderNumber: orderNumber,
      );
    }).toList();

    state = [...state, ...orderedItems];

    // Save to persistence
    try {
      final persistence = ref.read(persistenceServiceProvider);
      await persistence.saveOrderedItems(state);
    } catch (e) {
      print('Error saving ordered items: $e');
    }
  }

  /// Unmark items as ordered (move back to basket)
  Future<void> unmarkAsOrdered(List<String> itemIds) async {
    final itemsToUnmark = state.where((item) => itemIds.contains(item.id)).toList();
    state = state.where((item) => !itemIds.contains(item.id)).toList();

    // Save to persistence
    try {
      final persistence = ref.read(persistenceServiceProvider);
      await persistence.saveOrderedItems(state);
    } catch (e) {
      print('Error saving ordered items: $e');
    }

    // Return items to basket
    try {
      final basketNotifier = ref.read(basketProvider.notifier);
      for (var orderedItem in itemsToUnmark) {
        final basketItem = orderedItem.toBasketItem();
        await basketNotifier.addItem(basketItem);
      }
    } catch (e) {
      print('Error adding items back to basket: $e');
    }
  }

  /// Get ordered items by supplier
  List<OrderedItem> getBySupplier(String supplierName) {
    return state.where((item) => item.supplierName == supplierName).toList();
  }

  /// Get ordered items by date range
  List<OrderedItem> getByDateRange(DateTime startDate, DateTime endDate) {
    return state.where((item) {
      return item.orderedDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          item.orderedDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// Load ordered items from persistence
  Future<void> loadOrderedItems() async {
    await _loadFromPersistence();
  }
}

final orderedItemsProvider =
    NotifierProvider<OrderedItemsNotifier, List<OrderedItem>>(
  OrderedItemsNotifier.new,
);
