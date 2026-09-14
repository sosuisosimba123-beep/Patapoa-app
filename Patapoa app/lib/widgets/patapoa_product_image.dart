import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/api_config.dart';

/// A reusable widget that displays product images with fallbacks.
class PatapoaProductImage extends StatelessWidget {
  /// Optional URL for the network product photo.
  final String? imageUrl;

  /// Required slug string to map to network icons.
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

  /// Maps the category slug to the corresponding image filename on the server.
  String _getImageName(String slug) {
    const String folder = 'secondary category';
    
    // Mapping based on the new architecture
    switch (slug) {
      case 'biscuits-cookies':
        return '$folder/biscuits & cookies.png';
      case 'chocolate-sweets':
        return '$folder/chocolate & sweets.png';
      case 'crisps-cereals':
        return '$folder/crisps & cereals.png';
      case 'cooking-oil-fats':
        return '$folder/cooking oil & fats.png';
      case 'detergent-soap':
        return '$folder/detergant & soap.png';
      case 'dishwashing-materials':
        return '$folder/dishwashing materials.png';
      case 'baby-care':
        return '$folder/baby care.png';
      case 'audio-devices':
        return '$folder/audio devices.png';
      case 'chargers-cables':
        return '$folder/chargers & cables.png';
      case 'batteries-lighting':
        return '$folder/batteries & lighting.png';
      default:
        return '$folder/bakery&breakfast.png'; // Generic fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageName = _getImageName(categorySlug);
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
        child: _buildImageContent(imageName),
      ),
    );
  }

  Widget _buildImageContent(String imageName) {
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
        errorWidget: (context, url, error) => _buildCategoryImage(imageName),
      );
    }

    return _buildCategoryImage(imageName);
  }

  Widget _buildCategoryImage(String imageName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.network(
        '${ApiConfig.imageBaseUrl}/$imageName',
        width: width,
        height: height,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // Final fallback to a local asset if even the network category image fails
          return Image.asset(
            'assets/images/patapoa logo.jpg', // Or some other generic fallback asset you have
            width: width,
            height: height,
            fit: BoxFit.contain,
            errorBuilder: (context, e, s) => const Icon(Icons.shopping_basket, color: Colors.grey),
          );
        },
      ),
    );
  }
}
