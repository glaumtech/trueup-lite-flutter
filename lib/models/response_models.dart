import 'package:json_annotation/json_annotation.dart';

part 'response_models.g.dart';

@JsonSerializable()
class OrderSuggestionUpdateResponse {
  final bool success;
  final String? message;
  final int? updatedCount;

  const OrderSuggestionUpdateResponse({
    required this.success,
    this.message,
    this.updatedCount,
  });

  factory OrderSuggestionUpdateResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderSuggestionUpdateResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSuggestionUpdateResponseToJson(this);
}

@JsonSerializable()
class PurchaseOrderCreationResponse {
  final bool success;
  final String? message;
  final String? orderId;
  final String? orderNumber;
  final int? totalItems;
  final int? totalCost;

  const PurchaseOrderCreationResponse({
    required this.success,
    this.message,
    this.orderId,
    this.orderNumber,
    this.totalItems,
    this.totalCost,
  });

  factory PurchaseOrderCreationResponse.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderCreationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderCreationResponseToJson(this);
}

@JsonSerializable()
class OrderSuggestionStatistics {
  final int totalProductsNeedingReorder;
  final int totalSuppliersAffected;
  final int estimatedTotalCost;
  final int urgentProducts;
  final String? lastGeneratedDate;

  const OrderSuggestionStatistics({
    this.totalProductsNeedingReorder = 0,
    this.totalSuppliersAffected = 0,
    this.estimatedTotalCost = 0,
    this.urgentProducts = 0,
    this.lastGeneratedDate,
  });

  factory OrderSuggestionStatistics.fromJson(Map<String, dynamic> json) =>
      _$OrderSuggestionStatisticsFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSuggestionStatisticsToJson(this);
}

@JsonSerializable()
class BasketOperationResponse {
  final bool success;
  final String? message;
  final int? basketCount;
  final int? basketTotal;
  final Map<String, dynamic>? additionalData;

  const BasketOperationResponse({
    required this.success,
    this.message,
    this.basketCount,
    this.basketTotal,
    this.additionalData,
  });

  factory BasketOperationResponse.fromJson(Map<String, dynamic> json) =>
      _$BasketOperationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BasketOperationResponseToJson(this);
}

@JsonSerializable()
class BatchBasketOperationResponse {
  final bool success;
  final String? message;
  final int successfulItems;
  final int failedItems;
  final List<String> errors;
  final int? basketCount;
  final int? basketTotal;

  const BatchBasketOperationResponse({
    required this.success,
    this.message,
    this.successfulItems = 0,
    this.failedItems = 0,
    this.errors = const [],
    this.basketCount,
    this.basketTotal,
  });

  factory BatchBasketOperationResponse.fromJson(Map<String, dynamic> json) =>
      _$BatchBasketOperationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BatchBasketOperationResponseToJson(this);
}
