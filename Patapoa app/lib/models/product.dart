import 'package:json_annotation/json_annotation.dart';

part 'product.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class Product {
  final int id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final int? stockQuantity;
  final int? merchantId;
  final int? categoryId;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Product({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    this.stockQuantity,
    this.merchantId,
    this.categoryId,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);
  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class Category {
  final int id;
  final String name;
  final String? description;
  final String? image;
  
  Category({
    required this.id,
    required this.name,
    this.description,
    this.image,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) => _$CategoryFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductCreateRequest {
  final String name;
  final String? description;
  final double price;
  final int stockQuantity;
  final int? categoryId;
  final String? image;
  
  ProductCreateRequest({
    required this.name,
    this.description,
    required this.price,
    required this.stockQuantity,
    this.categoryId,
    this.image,
  });
  
  factory ProductCreateRequest.fromJson(Map<String, dynamic> json) => _$ProductCreateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCreateRequestToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class ProductUpdateRequest {
  final String? name;
  final String? description;
  final double? price;
  final int? stockQuantity;
  final int? categoryId;
  final String? image;
  final bool? isAvailable;
  
  ProductUpdateRequest({
    this.name,
    this.description,
    this.price,
    this.stockQuantity,
    this.categoryId,
    this.image,
    this.isAvailable,
  });
  
  factory ProductUpdateRequest.fromJson(Map<String, dynamic> json) => _$ProductUpdateRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ProductUpdateRequestToJson(this);
}
