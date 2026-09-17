import 'package:flutter/foundation.dart';
import '../utils/number_utils.dart';

class PrimaryCategory {
  final String id;
  final String name;
  final String slug;
  final String? imageUrl;
  final List<SecondaryCategory>? secondaryCategories;

  PrimaryCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.secondaryCategories,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrimaryCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory PrimaryCategory.fromJson(Map<String, dynamic> json) {
    return PrimaryCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String? ?? json['icon_url'] as String?,
      secondaryCategories: json['secondary_categories'] != null 
          ? (json['secondary_categories'] as List).map((i) => SecondaryCategory.fromJson(i as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    };
  }
}

class SecondaryCategory {
  final String id;
  final String primaryCategoryId;
  final String name;
  final String slug;
  final String? imageUrl;
  final PrimaryCategory? primaryCategory;

  SecondaryCategory({
    required this.id,
    required this.primaryCategoryId,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.primaryCategory,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecondaryCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  factory SecondaryCategory.fromJson(Map<String, dynamic> json) {
    return SecondaryCategory(
      id: json['id'].toString(),
      primaryCategoryId: (json['primary_category_id'] ?? json['primary_category']).toString(),
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String? ?? json['icon_url'] as String?,
      primaryCategory: json['primary_category'] != null && json['primary_category'] is Map
          ? PrimaryCategory.fromJson(json['primary_category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'primary_category': primaryCategoryId,
      'name': name,
      'slug': slug,
      'image_url': imageUrl,
    };
  }
}

class MasterProduct {
  final String id;
  final String name;
  final String? brand;
  final String? description;
  final String? primaryImageUrl;
  final String? backupImageUrl;
  final String? barcode;
  final String? secondaryCategoryId;
  final SecondaryCategory? secondaryCategory;

  MasterProduct({
    required this.id,
    required this.name,
    this.brand,
    this.description,
    this.primaryImageUrl,
    this.backupImageUrl,
    this.barcode,
    this.secondaryCategoryId,
    this.secondaryCategory,
  });

  factory MasterProduct.fromJson(Map<String, dynamic> json) {
    return MasterProduct(
      id: json['id'].toString(),
      name: json['name'] as String,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      primaryImageUrl: json['primary_image_url'] as String?,
      backupImageUrl: json['backup_image_url'] as String?,
      barcode: json['barcode'] as String?,
      secondaryCategoryId: (json['secondary_category_id'] ?? json['category']).toString(),
      secondaryCategory: json['secondary_category'] != null && json['secondary_category'] is Map
          ? SecondaryCategory.fromJson(json['secondary_category'] as Map<String, dynamic>) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'description': description,
      'barcode': barcode,
      'category': secondaryCategoryId,
    };
  }

  String get categorySlug => secondaryCategory?.slug ?? 'other';
}

class Product {
  final String id;
  final String? name;
  final String? brand;
  final String? unit;
  final String? description;
  final double price;
  final String? image;
  final int? stockQuantity;
  final String? merchantId;
  final String? secondaryCategoryId;
  final SecondaryCategory? secondaryCategory;
  final String? masterProductId;
  final MasterProduct? masterProduct;
  final bool isAvailable;
  final double distance;
  final Map<String, dynamic>? merchant;
  final bool isCustom;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  Product({
    required this.id,
    this.name,
    this.brand,
    this.unit,
    this.description,
    required this.price,
    this.image,
    this.stockQuantity,
    this.merchantId,
    this.secondaryCategoryId,
    this.secondaryCategory,
    this.masterProductId,
    this.masterProduct,
    required this.isAvailable,
    this.distance = 0.0,
    this.merchant,
    this.isCustom = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] ?? json['Description'] as String?,
      price: NumberUtils.toDouble(json['price'] ?? json['Price']),
      image: json['image'] ?? json['Image_url'] as String?,
      stockQuantity: NumberUtils.paramInt(json['stock_quantity'] ?? json['stock_count']),
      merchantId: (json['merchant_id'] ?? json['merchant']).toString(),
      secondaryCategoryId: (json['secondary_category_id'] ?? json['category']).toString(),
      secondaryCategory: json['secondary_category'] != null && json['secondary_category'] is Map
          ? SecondaryCategory.fromJson(json['secondary_category'] as Map<String, dynamic>) 
          : null,
      masterProductId: json['master_product_id']?.toString(),
      masterProduct: json['master_product'] != null && json['master_product'] is Map
          ? MasterProduct.fromJson(json['master_product'] as Map<String, dynamic>) 
          : null,
      isAvailable: json['is_available'] as bool? ?? true,
      distance: NumberUtils.toDouble(json['distance']),
      merchant: json['merchant'] is Map ? json['merchant'] as Map<String, dynamic> : null,
      isCustom: json['is_custom'] as bool? ?? false,
      createdAt: json['created'] == null ? null : DateTime.parse(json['created'] as String),
      updatedAt: json['updated'] == null ? null : DateTime.parse(json['updated'] as String),
    );
  }

  bool get isSimulation => 
    isCustom || 
    (merchant?['store_name']?.toString().contains('Simulation') ?? false);

  String get displayName => masterProduct?.name ?? name ?? 'Product';

  String get fullDisplayName {
    final base = displayName;
    final b = brand ?? '';
    final u = unit ?? '';
    
    if (b.isNotEmpty && u.isNotEmpty) return '$b $base ($u)';
    if (b.isNotEmpty) return '$b $base';
    if (u.isNotEmpty) return '$base ($u)';
    return base;
  }

  String? get displayImage => image ?? masterProduct?.primaryImageUrl;

  String get categorySlug => secondaryCategory?.slug ?? masterProduct?.categorySlug ?? 'other';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'unit': unit,
      'Price': price,
      'Description': description,
      'category': secondaryCategoryId,
      'merchant': merchantId,
      'is_available': isAvailable,
    };
  }
}

class ProductCreateRequest {
  final String? masterProductId;
  final String? secondaryCategoryId;
  final double price;
  final int stockCount;
  final bool isAvailable;
  
  ProductCreateRequest({
    this.masterProductId,
    this.secondaryCategoryId,
    required this.price,
    required this.stockCount,
    this.isAvailable = true,
  });
  
  Map<String, dynamic> toJson() => {
    if (masterProductId != null) 'master_product_id': masterProductId,
    if (secondaryCategoryId != null) 'category': secondaryCategoryId,
    'Price': price,
    'stock_count': stockCount,
    'is_available': isAvailable,
  };
}

class ProductUpdateRequest {
  final double? price;
  final int? stockCount;
  final bool? isAvailable;
  final String? secondaryCategoryId;
  
  ProductUpdateRequest({
    this.price,
    this.stockCount,
    this.isAvailable,
    this.secondaryCategoryId,
  });
  
  Map<String, dynamic> toJson() => {
    if (price != null) 'Price': price,
    if (stockCount != null) 'stock_count': stockCount,
    if (isAvailable != null) 'is_available': isAvailable,
    if (secondaryCategoryId != null) 'category': secondaryCategoryId,
  };
}

class ProductResponse {
  final List<Product> products;
  final MasterProduct? heroProduct;
  final bool merchantsNearby;

  ProductResponse({
    required this.products,
    this.heroProduct,
    this.merchantsNearby = true,
  });
}
