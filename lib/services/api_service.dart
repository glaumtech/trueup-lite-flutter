import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/supplier_order_suggestion.dart';
import '../models/product_order_suggestion.dart';
import '../models/po_basket_item.dart';
import '../models/order_suggestion_history.dart';
import '../models/weekly_purchase_history.dart';
import '../models/request_models.dart';
import '../models/response_models.dart';

class ApiService {
  // Update this to match your backend server URL
  // For Android Emulator: use 'http://10.0.2.2:8081'
  // For Physical Android Device: use your Mac's local IP (e.g., 'http://192.168.1.7:8081')
  // For iOS Simulator: use 'http://localhost:8081'
  // For iOS Physical Device: use your Mac's local IP (e.g., 'http://192.168.1.7:8081')
  static const String baseUrl =
      'http://10.0.2.2:8081'; // Mac's local IP for physical device connection
  static const String orderSuggestionsPath = '/order-suggestions';
  static const String itemsPath = '/items/getAll';

  // HTTP client with timeout configuration
  final http.Client _client = http.Client();

  // Timeout durations
  static const Duration _connectTimeout = Duration(seconds: 10);
  static const Duration _receiveTimeout = Duration(seconds: 30);
  static const Duration _sendTimeout = Duration(seconds: 10);

  // Enable performance logging (set to false in production)
  static const bool _enablePerformanceLogging = true;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Wrapper for HTTP GET with timeout and performance logging
  Future<http.Response> _getWithTimeout(
    Uri uri, {
    Map<String, String>? headers,
    String? operationName,
  }) async {
    Stopwatch? stopwatch;
    if (_enablePerformanceLogging) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final response = await _client
          .get(uri, headers: headers ?? _headers)
          .timeout(_receiveTimeout, onTimeout: () {
        throw TimeoutException(
          'Request timeout after ${_receiveTimeout.inSeconds}s',
          _receiveTimeout,
        );
      });

      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('⏱️  API Call: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - '
            'Status: ${response.statusCode} - '
            'Size: ${response.bodyBytes.length} bytes');
      }

