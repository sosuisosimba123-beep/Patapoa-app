import 'package:json_annotation/json_annotation.dart';

part 'order.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItem {
  final int id;
  final int productId;
  final int? merchantId;
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

  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Order {
  final int id;
  final String displayId;
  final int customerId;
  final int? riderId;
  final int addressId;
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

  String get merchantName => orderItems?.first.fullDisplayName ?? 'Store';
  String? get merchantImage => orderItems?.first.productImage;

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}
