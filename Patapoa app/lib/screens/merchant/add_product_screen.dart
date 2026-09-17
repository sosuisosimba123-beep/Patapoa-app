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
  late final TextEditingController _barcodeController;
  late final TextEditingController _unitController;
  
  String? _imageUrl;
  String _categorySlug = 'other';
  String? _masterProductId;
  bool _isLoading = false;

  List<PrimaryCategory> _primaryCategories = [];
  PrimaryCategory? _selectedPrimary;
  SecondaryCategory? _selectedSecondary;

  final List<String> _commonBrands = ['Kilombero', 'Azam', 'TPC', 'Kagera', 'Asas', 'Mo', 'Bakhresa', 'Generic', 'Local Farm'];
  final List<String> _commonUnits = ['1kg', '2kg', '5kg', '500ml', '1L', '1.5L', 'Pack', 'Piece', 'Bunch'];

  @override
  void initState() {
    super.initState();
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
      
      // Match the primary category from the loaded list to ensure dropdown works
      if (master.secondaryCategory?.primaryCategoryId != null) {
        try {
          _selectedPrimary = _primaryCategories.firstWhere(
            (c) => c.id == master.secondaryCategory!.primaryCategoryId
          );
          
          // Match the secondary category from the primary's list
          if (master.secondaryCategoryId != null) {
            _selectedSecondary = _selectedPrimary!.secondaryCategories?.firstWhere(
              (c) => c.id == master.secondaryCategoryId
            );
          }
        } catch (_) {
          // If not found in current list, fallback to the one from master
          _selectedSecondary = master.secondaryCategory;
          _selectedPrimary = master.secondaryCategory?.primaryCategory;
        }
      }
      
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
        _imageUrl = selected.src;
      });
    }
  }

  Future<void> _saveToInventory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSecondary == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a sub-category')));
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9.]'), ''));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price value')));
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
        'stock_count': 999, // Stock count removed from UI, defaulted to high value for MVP
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
        title: _buildImageSearchBar(),
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
                  Center(
                    child: GestureDetector(
                      onTap: _showPexelsPicker,
                      child: Column(
                        children: [
                          if (_imageUrl == null)
                            Container(
                              width: 160, height: 160,
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 2, style: BorderStyle.solid),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_rounded, size: 48, color: colorScheme.primary),
                                  const SizedBox(height: 8),
                                  Text('ADD PRODUCT IMAGE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: colorScheme.primary, letterSpacing: 1)),
                                ],
                              ),
                            )
                          else
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: PatapoaProductImage(
                                imageUrl: _imageUrl,
                                categorySlug: _categorySlug,
                                width: 160, height: 160,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text('Linked to Patapoa Library', style: textTheme.labelSmall?.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionLabel('BASIC INFORMATION'),
                  _buildTextField(_nameController, 'Product Name', Icons.shopping_bag_outlined),
                  _buildCustomizableField(controller: _brandController, label: 'Brand', icon: Icons.branding_watermark_outlined, suggestions: _commonBrands),
                  _buildCustomizableField(controller: _unitController, label: 'Unit / Size', icon: Icons.straighten_outlined, suggestions: _commonUnits),

                  const SizedBox(height: 16),
                  _buildSectionLabel('PRICING & DETAILS'),
                  _buildTextField(_priceController, 'Price (TZS)', Icons.payments_outlined, isNumber: true),
                  _buildTextField(_descController, 'Notes (Optional)', Icons.notes_rounded),
                  
                  const SizedBox(height: 16),
                  _buildSectionLabel('CATEGORY'),
                  _buildCategorySelection(),
                  
                  const SizedBox(height: 16),
                  _buildSectionLabel('INVENTORY SYNC'),
                  _buildTextField(_barcodeController, 'Barcode (Optional)', Icons.qr_code_2_rounded, 
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.camera_alt_outlined),
                      onPressed: () => context.push('/merchant/barcode-scan'),
                    )
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FilledButton(
                      onPressed: _saveToInventory,
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text('SAVE TO INVENTORY', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.grey, letterSpacing: 1.5)),
    );
  }

  Widget _buildImageSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        readOnly: true,
        onTap: _showPexelsPicker,
        decoration: const InputDecoration(
          hintText: 'Search Patapoa Library...',
          hintStyle: TextStyle(fontSize: 13),
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      children: [
        DropdownButtonFormField<PrimaryCategory>(
          value: _primaryCategories.contains(_selectedPrimary) ? _selectedPrimary : null,
          decoration: const InputDecoration(labelText: 'Main Category', prefixIcon: Icon(Icons.category_outlined)),
          items: _primaryCategories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() { 
            _selectedPrimary = v; 
            _selectedSecondary = null; 
            _categorySlug = 'other';
          }),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<SecondaryCategory>(
          value: (_selectedPrimary?.secondaryCategories?.contains(_selectedSecondary) ?? false) ? _selectedSecondary : null,
          decoration: const InputDecoration(labelText: 'Sub Category', prefixIcon: Icon(Icons.subdirectory_arrow_right_rounded)),
          items: (_selectedPrimary?.secondaryCategories ?? []).map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() { 
            _selectedSecondary = v; 
            _categorySlug = v?.slug ?? 'other';
          }),
        ),
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
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), suffixIcon: suffixIcon),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) {
          if (!label.contains('Optional') && (v == null || v.trim().isEmpty)) return 'Required';
          return null;
        },
      ),
    );
  }
}
