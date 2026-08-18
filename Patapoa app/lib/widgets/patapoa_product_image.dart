import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// A reusable widget that displays product images with fallbacks.
class PatapoaProductImage extends StatelessWidget {
  /// Optional URL for the network product photo.
  final String? imageUrl;

  /// Required slug string to map to local icons.
  final String categorySlug;

  /// Width of the image container. Defaults to 60.0.
  final double? width;

  /// Height of the image container. Defaults to 60.0.
  final double? height;

  /// Border radius of the image container. Defaults to 12.0.
  final BorderRadius? borderRadius;

  /// BoxFit for the network image. Defaults to BoxFit.cover.
  final BoxFit fit;

  const PatapoaProductImage({
    super.key,
    this.imageUrl,
    required this.categorySlug,
    this.width = 60.0,
    this.height = 60.0,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  /// Maps the category slug to the corresponding local asset path.
  String _getAssetPath(String slug) {
    const String basePath = 'assets/images/3d_categories/';
    
    // Mapping based on the new architecture
    switch (slug) {
      case 'biscuits-cookies':
        return '${basePath}biscuits & cookies.png';
      case 'chocolate-sweets':
        return '${basePath}chocolate & sweets.png';
      case 'crisps-cereals':
        return '${basePath}crisps & cereals.png';
      case 'cooking-oil-fats':
        return '${basePath}cooking oil & fats.png';
      case 'detergent-soap':
        return '${basePath}detergant & soap.png';
      case 'dishwashing-materials':
        return '${basePath}dishwashing materials.png';
      case 'baby-care':
        return '${basePath}baby care.png';
      case 'audio-devices':
        return '${basePath}audio devices.png';
      case 'chargers-cables':
        return '${basePath}chargers & cables.png';
      case 'batteries-lighting':
        return '${basePath}batteries & lighting.png';
      default:
        return '${basePath}bakery&breakfast.png'; // Generic fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetPath = _getAssetPath(categorySlug);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: effectiveBorderRadius,
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: _buildImageContent(assetPath),
      ),
    );
  }

  Widget _buildImageContent(String assetPath) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => _buildAssetImage(assetPath),
      );
    }

    return _buildAssetImage(assetPath);
  }

  Widget _buildAssetImage(String assetPath) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.shopping_basket, color: Colors.grey);
        },
      ),
    );
  }
}
