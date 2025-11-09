import 'package:json_annotation/json_annotation.dart';

part 'po_basket_item.g.dart';

@JsonSerializable()
class POBasketItem {
  final String? type; // 'supplier', 'product', 'custom'
  final String? id; // unique identifier
  final String? name;
  final String? unit;
  final int? quantity;
  final int? price;
  final String? notes;
  final int? supplierId;
  final String? supplierName;
  final int? productId;
  
  // For display purposes
  final bool isUrgent;
  final int? currentStock;
  final int? reorderLevel;

  const POBasketItem({
    this.type,
    this.id,
    this.name,
    this.unit,
    this.quantity,
    this.price,
    this.notes,
    this.supplierId,
    this.supplierName,
    this.productId,
    this.isUrgent = false,
    this.currentStock,
    this.reorderLevel,
  });

  factory POBasketItem.fromJson(Map<String, dynamic> json) =>
      _$POBasketItemFromJson(json);

  Map<String, dynamic> toJson() => _$POBasketItemToJson(this);

  // Helper methods
  int get totalCost => (price ?? 0) * (quantity ?? 0);
  
  bool get isSupplierItem => type == 'supplier';
  
  bool get isProductItem => type == 'product';
  
  bool get isCustomItem => type == 'custom';

  POBasketItem copyWith({
    String? type,
    String? id,
    String? name,
    String? unit,
    int? quantity,
    int? price,
    String? notes,
    int? supplierId,
    String? supplierName,
    int? productId,
    bool? isUrgent,
    int? currentStock,
    int? reorderLevel,
  }) {
    return POBasketItem(
      type: type ?? this.type,
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      productId: productId ?? this.productId,
      isUrgent: isUrgent ?? this.isUrgent,
      currentStock: currentStock ?? this.currentStock,
      reorderLevel: reorderLevel ?? this.reorderLevel,
    );
  }
}
