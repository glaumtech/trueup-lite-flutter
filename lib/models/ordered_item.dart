import 'package:json_annotation/json_annotation.dart';
import 'po_basket_item.dart';

part 'ordered_item.g.dart';

@JsonSerializable()
class OrderedItem {
  @JsonKey(fromJson: _idFromJson, toJson: _idToJson)
  final String? id; // Basket item ID
  final String? type; // 'supplier', 'product', 'custom'
  final String? name;
  final String? unit;
  final int? quantity;
  final int? price;
  final String? notes;
  final int? supplierId;
  final String? supplierName;
  final int? productId;
  final String? brandName;

  // Ordered-specific fields
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime orderedDate;
  final String? orderNotes;
  final String? orderNumber; // Optional PO number if created

  OrderedItem({
    this.id,
    this.type,
    this.name,
    this.unit,
    this.quantity,
    this.price,
    this.notes,
    this.supplierId,
    this.supplierName,
    this.productId,
    this.brandName,
    required this.orderedDate,
    this.orderNotes,
    this.orderNumber,
  });

  factory OrderedItem.fromJson(Map<String, dynamic> json) =>
      _$OrderedItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderedItemToJson(this);

  // Helper functions for ID serialization (handles both String and int)
  static String? _idFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is int) return value.toString();
    return value.toString();
  }

  static String? _idToJson(String? value) => value;

  // Helper functions for DateTime serialization
  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) {
      return DateTime.parse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  static String _dateTimeToJson(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  // Convert from POBasketItem
  factory OrderedItem.fromBasketItem(
    POBasketItem item, {
    DateTime? orderedDate,
    String? orderNotes,
    String? orderNumber,
  }) {
    return OrderedItem(
      id: item.id,
      type: item.type,
      name: item.name,
      unit: item.unit,
      quantity: item.quantity,
      price: item.price,
      notes: item.notes,
      supplierId: item.supplierId,
      supplierName: item.supplierName,
      productId: item.productId,
      brandName: null, // Will be populated from product if needed
      orderedDate: orderedDate ?? DateTime.now(),
      orderNotes: orderNotes,
      orderNumber: orderNumber,
    );
  }

  // Convert back to POBasketItem (for unmarking as ordered)
  POBasketItem toBasketItem() {
    return POBasketItem(
      id: id,
      type: type,
      name: name,
      unit: unit,
      quantity: quantity,
      price: price,
      notes: notes,
      supplierId: supplierId,
      supplierName: supplierName,
      productId: productId,
    );
  }

  // Helper methods
  int get totalCost => (price ?? 0) * (quantity ?? 0);

  OrderedItem copyWith({
    String? id,
    String? type,
    String? name,
    String? unit,
    int? quantity,
    int? price,
    String? notes,
    int? supplierId,
    String? supplierName,
    int? productId,
    String? brandName,
    DateTime? orderedDate,
    String? orderNotes,
    String? orderNumber,
  }) {
    return OrderedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      notes: notes ?? this.notes,
      supplierId: supplierId ?? this.supplierId,
      supplierName: supplierName ?? this.supplierName,
      productId: productId ?? this.productId,
      brandName: brandName ?? this.brandName,
      orderedDate: orderedDate ?? this.orderedDate,
      orderNotes: orderNotes ?? this.orderNotes,
      orderNumber: orderNumber ?? this.orderNumber,
    );
  }
}
