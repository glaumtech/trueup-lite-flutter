import 'package:intl/intl.dart';

class PurchaseV2CreateItemLine {
  final int productId;
  final String name;
  final String unit;
  final int qty;
  final int freeQty;
  final double price;
  final double discount;
  final double tax;
  final double total;
  final DateTime manufactureDate;
  final DateTime? expiryDate;

  const PurchaseV2CreateItemLine({
    required this.productId,
    required this.name,
    required this.unit,
    required this.qty,
    this.freeQty = 0,
    required this.price,
    required this.discount,
    required this.tax,
    required this.total,
    required this.manufactureDate,
    required this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'unit': unit,
      'qty': qty,
      'freeQty': freeQty,
      'price': price,
      'discount': discount,
      'tax': tax,
      'total': total,
      'manufactureDate': _formatDate(manufactureDate),
      'expiryDate': expiryDate != null ? _formatDate(expiryDate!) : null,
    };
  }
}

class PurchaseV2CreatePurchaseMeta {
  final String billNo;
  final DateTime billDate;
  final String paymentMode;
  final DateTime? dueDate;
  final String? poNo;
  final DateTime? poDate;
  final String? termsConditions;
  final String? privateNotes;
  final double? shippingCharges;
  final String? billImageUrl;

  const PurchaseV2CreatePurchaseMeta({
    required this.billNo,
    required this.billDate,
    required this.paymentMode,
    this.dueDate,
    this.poNo,
    this.poDate,
    this.termsConditions,
    this.privateNotes,
    this.shippingCharges,
    this.billImageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'billNo': billNo,
      'billDate': _formatDate(billDate),
      'dueDate': dueDate != null ? _formatDate(dueDate!) : null,
      'poNo': poNo,
      'poDate': poDate != null ? _formatDate(poDate!) : null,
      'paymentMode': paymentMode,
      'termsConditions': termsConditions,
      'privateNotes': privateNotes,
      'shippingCharges': shippingCharges,
      'billImageUrl': billImageUrl,
    };
  }
}

class PurchaseV2CreateRequest {
  final int vendorId;
  final PurchaseV2CreatePurchaseMeta purchase;
  final List<PurchaseV2CreateItemLine> items;
  final double totalAmount;

  const PurchaseV2CreateRequest({
    required this.vendorId,
    required this.purchase,
    required this.items,
    required this.totalAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'purchase': purchase.toJson(),
      'items': items.map((e) => e.toJson()).toList(),
      'totalAmount': totalAmount,
    };
  }
}

class PurchaseV2CreateResponse {
  final String? status;
  final String? message;
  final int? purchaseId;
  final String? billNo;
  final double? totalAmount;
  final int? itemCount;

  const PurchaseV2CreateResponse({
    this.status,
    this.message,
    this.purchaseId,
    this.billNo,
    this.totalAmount,
    this.itemCount,
  });

  factory PurchaseV2CreateResponse.fromJson(Map<String, dynamic> json) {
    return PurchaseV2CreateResponse(
      status: json['status'] as String?,
      message: json['message'] as String?,
      purchaseId: json['purchaseId'] != null ? (json['purchaseId'] as num).toInt() : null,
      billNo: json['billNo'] as String?,
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : null,
      itemCount: json['itemCount'] != null ? (json['itemCount'] as num).toInt() : null,
    );
  }
}

class PurchaseV2Summary {
  final int id;
  final String billNo;
  final DateTime billDate;
  final String supplierName;
  final String paymentMode;
  final double totalAmount;
  final double paid;
  final double due;
  final int itemCount;

  const PurchaseV2Summary({
    required this.id,
    required this.billNo,
    required this.billDate,
    required this.supplierName,
    required this.paymentMode,
    required this.totalAmount,
    required this.paid,
    required this.due,
    required this.itemCount,
  });

  factory PurchaseV2Summary.fromJson(Map<String, dynamic> json) {
    return PurchaseV2Summary(
      id: (json['id'] as num).toInt(),
      billNo: json['billNo'] as String? ?? '',
      billDate: DateTime.parse(json['billDate'] as String),
      supplierName: json['supplierName'] as String? ?? '',
      paymentMode: json['paymentMode'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num).toDouble(),
      paid: json['paid'] != null ? (json['paid'] as num).toDouble() : 0.0,
      due: json['due'] != null ? (json['due'] as num).toDouble() : 0.0,
      itemCount: json['itemCount'] != null ? (json['itemCount'] as num).toInt() : 0,
    );
  }
}

