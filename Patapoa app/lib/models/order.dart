import 'package:json_annotation/json_annotation.dart';
import 'product.dart';

part 'order.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Order {
  final int id;
  final String orderNumber;
  final String status;
  final double totalAmount;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? deliveryAddress;
  final String? deliveryNotes;
  final int? customerId;
  final int? merchantId;
  final int? riderId;
  final List<OrderItem>? items;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? riderName;
  final double? riderRating;
  
  Order({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.totalAmount,
    this.paymentMethod,
    this.paymentStatus,
    this.deliveryAddress,
    this.deliveryNotes,
    this.customerId,
    this.merchantId,
    this.riderId,
    this.items,
    this.createdAt,
    this.updatedAt,
    this.riderName,
    this.riderRating,
  });
  
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
  Map<String, dynamic> toJson() => _$OrderToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final String? productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final Product? product;
  
  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.product,
  });
  
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderCreateRequest {
  final List<OrderItemRequest> items;
  final String deliveryAddress;
  final String? deliveryNotes;
  final String? paymentMethod;
  
  OrderCreateRequest({
    required this.items,
    required this.deliveryAddress,
    this.deliveryNotes,
    this.paymentMethod,
  });
  
  factory OrderCreateRequest.fromJson(Map<String, dynamic> json) => _$OrderCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OrderCreateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderItemRequest {
  final int productId;
  final int quantity;
  
  OrderItemRequest({
    required this.productId,
    required this.quantity,
  });
  
  factory OrderItemRequest.fromJson(Map<String, dynamic> json) => _$OrderItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class OrderStatusUpdateRequest {
  final String status;
  final String? notes;
  
  OrderStatusUpdateRequest({
    required this.status,
    this.notes,
  });
  
  factory OrderStatusUpdateRequest.fromJson(Map<String, dynamic> json) => _$OrderStatusUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OrderStatusUpdateRequestToJson(this);
}
