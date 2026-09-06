import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/merchant_service.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import '../../models/pexels_image.dart';
import '../../widgets/patapoa_product_image.dart';
import '../../widgets/pexels_image_picker.dart';

class AddProductScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddProductScreen({super.key, this.initialData});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final MerchantService _merchantService = MerchantService();
  final ProductService _productService = ProductService();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _stockController = TextEditingController();
  late final TextEditingController _barcodeController;
  late final TextEditingController _unitController;
  
  String? _imageUrl;
  String _categorySlug = 'other';
  int? _masterProductId;
  bool _isLoading = false;

  List<PrimaryCategory> _primaryCategories = [];
  PrimaryCategory? _selectedPrimary;
  SecondaryCategory? _selectedSecondary;

  final List<String> _commonBrands = ['Kilombero', 'Azam', 'TPC', 'Kagera', 'Asas', 'Mo', 'Bakhresa', 'Generic', 'Local Farm'];
  final List<String> _commonUnits = ['1kg', '2kg', '5kg', '500ml', '1L', '1.5L', 'Pack', 'Piece', 'Bunch'];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with initial data if provided
    final data = widget.initialData;
    _nameController = TextEditingController(text: data?['name'] ?? '');
    _brandController = TextEditingController(text: data?['brand'] ?? '');
    _barcodeController = TextEditingController(text: data?['barcode'] ?? '');
    _unitController = TextEditingController(text: data?['unit'] ?? '');
    _imageUrl = data?['image_url'];
    _masterProductId = data?['master_product_id'];

    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _productService.getCategories();
      if (!mounted) return;
      setState(() => _primaryCategories = cats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _onMasterProductSelected(MasterProduct master) {
    setState(() {
      _masterProductId = master.id;
      _nameController.text = master.name;
      _brandController.text = master.brand ?? '';
      _imageUrl = master.primaryImageUrl;
      _barcodeController.text = master.barcode ?? '';
      _selectedSecondary = master.secondaryCategory;
      _selectedPrimary = master.secondaryCategory?.primaryCategory;
      _categorySlug = master.categorySlug;
    });
  }

  Future<void> _showPexelsPicker() async {
    final PexelsImage? selected = await showModalBottomSheet<PexelsImage>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => PexelsImagePicker(initialQuery: _nameController.text),
    );

    if (selected != null) {
      setState(() {
        _imageUrl = selected.src; // Use the Pexels URL directly
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pexels image URL linked to product!')));
      }
    }
  }

  Future<void> _saveToInventory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSecondary == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a sub-category')));
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    final stock = int.tryParse(_stockController.text.replaceAll(RegExp(r'[^0-9]'), ''));

    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price or stock values')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        'master_product_id': _masterProductId,
        'name': _nameController.text,
        'brand': _brandController.text,
        'unit': _unitController.text,
        'price': price,
        'description': _descController.text,
        'stock_count': stock,
        'barcode': _barcodeController.text,
        'secondary_category_id': _selectedSecondary!.id,
        'image_url': _imageUrl,
        'is_custom': _masterProductId == null,
      };

      await _merchantService.createManualProduct(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product added successfully!')));
        context.go('/merchant/inventory');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => context.push('/merchant/barcode-scan'),
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchAndFilter(colorScheme, textTheme),
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        PatapoaProductImage(
                          imageUrl: _imageUrl,
                          categorySlug: _categorySlug,
                          width: 120, height: 120,
                        ),
                        TextButton.icon(
                          onPressed: _showPexelsPicker,
                          icon: const Icon(Icons.image_search),
                          label: const Text('Search High-Quality Image'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(_nameController, 'Product Name', Icons.shopping_bag_outlined),
                  _buildCustomizableField(controller: _brandController, label: 'Brand', icon: Icons.branding_watermark_outlined, suggestions: _commonBrands),
                  _buildCustomizableField(controller: _unitController, label: 'Unit / Size', icon: Icons.straighten_outlined, suggestions: _commonUnits),

                  _buildTextField(_priceController, 'Price (TZS)', Icons.money, isNumber: true),
                  _buildTextField(_descController, 'Notes (Optional)', Icons.description_outlined),
                  _buildTextField(_stockController, 'Stock Count', Icons.inventory_2_outlined, isNumber: true),
                  
                  _buildCategorySelection(),
                  
                  _buildTextField(_barcodeController, 'Barcode (Optional)', Icons.qr_code, 
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () => context.push('/merchant/barcode-scan'),
                    )
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed: _saveToInventory,
                      child: const Text('Save to Inventory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        DropdownButtonFormField<PrimaryCategory>(
          value: _selectedPrimary,
          decoration: const InputDecoration(labelText: 'Main Category', prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
          items: _primaryCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() { 
            _selectedPrimary = v; 
            _selectedSecondary = null; 
            _categorySlug = 'other';
          }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<SecondaryCategory>(
          value: _selectedSecondary,
          decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right), border: OutlineInputBorder()),
          items: (_selectedPrimary?.secondaryCategories ?? []).map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() { 
            _selectedSecondary = v; 
            _categorySlug = v?.slug ?? 'other';
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCustomizableField({required TextEditingController controller, required String label, required IconData icon, required List<String> suggestions}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
          suffixIcon: PopupMenuButton<String>(
            icon: const Icon(Icons.arrow_drop_down),
            onSelected: (String v) => controller.text = v,
            itemBuilder: (ctx) => suggestions.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
          ),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffixIcon, border: const OutlineInputBorder()),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) {
          if (!label.contains('Optional') && (v == null || v.trim().isEmpty)) {
            return 'Required';
          }
          if (v != null && RegExp(r'[<>{}\[\]\\]').hasMatch(v)) {
            return 'Invalid characters detected';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSearchAndFilter(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<MasterProduct>(
          displayStringForOption: (option) => option.name,
          optionsBuilder: (textEditingValue) async {
            if (textEditingValue.text.isEmpty) return const Iterable<MasterProduct>.empty();
            return await _productService.getMasterProducts(search: textEditingValue.text);
          },
          onSelected: _onMasterProductSelected,
          fieldViewBuilder: (ctx, ctrl, node, onSubmit) => TextField(
            controller: ctrl, focusNode: node,
            decoration: InputDecoration(
              hintText: 'Search catalog templates...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(icon: const Icon(Icons.qr_code_scanner, color: Colors.blue), onPressed: () => context.push('/merchant/barcode-scan')),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
