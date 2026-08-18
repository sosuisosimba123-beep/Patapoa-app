import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  bool _isLoading = false;

  List<CartItem> get items => _items;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _items.fold(
    0, 
    (sum, item) => sum + (item.product.price * item.quantity)
  );

  bool get isLoading => _isLoading;

  CartProvider() {
    _loadCart();
  }

  Future<void> _loadCart() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart');
      
      if (cartData != null) {
        final List<dynamic> decoded = jsonDecode(cartData);
        _items = decoded
          .where((json) => json != null && json['product'] != null)
          .map((json) => CartItem.fromJson(json))
          .toList();
      }
    } catch (e) {
      debugPrint("Error loading cart: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString('cart', cartData);
    } catch (e) {
      debugPrint("Error saving cart: $e");
    }
  }

  String? addItem(Product product, {int quantity = 1, bool force = false}) {
    // Check if adding from a different merchant
    if (_items.isNotEmpty && _items.first.product.merchantId != product.merchantId) {
      if (force) {
        _items.clear();
      } else {
        return "DIFFERENT_MERCHANT";
      }
    }

    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    
    _saveCart();
    notifyListeners();
    return null;
  }

  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    
    final existingIndex = _items.indexWhere((item) => item.product.id == productId);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  List<Map<String, dynamic>> getOrderItems() {
    return _items.map((item) {
      return {
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();
  }
}
