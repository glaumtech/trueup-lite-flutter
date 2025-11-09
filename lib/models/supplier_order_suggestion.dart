import 'package:json_annotation/json_annotation.dart';
import 'product_order_suggestion.dart';

part 'supplier_order_suggestion.g.dart';

@JsonSerializable()
class SupplierOrderSuggestion {
  final int? supplierId;
  final String? supplierName;
  final String? supplierEmail;
  final String? supplierPhone;
  final String? vendorCode;
  final List<ProductOrderSuggestion> products;
  final int? totalProducts;
  final int? totalSuggestedQuantity;
  final int? estimatedTotalCost;

  const SupplierOrderSuggestion({
    this.supplierId,
    this.supplierName,
    this.supplierEmail,
    this.supplierPhone,
    this.vendorCode,
    this.products = const [],
    this.totalProducts,
    this.totalSuggestedQuantity,
    this.estimatedTotalCost,
  });

  factory SupplierOrderSuggestion.fromJson(Map<String, dynamic> json) =>
      _$SupplierOrderSuggestionFromJson(json);

  Map<String, dynamic> toJson() => _$SupplierOrderSuggestionToJson(this);

  // Helper methods
  int get actualTotalProducts => products.length;
  
  int get actualTotalQuantity => products.fold(0, (sum, product) => sum + product.finalQuantity);
  
  int get actualTotalCost => products.fold(0, (sum, product) => sum + product.totalCost);
  
  List<ProductOrderSuggestion> get urgentProducts => 
      products.where((product) => product.isUrgent).toList();
  
  bool get hasUrgentProducts => urgentProducts.isNotEmpty;

  SupplierOrderSuggestion copyWith({
    int? supplierId,
    String? supplierName,
    String? supplierEmail,
    String? supplierPhone,
    String? vendorCode,
    List<ProductOrderSuggestion>? products,
    int? totalProducts,
    int? totalSuggestedQuantity,
    int? estimatedTotalCost,
  }) {
    return SupplierOrderSuggestion(
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      supplierEmail: supplierEmail ?? this.supplierEmail,
      supplierPhone: supplierPhone ?? this.supplierPhone,
      vendorCode: vendorCode ?? this.vendorCode,
      products: products ?? this.products,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSuggestedQuantity: totalSuggestedQuantity ?? this.totalSuggestedQuantity,
      estimatedTotalCost: estimatedTotalCost ?? this.estimatedTotalCost,
    );
  }
}
