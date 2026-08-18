import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../models/product.dart';
import '../../widgets/patapoa_product_image.dart';

class MerchantEditProductScreen extends StatefulWidget {
  const MerchantEditProductScreen({super.key, required this.product});
  final Product product;

  @override
  State<MerchantEditProductScreen> createState() => _MerchantEditProductScreenState();
}

class _MerchantEditProductScreenState extends State<MerchantEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MerchantService _merchantService = MerchantService();
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: widget.product.price.toString());
    _stockController = TextEditingController(text: (widget.product.stockQuantity ?? 0).toString());
    _isAvailable = widget.product.isAvailable;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Sanitize and Parse
    String priceStr = _priceController.text.trim().replaceAll(RegExp(r'[,\s]'), '');
    String stockStr = _stockController.text.trim().replaceAll(RegExp(r'[,\s]'), '');
    
    // Handle local format
    if (priceStr.contains('.')) {
      int lastDotIndex = priceStr.lastIndexOf('.');
      if (priceStr.length - lastDotIndex == 4) priceStr = priceStr.replaceAll('.', '');
    }

    final price = double.tryParse(priceStr);
    final stock = int.tryParse(stockStr);

    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid numeric values')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = ProductUpdateRequest(
        price: price,
        stockCount: stock,
        isAvailable: _isAvailable,
      );
      await _merchantService.updateProduct(widget.product.id, request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product updated successfully')));
        context.go('/merchant/inventory');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Listing'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back))
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductHeader(colorScheme, textTheme),
              const SizedBox(height: 32),

              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (TZS)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v?.isEmpty ?? true ? 'Required' : null
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Product is Available'),
                subtitle: const Text('Toggle off to hide from customers'),
                value: _isAvailable,
                onChanged: (v) => setState(() => _isAvailable = v),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _updateProduct,
                  icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Saving Changes...' : 'Save Updates'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(ColorScheme colorScheme, TextTheme textTheme) {
    return Row(
      children: [
        PatapoaProductImage(
          imageUrl: widget.product.displayImage,
          categorySlug: widget.product.categorySlug,
          width: 100, height: 100,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.product.displayName, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              Text(widget.product.masterProduct?.brand ?? 'Local Brand', style: TextStyle(color: colorScheme.primary)),
              const SizedBox(height: 4),
              const Text('Standard catalog item. Name and image cannot be edited.', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }
}
