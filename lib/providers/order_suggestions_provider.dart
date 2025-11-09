import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_order_suggestion.dart';
import '../models/po_basket_item.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';
import '../services/api_service.dart';
import '../models/weekly_purchase_history.dart';
import '../models/order_suggestion_history.dart';

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
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
