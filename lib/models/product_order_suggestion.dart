import 'package:json_annotation/json_annotation.dart';

part 'product_order_suggestion.g.dart';

@JsonSerializable()
class ProductOrderSuggestion {
  final int? productId;
  final String? productName;
  final String? productCode;
  final String? unit;
  final int? currentStock;
  final int? minimumThreshold;
  final int? stockDeficit;
  final int? suggestedQuantity;
  final int? minimumOrderQuantity;
  final int? supplierPrice;
  final int? mrp;
  final int? leadTimeDays;
  final String? categoryName;
  final String? brandName;
  final String? supplierProductCode;
  final bool isPrimarySupplier;
  final int? supplierId;
  final String? supplierName;

  // For user adjustments
  final int? adjustedQuantity;
  final String? adjustmentNotes;

  const ProductOrderSuggestion({
    this.productId,
    this.productName,
    this.productCode,
    this.unit,
    this.currentStock,
    this.minimumThreshold,
    this.stockDeficit,
    this.suggestedQuantity,
    this.minimumOrderQuantity,
    this.supplierPrice,
    this.mrp,
    this.leadTimeDays,
    this.categoryName,
    this.brandName,
    this.supplierProductCode,
    this.isPrimarySupplier = false,
    this.supplierId,
    this.supplierName,
    this.adjustedQuantity,
    this.adjustmentNotes,
  });

  factory ProductOrderSuggestion.fromJson(Map<String, dynamic> json) =>
      _$ProductOrderSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$ProductOrderSuggestionToJson(this);

  // Helper methods
  int get finalQuantity => adjustedQuantity ?? suggestedQuantity ?? 0;

  int get totalCost => (supplierPrice ?? 0) * finalQuantity;

  bool get isUrgent => (currentStock ?? 0) <= ((minimumThreshold ?? 0) * 0.5);

  double get stockRatio => minimumThreshold != null && minimumThreshold! > 0
      ? (currentStock ?? 0) / minimumThreshold!
      : 0.0;

  ProductOrderSuggestion copyWith({
    int? productId,
    String? productName,
    String? productCode,
    String? unit,
    int? currentStock,
    int? minimumThreshold,
    int? stockDeficit,
    int? suggestedQuantity,
    int? minimumOrderQuantity,
    int? supplierPrice,
    int? mrp,
    int? leadTimeDays,
    String? categoryName,
    String? brandName,
    String? supplierProductCode,
    bool? isPrimarySupplier,
    int? supplierId,
    String? supplierName,
    int? adjustedQuantity,
    String? adjustmentNotes,
  }) {
    return ProductOrderSuggestion(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minimumThreshold: minimumThreshold ?? this.minimumThreshold,
      stockDeficit: stockDeficit ?? this.stockDeficit,
      suggestedQuantity: suggestedQuantity ?? this.suggestedQuantity,
      minimumOrderQuantity: minimumOrderQuantity ?? this.minimumOrderQuantity,
      supplierPrice: supplierPrice ?? this.supplierPrice,
      mrp: mrp ?? this.mrp,
      leadTimeDays: leadTimeDays ?? this.leadTimeDays,
      categoryName: categoryName ?? this.categoryName,
      brandName: brandName ?? this.brandName,
      supplierProductCode: supplierProductCode ?? this.supplierProductCode,
      isPrimarySupplier: isPrimarySupplier ?? this.isPrimarySupplier,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      adjustedQuantity: adjustedQuantity ?? this.adjustedQuantity,
      adjustmentNotes: adjustmentNotes ?? this.adjustmentNotes,
    );
  }
}
