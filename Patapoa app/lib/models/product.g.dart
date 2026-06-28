// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Product _$ProductFromJson(Map<String, dynamic> json) => Product(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  image: json['image'] as String?,
  stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
  merchantId: (json['merchant_id'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  isAvailable: json['is_available'] as bool,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'image': instance.image,
  'stock_quantity': instance.stockQuantity,
  'merchant_id': instance.merchantId,
  'category_id': instance.categoryId,
  'is_available': instance.isAvailable,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
};

Category _$CategoryFromJson(Map<String, dynamic> json) => Category(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  image: json['image'] as String?,
);

Map<String, dynamic> _$CategoryToJson(Category instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'image': instance.image,
};

ProductCreateRequest _$ProductCreateRequestFromJson(
  Map<String, dynamic> json,
) => ProductCreateRequest(
  name: json['name'] as String,
  description: json['description'] as String?,
  price: (json['price'] as num).toDouble(),
  stockQuantity: (json['stock_quantity'] as num).toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  image: json['image'] as String?,
);

Map<String, dynamic> _$ProductCreateRequestToJson(
  ProductCreateRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'stock_quantity': instance.stockQuantity,
  'category_id': instance.categoryId,
  'image': instance.image,
};

ProductUpdateRequest _$ProductUpdateRequestFromJson(
  Map<String, dynamic> json,
) => ProductUpdateRequest(
  name: json['name'] as String?,
  description: json['description'] as String?,
  price: (json['price'] as num?)?.toDouble(),
  stockQuantity: (json['stock_quantity'] as num?)?.toInt(),
  categoryId: (json['category_id'] as num?)?.toInt(),
  image: json['image'] as String?,
  isAvailable: json['is_available'] as bool?,
);

Map<String, dynamic> _$ProductUpdateRequestToJson(
  ProductUpdateRequest instance,
) => <String, dynamic>{
  'name': instance.name,
  'description': instance.description,
  'price': instance.price,
  'stock_quantity': instance.stockQuantity,
  'category_id': instance.categoryId,
  'image': instance.image,
  'is_available': instance.isAvailable,
};
