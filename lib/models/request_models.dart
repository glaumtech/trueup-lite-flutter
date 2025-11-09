import 'package:json_annotation/json_annotation.dart';

part 'request_models.g.dart';

@JsonSerializable()
class OrderSuggestionBasketRequest {
  final int? supplierId;
  final int? productId;
  final int? quantity;
  final String? notes;

  const OrderSuggestionBasketRequest({
    this.supplierId,
    this.productId,
    this.quantity,
    this.notes,
  });

  factory OrderSuggestionBasketRequest.fromJson(Map<String, dynamic> json) =>
      _$OrderSuggestionBasketRequestFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSuggestionBasketRequestToJson(this);
}

@JsonSerializable()
class OrderQuantityUpdate {
  final int? productId;
  final int? supplierId;
  final int? newQuantity;
  final String? notes;

  const OrderQuantityUpdate({
    this.productId,
    this.supplierId,
    this.newQuantity,
    this.notes,
  });

  factory OrderQuantityUpdate.fromJson(Map<String, dynamic> json) =>
      _$OrderQuantityUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$OrderQuantityUpdateToJson(this);
}

@JsonSerializable()
class CreatePurchaseOrderRequest {
  final int? supplierId;
  final String? supplierName;
  final List<PurchaseOrderItem> items;
  final String? notes;
  final String? expectedDeliveryDate;
  final String? priority; // HIGH, MEDIUM, LOW

  const CreatePurchaseOrderRequest({
    this.supplierId,
    this.supplierName,
    this.items = const [],
    this.notes,
    this.expectedDeliveryDate,
    this.priority,
  });

  factory CreatePurchaseOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreatePurchaseOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreatePurchaseOrderRequestToJson(this);
}

@JsonSerializable()
class PurchaseOrderItem {
  final int? productId;
  final String? productName;
  final int? quantity;
  final int? unitPrice;
  final String? notes;

  const PurchaseOrderItem({
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.notes,
  });

  factory PurchaseOrderItem.fromJson(Map<String, dynamic> json) =>
      _$PurchaseOrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$PurchaseOrderItemToJson(this);
}

@JsonSerializable()
class CreateBasketPurchaseOrderRequest {
  final String? notes;
  final String? expectedDeliveryDate;
  final String? priority;
  final bool clearBasketAfterOrder;

  const CreateBasketPurchaseOrderRequest({
    this.notes,
    this.expectedDeliveryDate,
    this.priority,
    this.clearBasketAfterOrder = true,
  });

  factory CreateBasketPurchaseOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateBasketPurchaseOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateBasketPurchaseOrderRequestToJson(this);
}
