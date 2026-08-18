// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$PrimaryCategoryToJson(PrimaryCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'slug': instance.slug,
      'image_url': instance.imageUrl,
      'secondary_categories': instance.secondaryCategories,
    };

Map<String, dynamic> _$SecondaryCategoryToJson(SecondaryCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'primary_category_id': instance.primaryCategoryId,
      'name': instance.name,
      'slug': instance.slug,
      'image_url': instance.imageUrl,
      'primary_category': instance.primaryCategory,
    };

Map<String, dynamic> _$MasterProductToJson(MasterProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'brand': instance.brand,
      'description': instance.description,
      'primary_image_url': instance.primaryImageUrl,
      'backup_image_url': instance.backupImageUrl,
      'barcode': instance.barcode,
      'secondary_category_id': instance.secondaryCategoryId,
      'secondary_category': instance.secondaryCategory,
      'category_slug': instance.categorySlug,
    };

Map<String, dynamic> _$ProductToJson(Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'brand': instance.brand,
  'unit': instance.unit,
  'description': instance.description,
  'price': instance.price,
  'image': instance.image,
  'stock_quantity': instance.stockQuantity,
  'merchant_id': instance.merchantId,
  'secondary_category_id': instance.secondaryCategoryId,
  'secondary_category': instance.secondaryCategory,
  'master_product_id': instance.masterProductId,
  'master_product': instance.masterProduct,
  'is_available': instance.isAvailable,
  'distance': instance.distance,
  'merchant': instance.merchant,
  'is_custom': instance.isCustom,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'is_simulation': instance.isSimulation,
  'display_name': instance.displayName,
  'full_display_name': instance.fullDisplayName,
  'display_image': instance.displayImage,
  'category_slug': instance.categorySlug,
};
