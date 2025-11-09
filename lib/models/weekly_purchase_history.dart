import 'package:json_annotation/json_annotation.dart';

part 'weekly_purchase_history.g.dart';

@JsonSerializable()
class WeeklyPurchaseItem {
  final int? productId;
  final String? productName;
  final int? quantity;
  final double? unitPrice;
  final double? totalAmount;
  final String? supplierName;
  final DateTime? purchaseDate;

  const WeeklyPurchaseItem({
    this.productId,
    this.productName,
    this.quantity,
    this.unitPrice,
    this.totalAmount,
    this.supplierName,
    this.purchaseDate,
  });

  factory WeeklyPurchaseItem.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPurchaseItemFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyPurchaseItemToJson(this);
}

@JsonSerializable()
class WeeklyPurchaseHistory {
  final String? weekRange;
  @JsonKey(name: 'weekStartDate')
  final DateTime? weekStartDate;
  @JsonKey(name: 'weekEndDate')
  final DateTime? weekEndDate;
  final List<WeeklyPurchaseItem> purchaseItems;
  final int totalItems;
  final double totalAmount;

  const WeeklyPurchaseHistory({
    this.weekRange,
    this.weekStartDate,
    this.weekEndDate,
    this.purchaseItems = const [],
    this.totalItems = 0,
    this.totalAmount = 0.0,
  });

  factory WeeklyPurchaseHistory.fromJson(Map<String, dynamic> json) =>
      _$WeeklyPurchaseHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyPurchaseHistoryToJson(this);

  // Helper methods
  String get formattedWeekRange {
    if (weekStartDate != null && weekEndDate != null) {
      return '${weekStartDate!.day}/${weekStartDate!.month} - ${weekEndDate!.day}/${weekEndDate!.month}/${weekEndDate!.year}';
    }
    return weekRange ?? 'Unknown Week';
  }
  
  Map<String, List<WeeklyPurchaseItem>> get itemsBySupplier {
    final Map<String, List<WeeklyPurchaseItem>> grouped = {};
    for (final item in purchaseItems) {
      final supplierName = item.supplierName ?? 'Unknown Supplier';
      grouped.putIfAbsent(supplierName, () => []).add(item);
    }
    return grouped;
  }

  WeeklyPurchaseHistory copyWith({
    String? weekRange,
    DateTime? weekStartDate,
    DateTime? weekEndDate,
    List<WeeklyPurchaseItem>? purchaseItems,
    int? totalItems,
    double? totalAmount,
  }) {
    return WeeklyPurchaseHistory(
      weekRange: weekRange ?? this.weekRange,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      weekEndDate: weekEndDate ?? this.weekEndDate,
      purchaseItems: purchaseItems ?? this.purchaseItems,
      totalItems: totalItems ?? this.totalItems,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
