import 'package:json_annotation/json_annotation.dart';
import '../utils/number_utils.dart';

part 'product.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class PrimaryCategory {
  final int id;
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

  factory PrimaryCategory.fromJson(Map<String, dynamic> json) {
    return PrimaryCategory(
      id: NumberUtils.paramInt(json['id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String?,
      secondaryCategories: json['secondary_categories'] != null 
          ? (json['secondary_categories'] as List).map((i) => SecondaryCategory.fromJson(i as Map<String, dynamic>)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$PrimaryCategoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class SecondaryCategory {
  final int id;
  final int primaryCategoryId;
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

  factory SecondaryCategory.fromJson(Map<String, dynamic> json) {
    return SecondaryCategory(
      id: NumberUtils.paramInt(json['id']),
      primaryCategoryId: NumberUtils.paramInt(json['primary_category_id']),
      name: json['name'] as String,
      slug: json['slug'] as String,
      imageUrl: json['image_url'] as String?,
      primaryCategory: json['primary_category'] != null 
          ? PrimaryCategory.fromJson(json['primary_category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => _$SecondaryCategoryToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class MasterProduct {
  final int id;
  final String name;
  final String? brand;
  final String? description;
  final String? primaryImageUrl;
  final String? backupImageUrl;
  final String? barcode;
  final int? secondaryCategoryId;
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
      id: NumberUtils.paramInt(json['id']),
      name: json['name'] as String,
      brand: json['brand'] as String?,
      description: json['description'] as String?,
      primaryImageUrl: json['primary_image_url'] as String?,
      backupImageUrl: json['backup_image_url'] as String?,
      barcode: json['barcode'] as String?,
      secondaryCategoryId: NumberUtils.paramInt(json['secondary_category_id']),
      secondaryCategory: json['secondary_category'] != null 
          ? SecondaryCategory.fromJson(json['secondary_category'] as Map<String, dynamic>) 
          : null,
    );
  }
  
  Map<String, dynamic> toJson() => _$MasterProductToJson(this);

  String get categorySlug => secondaryCategory?.slug ?? 'other';
}

@JsonSerializable(fieldRename: FieldRename.snake, createFactory: false)
class Product {
  final int id;
  final String? name;
  final String? brand;
  final String? unit;
  final String? description;
  final double price;
  final String? image;
  final int? stockQuantity;
  final int? merchantId;
  final int? secondaryCategoryId;
  final SecondaryCategory? secondaryCategory;
  final int? masterProductId;
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
      id: NumberUtils.paramInt(json['id']),
      name: json['name'] as String?,
      brand: json['brand'] as String?,
      unit: json['unit'] as String?,
      description: json['description'] as String?,
      price: NumberUtils.toDouble(json['price']),
      image: json['image'] as String?,
      stockQuantity: NumberUtils.paramInt(json['stock_quantity'] ?? json['stock_count']),
      merchantId: NumberUtils.paramInt(json['merchant_id']),
      secondaryCategoryId: NumberUtils.paramInt(json['secondary_category_id']),
      secondaryCategory: json['secondary_category'] != null 
          ? SecondaryCategory.fromJson(json['secondary_category'] as Map<String, dynamic>) 
          : null,
      masterProductId: NumberUtils.paramInt(json['master_product_id']),
      masterProduct: json['master_product'] != null 
          ? MasterProduct.fromJson(json['master_product'] as Map<String, dynamic>) 
          : null,
      isAvailable: json['is_available'] as bool? ?? true,
      distance: NumberUtils.toDouble(json['distance']),
      merchant: json['merchant'] as Map<String, dynamic>?,
      isCustom: json['is_custom'] as bool? ?? false,
      createdAt: json['created_at'] == null ? null : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null ? null : DateTime.parse(json['updated_at'] as String),
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

  Map<String, dynamic> toJson() => _$ProductToJson(this);
}

class ProductCreateRequest {
  final int? masterProductId;
  final int? secondaryCategoryId;
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
    if (secondaryCategoryId != null) 'secondary_category_id': secondaryCategoryId,
    'price': price,
    'stock_count': stockCount,
    'is_available': isAvailable,
  };
}

class ProductUpdateRequest {
  final double? price;
  final int? stockCount;
  final bool? isAvailable;
  final int? secondaryCategoryId;
  
  ProductUpdateRequest({
    this.price,
    this.stockCount,
    this.isAvailable,
    this.secondaryCategoryId,
  });
  
  Map<String, dynamic> toJson() => {
    if (price != null) 'price': price,
    if (stockCount != null) 'stock_count': stockCount,
    if (isAvailable != null) 'is_available': isAvailable,
    if (secondaryCategoryId != null) 'secondary_category_id': secondaryCategoryId,
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
