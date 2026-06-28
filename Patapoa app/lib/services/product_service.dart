import 'dart:convert';
import '../config/api_config.dart';
import '../models/product.dart';
import 'api_service.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  Future<List<Product>> getProducts({
    int? categoryId,
    int? merchantId,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = ApiConfig.products;
      final params = <String>[];
      
      if (categoryId != null) params.add('category_id=$categoryId');
      if (merchantId != null) params.add('merchant_id=$merchantId');
      if (search != null) params.add('q=${Uri.encodeComponent(search)}');
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> productsData = decoded is List ? decoded : (decoded['data'] ?? []);
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> getProduct(int id, {List<String>? fields}) async {
    try {
      String url = ApiConfig.product(id);
      if (fields != null && fields.isNotEmpty) {
        url += '?fields=${fields.join(',')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error fetching product: $e');
    }
  }

  Future<List<Product>> getMerchantProducts({int page = 1, int limit = 20}) async {
    try {
      String url = ApiConfig.merchantProducts;
      final params = <String>[];
      params.add('page=$page');
      params.add('limit=$limit');
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await _apiService.get(url);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> productsData = decoded is List ? decoded : (decoded['data'] ?? []);
        return productsData.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load merchant products');
      }
    } catch (e) {
      throw Exception('Error fetching merchant products: $e');
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    return getProducts(search: query);
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await _apiService.get(ApiConfig.categories);
      
      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        final List<dynamic> categoriesData = decoded is List ? decoded : (decoded['data'] ?? []);
        return categoriesData.map((json) => Category.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<Product> createProduct(ProductCreateRequest request) async {
    try {
      final response = await _apiService.post(ApiConfig.merchantProducts, request.toJson());
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to create product');
      }
    } catch (e) {
      throw Exception('Error creating product: $e');
    }
  }

  Future<Product> updateProduct(int id, ProductUpdateRequest request) async {
    try {
      final response = await _apiService.put(ApiConfig.merchantProduct(id), request.toJson());
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data['data'] ?? data);
      } else {
        throw Exception('Failed to update product');
      }
    } catch (e) {
      throw Exception('Error updating product: $e');
    }
  }

  Future<void> deleteProduct(int id) async {
    try {
      final response = await _apiService.delete(ApiConfig.merchantProduct(id));
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete product');
      }
    } catch (e) {
      throw Exception('Error deleting product: $e');
    }
  }
}