class PurchaseV2SupplierMini {
  final int id;
  final String name;

  const PurchaseV2SupplierMini({required this.id, required this.name});

  factory PurchaseV2SupplierMini.fromJson(Map<String, dynamic> json) {
    return PurchaseV2SupplierMini(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String? ?? '',
    );
  }
}

class PurchaseV2DetailItem {
  final int productId;
  final String name;
  final String unit;
  final int qty;
  final int freeQty;
  final double price;
  final double discount;
  final double tax;
  final double total;
  final DateTime? manufactureDate;
  final DateTime? expiryDate;

  const PurchaseV2DetailItem({
    required this.productId,
    required this.name,
    required this.unit,
    required this.qty,
    this.freeQty = 0,
    required this.price,
    required this.discount,
    required this.tax,
    required this.total,
    required this.manufactureDate,
    required this.expiryDate,
  });

  factory PurchaseV2DetailItem.fromJson(Map<String, dynamic> json) {
    final manufacture = json['manufactureDate'] as String?;
    final expiry = json['expiryDate'] as String?;
    return PurchaseV2DetailItem(
      productId: (json['productId'] as num).toInt(),
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      qty: (json['qty'] as num).toInt(),
      freeQty: json['freeQty'] != null ? (json['freeQty'] as num).toInt() : 0,
      price: (json['price'] as num).toDouble(),
      discount: json['discount'] != null ? (json['discount'] as num).toDouble() : 0.0,
      tax: json['tax'] != null ? (json['tax'] as num).toDouble() : 0.0,
      total: json['total'] != null ? (json['total'] as num).toDouble() : 0.0,
      manufactureDate: manufacture != null && manufacture.isNotEmpty
          ? DateTime.parse(manufacture)
          : null,
      expiryDate: expiry != null && expiry.isNotEmpty ? DateTime.parse(expiry) : null,
    );
  }
}

class PurchaseV2Detail {
  final int id;
  final String billNo;
  final DateTime billDate;
  final DateTime? dueDate;
  final String? poNo;
  final DateTime? poDate;
  final String paymentMode;
  final String? termsConditions;
  final String? privateNotes;
  final double? shippingCharges;
  final double totalAmount;
  final PurchaseV2SupplierMini? supplier;
  final String? billImageUrl;
  final List<PurchaseV2DetailItem> items;

  const PurchaseV2Detail({
    required this.id,
    required this.billNo,
    required this.billDate,
    required this.dueDate,
    required this.poNo,
    required this.poDate,
    required this.paymentMode,
    required this.termsConditions,
    required this.privateNotes,
    required this.shippingCharges,
    required this.totalAmount,
    required this.supplier,
    required this.billImageUrl,
    required this.items,
  });

  factory PurchaseV2Detail.fromJson(Map<String, dynamic> json) {
    final supplierJson = json['supplier'] as Map<String, dynamic>?;
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return PurchaseV2Detail(
      id: (json['id'] as num).toInt(),
      billNo: json['billNo'] as String? ?? '',
      billDate: DateTime.parse(json['billDate'] as String),
      dueDate: (json['dueDate'] as String?)?.isNotEmpty == true
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      poNo: json['poNo'] as String?,
      poDate: (json['poDate'] as String?)?.isNotEmpty == true
          ? DateTime.parse(json['poDate'] as String)
          : null,
      paymentMode: json['paymentMode'] as String? ?? '',
      termsConditions: json['termsConditions'] as String?,
      privateNotes: json['privateNotes'] as String?,
      shippingCharges:
          json['shippingCharges'] != null ? (json['shippingCharges'] as num).toDouble() : null,
      totalAmount: json['totalAmount'] != null ? (json['totalAmount'] as num).toDouble() : 0.0,
      supplier: supplierJson != null ? PurchaseV2SupplierMini.fromJson(supplierJson) : null,
      billImageUrl: json['billImageUrl'] as String?,
      items: itemsJson.map((e) => PurchaseV2DetailItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

