class InventoryAbcDsiSkuRow {
  final int? productId;
  final String? productName;
  final String? unit;
  final String category;
  final double revenueLast90Days;
  final int qtySoldLast90Days;
  final int onHandQty;
  final double onHandValue;
  final double cogsLast90Days;
  final double dsi;
  final double turnoverRate;
  final DateTime? lastSoldDate;
  final int? daysSinceLastSold;
  final bool shiftedToCategoryBInLast90Days;
  final bool deadStock90Plus;
  final bool deadStock120Plus;
  final bool zeroSalesLast180Days;
  final List<String> suggestedActions;

  const InventoryAbcDsiSkuRow({
    this.productId,
    this.productName,
    this.unit,
    required this.category,
    required this.revenueLast90Days,
    required this.qtySoldLast90Days,
    required this.onHandQty,
    required this.onHandValue,
    required this.cogsLast90Days,
    required this.dsi,
    required this.turnoverRate,
    this.lastSoldDate,
    this.daysSinceLastSold,
    required this.shiftedToCategoryBInLast90Days,
    required this.deadStock90Plus,
    required this.deadStock120Plus,
    required this.zeroSalesLast180Days,
    required this.suggestedActions,
  });

  factory InventoryAbcDsiSkuRow.fromJson(Map<String, dynamic> json) {
    final rawActions = (json['suggestedActions'] as List<dynamic>? ?? const []);
    return InventoryAbcDsiSkuRow(
      productId: (json['productId'] as num?)?.toInt(),
      productName: json['productName'] as String?,
      unit: json['unit'] as String?,
      category: (json['category'] as String?) ?? 'C',
      revenueLast90Days: (json['revenueLast90Days'] as num?)?.toDouble() ?? 0.0,
      qtySoldLast90Days: (json['qtySoldLast90Days'] as num?)?.toInt() ?? 0,
      onHandQty: (json['onHandQty'] as num?)?.toInt() ?? 0,
      onHandValue: (json['onHandValue'] as num?)?.toDouble() ?? 0.0,
      cogsLast90Days: (json['cogsLast90Days'] as num?)?.toDouble() ?? 0.0,
      dsi: (json['dsi'] as num?)?.toDouble() ?? 0.0,
      turnoverRate: (json['turnoverRate'] as num?)?.toDouble() ?? 0.0,
      lastSoldDate: (json['lastSoldDate'] as String?) != null
          ? DateTime.tryParse(json['lastSoldDate'] as String)
          : null,
      daysSinceLastSold: (json['daysSinceLastSold'] as num?)?.toInt(),
      shiftedToCategoryBInLast90Days:
          (json['shiftedToCategoryBInLast90Days'] as bool?) ?? false,
      deadStock90Plus: (json['deadStock90Plus'] as bool?) ?? false,
      deadStock120Plus: (json['deadStock120Plus'] as bool?) ?? false,
      zeroSalesLast180Days: (json['zeroSalesLast180Days'] as bool?) ?? false,
      suggestedActions: rawActions.map((e) => e.toString()).toList(),
    );
  }
}

class InventoryAbcDsiReport {
  final int windowDays;
  final int weeklySnapshotCount;
  final int totalSkus;
  final int categoryACount;
  final int categoryBCount;
  final int categoryCCount;
  final double totalRevenueLast90Days;
  final double totalCogsLast90Days;
  final double totalOnHandValue;
  final double storeAverageDsi;
  final int deadStock90PlusCount;
  final int deadStock120PlusCount;
  final List<InventoryAbcDsiSkuRow> allSkus;
  final List<InventoryAbcDsiSkuRow> categoryCAuditItems;

  const InventoryAbcDsiReport({
    required this.windowDays,
    required this.weeklySnapshotCount,
    required this.totalSkus,
    required this.categoryACount,
    required this.categoryBCount,
    required this.categoryCCount,
    required this.totalRevenueLast90Days,
    required this.totalCogsLast90Days,
    required this.totalOnHandValue,
    required this.storeAverageDsi,
    required this.deadStock90PlusCount,
    required this.deadStock120PlusCount,
    required this.allSkus,
    required this.categoryCAuditItems,
  });

  factory InventoryAbcDsiReport.fromJson(Map<String, dynamic> json) {
    final all = (json['allSkus'] as List<dynamic>? ?? const []);
    final audit = (json['categoryCAuditItems'] as List<dynamic>? ?? const []);

    return InventoryAbcDsiReport(
      windowDays: (json['windowDays'] as num?)?.toInt() ?? 90,
      weeklySnapshotCount: (json['weeklySnapshotCount'] as num?)?.toInt() ?? 13,
      totalSkus: (json['totalSkus'] as num?)?.toInt() ?? 0,
      categoryACount: (json['categoryACount'] as num?)?.toInt() ?? 0,
      categoryBCount: (json['categoryBCount'] as num?)?.toInt() ?? 0,
      categoryCCount: (json['categoryCCount'] as num?)?.toInt() ?? 0,
      totalRevenueLast90Days:
          (json['totalRevenueLast90Days'] as num?)?.toDouble() ?? 0.0,
      totalCogsLast90Days:
          (json['totalCogsLast90Days'] as num?)?.toDouble() ?? 0.0,
      totalOnHandValue: (json['totalOnHandValue'] as num?)?.toDouble() ?? 0.0,
      storeAverageDsi: (json['storeAverageDsi'] as num?)?.toDouble() ?? 0.0,
      deadStock90PlusCount: (json['deadStock90PlusCount'] as num?)?.toInt() ?? 0,
      deadStock120PlusCount:
          (json['deadStock120PlusCount'] as num?)?.toInt() ?? 0,
      allSkus: all
          .map((e) => InventoryAbcDsiSkuRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      categoryCAuditItems: audit
          .map((e) => InventoryAbcDsiSkuRow.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