      return response;
    } catch (e) {
      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('❌ API Call Failed: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - Error: $e');
      }
      rethrow;
    }
  }

  /// Wrapper for HTTP POST with timeout and performance logging
  Future<http.Response> _postWithTimeout(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String? operationName,
  }) async {
    Stopwatch? stopwatch;
    if (_enablePerformanceLogging) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final response = await _client
          .post(uri, headers: headers ?? _headers, body: body)
          .timeout(_receiveTimeout, onTimeout: () {
        throw TimeoutException(
          'Request timeout after ${_receiveTimeout.inSeconds}s',
          _receiveTimeout,
        );
      });

      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('⏱️  API Call: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - '
            'Status: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('❌ API Call Failed: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - Error: $e');
      }
      rethrow;
    }
  }

  /// Wrapper for HTTP PUT with timeout and performance logging
  Future<http.Response> _putWithTimeout(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    String? operationName,
  }) async {
    Stopwatch? stopwatch;
    if (_enablePerformanceLogging) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final response = await _client
          .put(uri, headers: headers ?? _headers, body: body)
          .timeout(_receiveTimeout, onTimeout: () {
        throw TimeoutException(
          'Request timeout after ${_receiveTimeout.inSeconds}s',
          _receiveTimeout,
        );
      });

      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('⏱️  API Call: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - '
            'Status: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('❌ API Call Failed: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - Error: $e');
      }
      rethrow;
    }
  }

  /// Wrapper for HTTP DELETE with timeout and performance logging
  Future<http.Response> _deleteWithTimeout(
    Uri uri, {
    Map<String, String>? headers,
    String? operationName,
  }) async {
    Stopwatch? stopwatch;
    if (_enablePerformanceLogging) {
      stopwatch = Stopwatch()..start();
    }

    try {
      final response = await _client
          .delete(uri, headers: headers ?? _headers)
          .timeout(_receiveTimeout, onTimeout: () {
        throw TimeoutException(
          'Request timeout after ${_receiveTimeout.inSeconds}s',
          _receiveTimeout,
        );
      });

      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('⏱️  API Call: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - '
            'Status: ${response.statusCode}');
      }

      return response;
    } catch (e) {
      if (_enablePerformanceLogging && stopwatch != null) {
        stopwatch.stop();
        print('❌ API Call Failed: ${operationName ?? uri.path} - '
            '${stopwatch.elapsedMilliseconds}ms - Error: $e');
      }
      rethrow;
    }
  }

  // ============ ORDER SUGGESTION GENERATION ============

  /// Generate order suggestions for products below reorder level
  Future<List<ProductOrderSuggestion>> generateOrderSuggestions() async {
    Stopwatch? overallStopwatch;
    if (_enablePerformanceLogging) {
      overallStopwatch = Stopwatch()..start();
    }

    try {
      if (_enablePerformanceLogging) {
        print('📊 Starting to fetch order suggestions...');
      }

      // Fetch all items in one call using /items endpoint
      final uri = Uri.parse('$baseUrl/items');

      final response = await _getWithTimeout(
        uri,
        operationName: 'getAllItems',
      );

      if (response.statusCode != 200) {
        throw ApiException('Failed to fetch items', response.statusCode);
      }

      Stopwatch? decodeStopwatch;
      if (_enablePerformanceLogging) {
        decodeStopwatch = Stopwatch()..start();
      }

      final List<dynamic> allProducts;
      final responseBody = json.decode(response.body);

      // Handle both array response and paginated response format
      if (responseBody is List) {
        allProducts = responseBody;
      } else if (responseBody is Map && responseBody['content'] is List) {
        allProducts = responseBody['content'];
      } else {
        throw ApiException('Unexpected response format from /items endpoint');
      }

      if (_enablePerformanceLogging && decodeStopwatch != null) {
        decodeStopwatch.stop();
        print('   JSON decode: ${decodeStopwatch.elapsedMilliseconds}ms');
        print('📦 Total products fetched: ${allProducts.length}');
      }

      // Process products
      Stopwatch? processStopwatch;
      if (_enablePerformanceLogging) {
        processStopwatch = Stopwatch()..start();
      }
      final List<ProductOrderSuggestion> allSuggestions = [];

      for (var productJson in allProducts) {
        // Extract basic product information
        final currentStock = (productJson['qty'] as num?)?.toInt() ?? 0;
        final minimumThreshold = productJson['minimumThreshold'];

        // Handle null minimumThreshold - use 0 as default to show all products
        // Products with null threshold will still be shown but won't trigger auto-suggestions
        final thresholdValue =
            minimumThreshold != null ? (minimumThreshold as num).toInt() : 0;

        // Get suppliers array (created from productSuppliers in backend)
        final List<dynamic>? suppliersJson = productJson['suppliers'];

        // Log for debugging
        if (_enablePerformanceLogging) {
          print(
              '   Product ${productJson['id']}: stock=$currentStock, threshold=$thresholdValue, suppliers=${suppliersJson?.length ?? 0}');
        }

        // Skip products without suppliers (they can't be ordered)
        if (suppliersJson == null || suppliersJson.isEmpty) {
          if (_enablePerformanceLogging) {
            print('   Skipping product ${productJson['id']} - no suppliers');
          }
          continue;
        }

        // Find the best supplier to use
        Map<String, dynamic>? supplierData;

        // First, try to use primarySupplier field if available
        final primarySupplierJson = productJson['primarySupplier'];
        if (primarySupplierJson != null && primarySupplierJson is Map) {
          // Find the full supplier details from suppliers array that matches primary supplier
          for (var supplier in suppliersJson) {
            if (supplier is Map &&
                supplier['id'] == primarySupplierJson['id'] &&
                (supplier['isActive'] == true ||
                    supplier['isActive'] == null)) {
              supplierData = Map<String, dynamic>.from(supplier);
              break;
            }
          }
        }

        // If no primary supplier found, look for first active supplier
        if (supplierData == null) {
          for (var supplier in suppliersJson) {
            if (supplier is Map) {
              // Prefer active primary suppliers
              final isActive =
                  supplier['isActive'] == true || supplier['isActive'] == null;
              final isPrimary = supplier['isPrimarySupplier'] == true;

              if (isActive) {
                supplierData = Map<String, dynamic>.from(supplier);
                // If it's primary, use it immediately
                if (isPrimary) {
                  break;
                }
              }
            }
          }
        }

        // If still no supplier found, use first supplier (even if inactive)
        if (supplierData == null && suppliersJson.isNotEmpty) {
          final firstSupplier = suppliersJson.first;
          if (firstSupplier is Map) {
            supplierData = Map<String, dynamic>.from(firstSupplier);
          }
        }

        // Create suggestion if we have supplier data
        // Show all products with suppliers, even if they don't need restocking
        if (supplierData != null) {
          final stockDeficit =
              thresholdValue > 0 ? (thresholdValue - currentStock) : 0;

          // Calculate suggested quantity based on pack size
          final packSize =
              (supplierData['minimumOrderQuantity'] as num?)?.toInt() ?? 1;
          int suggestedQuantity = 0;
          if (stockDeficit > 0) {
            final packsNeeded = (stockDeficit / packSize).ceil();
            suggestedQuantity = (packsNeeded * packSize).toInt();
          }

          // Add product to suggestions (show all products with suppliers)
          // If threshold is 0 or null, suggestedQuantity will be 0 but product will still show
          final productSuggestion = ProductOrderSuggestion(
            productId: productJson['id'] as int?,
            productName: productJson['name'] as String?,
            productCode: productJson['id']?.toString(),
            unit: productJson['unit'] as String?,
            currentStock: currentStock,
            minimumThreshold: thresholdValue > 0 ? thresholdValue : null,
            stockDeficit: stockDeficit > 0 ? stockDeficit : 0,
            suggestedQuantity: suggestedQuantity,
            minimumOrderQuantity:
                (supplierData['minimumOrderQuantity'] as num?)?.toInt(),
            supplierPrice: (supplierData['supplierPrice'] as num?)?.toInt(),
            mrp: (productJson['mrp'] as num?)?.toInt(),
            leadTimeDays: (supplierData['leadTimeDays'] as num?)?.toInt() ?? 0,
            categoryName: productJson['category']?['name'] as String?,
            brandName: productJson['brand']?['name'] as String?,
            supplierProductCode: supplierData['supplierProductCode'] as String?,
            isPrimarySupplier: supplierData['isPrimarySupplier'] == true,
            supplierId: (supplierData['id'] as num?)?.toInt(),
            supplierName: supplierData['name'] as String?,
          );
          allSuggestions.add(productSuggestion);
        }
      }

      if (_enablePerformanceLogging && processStopwatch != null) {
        processStopwatch.stop();
        print(
            '⚙️  Processing products: ${processStopwatch.elapsedMilliseconds}ms '
            '(${allSuggestions.length} suggestions)');
      }

      if (_enablePerformanceLogging && overallStopwatch != null) {
        overallStopwatch.stop();
        print('✅ Total time: ${overallStopwatch.elapsedMilliseconds}ms '
            '(${(overallStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s)');
      }

      return allSuggestions;
    } catch (e) {
      if (_enablePerformanceLogging && overallStopwatch != null) {
        overallStopwatch.stop();
        print('❌ Failed after ${overallStopwatch.elapsedMilliseconds}ms');
      }
      throw ApiException('Error generating order suggestions: $e');
    }
  }

  /// Generate order suggestions for specific suppliers
  Future<List<SupplierOrderSuggestion>> generateOrderSuggestionsForSuppliers(
    List<int> supplierIds,
  ) async {
    try {
      final uri =
          Uri.parse('$baseUrl$orderSuggestionsPath/generate-for-suppliers');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(supplierIds),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => SupplierOrderSuggestion.fromJson(json))
            .toList();
      } else {
        throw ApiException(
            'Failed to generate supplier-specific order suggestions',
            response.statusCode);
      }
    } catch (e) {
      throw ApiException(
          'Error generating supplier-specific order suggestions: $e');
    }
  }

  /// Update suggested quantities for specific products
  Future<OrderSuggestionUpdateResponse> updateSuggestedQuantities(
    List<OrderQuantityUpdate> updates,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/update-quantities');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(updates.map((update) => update.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        return OrderSuggestionUpdateResponse.fromJson(
            json.decode(response.body));
      } else {
        throw ApiException(
            'Failed to update suggested quantities', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error updating suggested quantities: $e');
    }
  }

  /// Create purchase order from suggestions
  Future<PurchaseOrderCreationResponse> createPurchaseOrderFromSuggestions(
    CreatePurchaseOrderRequest request,
  ) async {
    try {
      final uri =
          Uri.parse('$baseUrl$orderSuggestionsPath/create-purchase-order');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return PurchaseOrderCreationResponse.fromJson(
            json.decode(response.body));
      } else {
        throw ApiException(
            'Failed to create purchase order', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error creating purchase order: $e');
    }
  }

  // ============ EXPORT FUNCTIONALITY ============

  /// Export order suggestions to Excel
  Future<Uint8List> exportOrderSuggestionsToExcel(
      [List<int>? supplierIds]) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/export-excel');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: supplierIds != null ? json.encode(supplierIds) : null,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw ApiException('Failed to export to Excel', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error exporting to Excel: $e');
    }
  }

  /// Export order suggestions to PDF
  Future<Uint8List> exportOrderSuggestionsToPdf(
      [List<int>? supplierIds]) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/export-pdf');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: supplierIds != null ? json.encode(supplierIds) : null,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        throw ApiException('Failed to export to PDF', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error exporting to PDF: $e');
    }
  }

  /// Export order suggestions to text format
  Future<String> exportOrderSuggestionsToText([
    List<int>? supplierIds,
    String format = 'simple',
  ]) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/export-text')
          .replace(queryParameters: {'format': format});

      final response = await _client.post(
        uri,
        headers: _headers,
        body: supplierIds != null ? json.encode(supplierIds) : null,
      );

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw ApiException('Failed to export to text', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error exporting to text: $e');
    }
  }

  // ============ STATISTICS AND HISTORY ============

  /// Get order suggestion statistics
  Future<OrderSuggestionStatistics> getOrderSuggestionStatistics() async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/statistics');

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return OrderSuggestionStatistics.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to get statistics', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting statistics: $e');
    }
  }

  /// Get order suggestion history with pagination
  Future<PaginatedResponse<OrderSuggestionHistory>> getOrderSuggestionHistory({
    int page = 0,
    int size = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/history')
          .replace(queryParameters: {
        'page': page.toString(),
        'size': size.toString(),
      });

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PaginatedResponse<OrderSuggestionHistory>.fromJson(
          jsonData,
          (json) => OrderSuggestionHistory.fromJson(json),
        );
      } else {
        throw ApiException('Failed to get history', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting history: $e');
    }
  }

  /// Get weekly purchase history
  Future<List<WeeklyPurchaseHistory>> getWeeklyPurchaseHistory(
      {int weeks = 4}) async {
    try {
      final uri =
          Uri.parse('$baseUrl$orderSuggestionsPath/weekly-purchase-history')
              .replace(queryParameters: {'weeks': weeks.toString()});

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList
            .map((json) => WeeklyPurchaseHistory.fromJson(json))
            .toList();
      } else {
        throw ApiException(
            'Failed to get weekly purchase history', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting weekly purchase history: $e');
    }
  }

  // ============ BASKET MANAGEMENT ============

  /// Add item to PO basket
  Future<BasketOperationResponse> addToBasket(POBasketItem basketItem) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket/add');

      // Validate required fields before sending
      if (basketItem.type == null || basketItem.type!.isEmpty) {
        throw ApiException('Basket item type is required', 400);
      }
      if (basketItem.quantity == null || basketItem.quantity! <= 0) {
        throw ApiException('Basket item quantity must be greater than 0', 400);
      }
      if (basketItem.type == 'product' && basketItem.productId == null) {
        throw ApiException(
            'Product ID is required for product type items', 400);
      }

      // Prepare JSON payload
      final jsonPayload = basketItem.toJson();

      // Log the request payload for debugging
      print('📤 Add to basket request:');
      print('   URL: $uri');
      print('   Payload: ${json.encode(jsonPayload)}');
      print('   Type: ${basketItem.type}');
      print('   ProductId: ${basketItem.productId}');
      print('   Quantity: ${basketItem.quantity}');
      print('   Price: ${basketItem.price}');
      print('   Name: ${basketItem.name}');

      final response = await _postWithTimeout(
        uri,
        body: json.encode(jsonPayload),
        operationName: 'addToBasket',
      );

      // Log response for debugging
      print('📥 Add to basket response:');
      print('   Status: ${response.statusCode}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        return BasketOperationResponse.fromJson(json.decode(response.body));
      } else {
        final errorBody = response.body;
        print(
            '❌ Add to basket failed: Status ${response.statusCode}, Body: $errorBody');
        throw ApiException('Failed to add item to basket', response.statusCode);
      }
    } catch (e) {
      print('❌ Error adding item to basket: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('Error adding item to basket: $e');
    }
  }

  /// Remove item from PO basket
  Future<BasketOperationResponse> removeFromBasket(String basketItemId) async {
    try {
      final uri = Uri.parse(
          '$baseUrl$orderSuggestionsPath/basket/remove/$basketItemId');

      final response = await _deleteWithTimeout(
        uri,
        operationName: 'removeFromBasket',
      );

      if (response.statusCode == 200) {
        return BasketOperationResponse.fromJson(json.decode(response.body));
      } else {
        final errorBody = response.body;
        print(
            '❌ Remove from basket failed: Status ${response.statusCode}, Body: $errorBody');
        throw ApiException(
            'Failed to remove item from basket', response.statusCode);
      }
    } catch (e) {
      print('❌ Error removing item from basket: $e');
      throw ApiException('Error removing item from basket: $e');
    }
  }

  /// Update item in PO basket
  Future<BasketOperationResponse> updateBasketItem(
      POBasketItem basketItem) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket/update');

      final response = await _putWithTimeout(
        uri,
        body: json.encode(basketItem.toJson()),
        operationName: 'updateBasketItem',
      );

      if (response.statusCode == 200) {
        return BasketOperationResponse.fromJson(json.decode(response.body));
      } else {
        final errorBody = response.body;
        print(
            '❌ Update basket item failed: Status ${response.statusCode}, Body: $errorBody');
        throw ApiException('Failed to update basket item', response.statusCode);
      }
    } catch (e) {
      print('❌ Error updating basket item: $e');
      throw ApiException('Error updating basket item: $e');
    }
  }

  /// Get all items in PO basket
  Future<List<POBasketItem>> getBasketItems() async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket');

      final response = await _getWithTimeout(
        uri,
        operationName: 'getBasketItems',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => POBasketItem.fromJson(json)).toList();
      } else {
        throw ApiException('Failed to get basket items', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting basket items: $e');
    }
  }

  /// Clear all items from PO basket
  Future<BasketOperationResponse> clearBasket() async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket/clear');

      final response = await _client.delete(uri, headers: _headers);

      if (response.statusCode == 200) {
        return BasketOperationResponse.fromJson(json.decode(response.body));
      } else {
        throw ApiException('Failed to clear basket', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error clearing basket: $e');
    }
  }

  /// Create purchase order from basket items
  Future<PurchaseOrderCreationResponse> createPurchaseOrderFromBasket(
    CreateBasketPurchaseOrderRequest request,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket/create-po');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return PurchaseOrderCreationResponse.fromJson(
            json.decode(response.body));
      } else {
        throw ApiException(
            'Failed to create purchase order from basket', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error creating purchase order from basket: $e');
    }
  }

  // ============ ENHANCED BASKET OPERATIONS ============

  /// Add order suggestion to basket with supplier context
  Future<BasketOperationResponse> addOrderSuggestionToBasket(
    OrderSuggestionBasketRequest request,
  ) async {
    try {
      final uri =
          Uri.parse('$baseUrl$orderSuggestionsPath/basket/add-suggestion');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return BasketOperationResponse.fromJson(json.decode(response.body));
      } else {
        throw ApiException(
            'Failed to add suggestion to basket', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error adding suggestion to basket: $e');
    }
  }

  /// Add multiple order suggestions to basket
  Future<BatchBasketOperationResponse> addMultipleOrderSuggestionsToBasket(
    List<OrderSuggestionBasketRequest> requests,
  ) async {
    try {
      final uri = Uri.parse(
          '$baseUrl$orderSuggestionsPath/basket/add-multiple-suggestions');

      final response = await _client.post(
        uri,
        headers: _headers,
        body: json.encode(requests.map((req) => req.toJson()).toList()),
      );

      if (response.statusCode == 200) {
        return BatchBasketOperationResponse.fromJson(
            json.decode(response.body));
      } else {
        throw ApiException('Failed to add multiple suggestions to basket',
            response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error adding multiple suggestions to basket: $e');
    }
  }

  /// Get basket items grouped by supplier
  Future<Map<String, dynamic>> getBasketItemsGroupedBySupplier() async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/basket/grouped');

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException(
            'Failed to get grouped basket items', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting grouped basket items: $e');
    }
  }

  // ============ DEBUG FUNCTIONALITY ============

  /// Get debug information about products and their threshold status
  Future<Map<String, dynamic>> getDebugInfo() async {
    try {
      final uri = Uri.parse('$baseUrl$orderSuggestionsPath/debug');

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw ApiException('Failed to get debug info', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting debug info: $e');
    }
  }

  // ============ CATEGORIES AND BRANDS ============

  /// Get all active categories
  Future<List<Map<String, dynamic>>> getCategories({
    int? brandId,
    int? supplierId,
  }) async {
    try {
      final uri =
          Uri.parse('$baseUrl/items/categories').replace(queryParameters: {
        if (brandId != null) 'brandId': brandId.toString(),
        if (supplierId != null) 'supplierId': supplierId.toString(),
      });

      final response = await _getWithTimeout(
        uri,
        operationName: 'getCategories',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw ApiException('Failed to get categories', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting categories: $e');
    }
  }

  /// Get all active brands
  Future<List<Map<String, dynamic>>> getBrands({
    int? categoryId,
    int? supplierId,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/items/brands').replace(queryParameters: {
        if (categoryId != null) 'categoryId': categoryId.toString(),
        if (supplierId != null) 'supplierId': supplierId.toString(),
      });

      final response = await _getWithTimeout(
        uri,
        operationName: 'getBrands',
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => json as Map<String, dynamic>).toList();
      } else {
        throw ApiException('Failed to get brands', response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error getting brands: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}

// Helper classes
class PaginatedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool first;
  final bool last;

  PaginatedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.first,
    required this.last,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse<T>(
      content: (json['content'] as List<dynamic>)
          .map((item) => fromJsonT(item))
          .toList(),
      page: json['number'] ?? 0,
      size: json['size'] ?? 0,
      totalElements: json['totalElements'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      first: json['first'] ?? true,
      last: json['last'] ?? true,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}
