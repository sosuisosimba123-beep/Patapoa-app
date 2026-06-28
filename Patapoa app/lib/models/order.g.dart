// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  orderNumber: json['order_number'] as String,
  status: json['status'] as String,
  totalAmount: (json['total_amount'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String?,
  paymentStatus: json['payment_status'] as String?,
  deliveryAddress: json['delivery_address'] as String?,
  deliveryNotes: json['delivery_notes'] as String?,
  customerId: (json['customer_id'] as num?)?.toInt(),
  merchantId: (json['merchant_id'] as num?)?.toInt(),
  riderId: (json['rider_id'] as num?)?.toInt(),
  items: (json['items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  riderName: json['rider_name'] as String?,
  riderRating: (json['rider_rating'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'order_number': instance.orderNumber,
  'status': instance.status,
  'total_amount': instance.totalAmount,
  'payment_method': instance.paymentMethod,
  'payment_status': instance.paymentStatus,
  'delivery_address': instance.deliveryAddress,
  'delivery_notes': instance.deliveryNotes,
  'customer_id': instance.customerId,
  'merchant_id': instance.merchantId,
  'rider_id': instance.riderId,
  'items': instance.items,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'rider_name': instance.riderName,
  'rider_rating': instance.riderRating,
};

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num).toInt(),
  orderId: (json['order_id'] as num).toInt(),
  productId: (json['product_id'] as num).toInt(),
  productName: json['product_name'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  totalPrice: (json['total_price'] as num).toDouble(),
  product: json['product'] == null
      ? null
      : Product.fromJson(json['product'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'order_id': instance.orderId,
  'product_id': instance.productId,
  'product_name': instance.productName,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'total_price': instance.totalPrice,
  'product': instance.product,
};

OrderCreateRequest _$OrderCreateRequestFromJson(Map<String, dynamic> json) =>
    OrderCreateRequest(
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItemRequest.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: json['delivery_address'] as String,
      deliveryNotes: json['delivery_notes'] as String?,
      paymentMethod: json['payment_method'] as String?,
    );

Map<String, dynamic> _$OrderCreateRequestToJson(OrderCreateRequest instance) =>
    <String, dynamic>{
      'items': instance.items,
      'delivery_address': instance.deliveryAddress,
      'delivery_notes': instance.deliveryNotes,
      'payment_method': instance.paymentMethod,
    };

OrderItemRequest _$OrderItemRequestFromJson(Map<String, dynamic> json) =>
    OrderItemRequest(
      productId: (json['product_id'] as num).toInt(),
      quantity: (json['quantity'] as num).toInt(),
    );

Map<String, dynamic> _$OrderItemRequestToJson(OrderItemRequest instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'quantity': instance.quantity,
    };

OrderStatusUpdateRequest _$OrderStatusUpdateRequestFromJson(
  Map<String, dynamic> json,
) => OrderStatusUpdateRequest(
  status: json['status'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$OrderStatusUpdateRequestToJson(
  OrderStatusUpdateRequest instance,
) => <String, dynamic>{'status': instance.status, 'notes': instance.notes};
