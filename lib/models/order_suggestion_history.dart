import 'package:json_annotation/json_annotation.dart';

part 'order_suggestion_history.g.dart';

@JsonSerializable()
class OrderSuggestionHistory {
  final int? id;
  final String? supplierName;
  final int totalProducts;
  final int totalSuggestedQuantity;
  final int estimatedCost;
  final String? actionTaken; // GENERATED, MODIFIED, ORDER_CREATED, EXPORTED
  final String? actionBy;
  @JsonKey(name: 'actionDate')
  final DateTime? actionDate;
  final String? notes;

  const OrderSuggestionHistory({
    this.id,
    this.supplierName,
    this.totalProducts = 0,
    this.totalSuggestedQuantity = 0,
    this.estimatedCost = 0,
    this.actionTaken,
    this.actionBy,
    this.actionDate,
    this.notes,
  });

  factory OrderSuggestionHistory.fromJson(Map<String, dynamic> json) =>
      _$OrderSuggestionHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSuggestionHistoryToJson(this);

  // Helper methods
  String get formattedActionDate {
    if (actionDate == null) return 'Unknown';
    return '${actionDate!.day}/${actionDate!.month}/${actionDate!.year} ${actionDate!.hour}:${actionDate!.minute.toString().padLeft(2, '0')}';
  }
  
  String get actionTypeDisplay {
    switch (actionTaken) {
      case 'GENERATED':
        return 'Generated';
      case 'MODIFIED':
        return 'Modified';
      case 'ORDER_CREATED':
        return 'Order Created';
      case 'EXPORTED':
        return 'Exported';
      default:
        return actionTaken ?? 'Unknown';
    }
  }

  OrderSuggestionHistory copyWith({
    int? id,
    String? supplierName,
    int? totalProducts,
    int? totalSuggestedQuantity,
    int? estimatedCost,
    String? actionTaken,
    String? actionBy,
    DateTime? actionDate,
    String? notes,
  }) {
    return OrderSuggestionHistory(
      id: id ?? this.id,
      supplierName: supplierName ?? this.supplierName,
      totalProducts: totalProducts ?? this.totalProducts,
      totalSuggestedQuantity: totalSuggestedQuantity ?? this.totalSuggestedQuantity,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actionTaken: actionTaken ?? this.actionTaken,
      actionBy: actionBy ?? this.actionBy,
      actionDate: actionDate ?? this.actionDate,
      notes: notes ?? this.notes,
    );
  }
}
