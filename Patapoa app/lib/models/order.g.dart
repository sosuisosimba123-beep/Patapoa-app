// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  id: (json['id'] as num).toInt(),
  productId: (json['product_id'] as num).toInt(),
  merchantId: (json['merchant_id'] as num?)?.toInt(),
  productName: json['product_name'] as String,
  brand: json['brand'] as String?,
  unit: json['unit'] as String?,
  productDescription: json['product_description'] as String?,
  productImage: json['product_image'] as String?,
  quantity: (json['quantity'] as num).toInt(),
  unitPrice: (json['unit_price'] as num).toDouble(),
  subtotal: (json['subtotal'] as num).toDouble(),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'id': instance.id,
  'product_id': instance.productId,
  'merchant_id': instance.merchantId,
  'product_name': instance.productName,
  'brand': instance.brand,
  'unit': instance.unit,
  'product_description': instance.productDescription,
  'product_image': instance.productImage,
  'quantity': instance.quantity,
  'unit_price': instance.unitPrice,
  'subtotal': instance.subtotal,
};

Order _$OrderFromJson(Map<String, dynamic> json) => Order(
  id: (json['id'] as num).toInt(),
  displayId: json['display_id'] as String,
  customerId: (json['customer_id'] as num).toInt(),
  riderId: (json['rider_id'] as num?)?.toInt(),
  addressId: (json['address_id'] as num).toInt(),
  status: json['status'] as String,
  subtotal: (json['subtotal'] as num).toDouble(),
  deliveryFee: (json['delivery_fee'] as num).toDouble(),
  platformFee: (json['platform_fee'] as num).toDouble(),
  total: (json['total'] as num).toDouble(),
  paymentMethod: json['payment_method'] as String,
  paymentStatus: json['payment_status'] as String,
  customerNotes: json['customer_notes'] as String?,
  placedAt: json['placed_at'] == null
      ? null
      : DateTime.parse(json['placed_at'] as String),
  orderItems: (json['order_items'] as List<dynamic>?)
      ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  address: json['address'] as Map<String, dynamic>?,
  customer: json['customer'] as Map<String, dynamic>?,
  rider: json['rider'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
  'id': instance.id,
  'display_id': instance.displayId,
  'customer_id': instance.customerId,
  'rider_id': instance.riderId,
  'address_id': instance.addressId,
  'status': instance.status,
  'subtotal': instance.subtotal,
  'delivery_fee': instance.deliveryFee,
  'platform_fee': instance.platformFee,
  'total': instance.total,
  'payment_method': instance.paymentMethod,
  'payment_status': instance.paymentStatus,
  'customer_notes': instance.customerNotes,
  'placed_at': instance.placedAt?.toIso8601String(),
  'order_items': instance.orderItems,
  'address': instance.address,
  'customer': instance.customer,
  'rider': instance.rider,
};
