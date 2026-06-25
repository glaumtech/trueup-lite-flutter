class AdminStoreOrder {
  final String id;
  final String date;
  final String? createdAt;
  final double total;
  final double shippingFee;
  final String status;
  final String paymentMethod;
  final String? staffNotes;
  final ShippingAddress shippingAddress;
  final List<AdminOrderItem> items;

  const AdminStoreOrder({
    required this.id,
    required this.date,
    this.createdAt,
    required this.total,
    required this.shippingFee,
    required this.status,
    required this.paymentMethod,
    this.staffNotes,
    required this.shippingAddress,
    required this.items,
  });

  factory AdminStoreOrder.fromJson(Map<String, dynamic> json) {
    final address = json['shippingAddress'] as Map<String, dynamic>? ?? {};
    final itemsJson = json['items'] as List<dynamic>? ?? [];

    return AdminStoreOrder(
      id: json['orderRef'] as String? ?? '',
      date: json['orderDate'] as String? ?? '',
      createdAt: json['createdAt'] as String?,
      total: _toDouble(json['total']),
      shippingFee: _toDouble(json['shippingFee'], fallback: 60),
      status: normalizeOrderStatus(json['status'] as String? ?? 'Pending'),
      paymentMethod: json['paymentMethod'] as String? ?? 'Cash on Delivery',
      staffNotes: json['staffNotes'] as String?,
      shippingAddress: ShippingAddress.fromJson(address),
      items: itemsJson
          .map((e) => AdminOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get subtotal =>
      items.fold(0, (sum, item) => sum + lineTotal(item));
}

class AdminOrderItem {
  final String name;
  final int qty;
  final double price;

  const AdminOrderItem({
    required this.name,
    required this.qty,
    required this.price,
  });

  factory AdminOrderItem.fromJson(Map<String, dynamic> json) {
    return AdminOrderItem(
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int? ?? 0,
      price: _toDouble(json['unitPrice']),
    );
  }
}

class ShippingAddress {
  final String name;
  final String email;
  final String street;
  final String city;
  final String state;
  final String zip;
  final String phone;

  const ShippingAddress({
    required this.name,
    required this.email,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
    required this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      street: json['street'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

const double defaultShippingFee = 60;

String normalizeOrderStatus(String status) {
  if (status == 'Processing') return 'Pending';
  return status;
}

double lineTotal(AdminOrderItem item) => item.price * item.qty;

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

Map<String, int> countOrdersByStatus(List<AdminStoreOrder> orders) {
  final counts = <String, int>{
    'Pending': 0,
    'Accepted': 0,
    'Shipped': 0,
    'Delivered': 0,
    'Cancelled': 0,
  };
  for (final order in orders) {
    final status = normalizeOrderStatus(order.status);
    if (counts.containsKey(status)) {
      counts[status] = counts[status]! + 1;
    }
  }
  return counts;
}
