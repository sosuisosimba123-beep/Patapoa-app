import 'package:flutter/foundation.dart';

class OrderItem {
  final String id;
  final String productId;
  final String? merchantId;
  final String productName;
  final String? brand;
  final String? unit;
  final String? productDescription;
  final String? productImage;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  OrderItem({
    required this.id,
    required this.productId,
    this.merchantId,
    required this.productName,
    this.brand,
    this.unit,
    this.productDescription,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  String get fullDisplayName {
    final b = brand ?? '';
    final u = unit ?? '';
    if (b.isNotEmpty && u.isNotEmpty) return '$b $productName ($u)';
    if (b.isNotEmpty) return '$b $productName';
    if (u.isNotEmpty) return '$productName ($u)';
    return productName;
  }

  double get totalPrice => subtotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final priceAtSale = (json['price_at_sale'] ?? json['unit_price'] ?? 0.0) as num;
    final qty = (json['quantity'] ?? 1) as num;
    
    return OrderItem(
      id: json['id'].toString(),
      productId: (json['product_id'] ?? json['product']).toString(),
      merchantId: (json['merchant_id'] ?? json['merchant']).toString(),
      productName: json['product_name'] as String? ?? 'Product',
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      productDescription: json['product_description'] as String?,
      productImage: json['product_image'] as String?,
      quantity: qty.toInt(),
      unitPrice: priceAtSale.toDouble(),
      subtotal: (json['subtotal'] ?? (priceAtSale * qty)).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'merchant_id': merchantId,
      'product_name': productName,
      'brand': brand,
      'unit': unit,
      'product_description': productDescription,
      'product_image': productImage,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
    };
  }
}

class Order {
  final String id;
  final String displayId;
  final String customerId;
  final String? riderId;
  final String addressId;
  final String status;
  final double subtotal;
  final double deliveryFee;
  final double platformFee;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final String? customerNotes;
  final DateTime? placedAt;
  final List<OrderItem>? orderItems;
  final Map<String, dynamic>? address;
  final Map<String, dynamic>? customer;
  final Map<String, dynamic>? rider;

  Order({
    required this.id,
    required this.displayId,
    required this.customerId,
    this.riderId,
    required this.addressId,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.platformFee,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    this.customerNotes,
    this.placedAt,
    this.orderItems,
    this.address,
    this.customer,
    this.rider,
  });

  String get orderNumber => displayId;
  double get totalAmount => total;

  String? get riderName => rider?['user']?['name'];
  double? get riderRating => (rider?['rating'] as num?)?.toDouble();

  String get merchantName => orderItems?.first.productName ?? 'Store';
  String? get merchantImage => orderItems?.first.productImage;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      displayId: json['order_number']?.toString() ?? json['id'].toString(),
      customerId: (json['customer_id'] ?? json['customer']).toString(),
      riderId: json['rider']?.toString(),
      addressId: (json['address_id'] ?? json['delivery_address'] ?? 'Not Set').toString(),
      status: json['status'] as String? ?? 'placed',
      subtotal: (json['subtotal'] ?? json['total_amount'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platform_fee'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] ?? json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'] as String? ?? 'Cash',
      paymentStatus: json['payment_status'] as String? ?? 'Pending',
      customerNotes: json['customer_notes'] as String?,
      placedAt: json['created'] == null ? null : DateTime.parse(json['created'] as String),
      orderItems: json['expand']?['order_items_via_order'] != null
          ? (json['expand']['order_items_via_order'] as List).map((i) => OrderItem.fromJson(i.data)).toList()
          : (json['order_items'] as List?)?.map((i) => OrderItem.fromJson(i)).toList(),
      address: json['address'] is Map ? json['address'] as Map<String, dynamic> : null,
      customer: json['expand']?['customer']?.data,
      rider: json['expand']?['rider']?.data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': displayId,
      'customer': customerId,
      'rider': riderId,
      'Address': addressId,
      'status': status,
      'total_amount': total,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
      'customer_notes': customerNotes,
    };
  }
}
