import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../services/api_service.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  final MobileScannerController _controller = MobileScannerController();

  Future<void> _handleBarcode(String barcode) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    _controller.stop(); // Stop camera while processing

    try {
      final response = await _apiService.post('/products/scan', {'barcode': barcode});
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body)['data'];
        if (mounted) {
          // Navigate to add product screen with pre-filled data
          context.pushReplacement('/merchant/add-product', extra: {
            'barcode': barcode,
            'master_product_id': data['master_product_id'],
            'name': data['name'],
            'brand': data['brand'],
            'secondary_category_id': data['secondary_category_id'],
            'image_url': data['image_url'],
          });
        }
      }
    } catch (e) {
      // Gracefully handle "Not Found" or any error as a prompt for manual addition
      if (mounted) {
        _showNotFoundDialog(barcode);
      }
    }
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Product Not Found'),
        content: Text('Barcode $barcode was not found in our database. Would you like to add it manually?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.start();
              setState(() => _isProcessing = false);
            }, 
            child: const Text('RESCAN')
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.pushReplacement('/merchant/add-product', extra: {'barcode': barcode});
            }, 
            child: const Text('ADD MANUALLY')
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Product Barcode'),
        actions: [
          IconButton(
            onPressed: () => _controller.toggleTorch(),
            icon: ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, child) {
                return Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _handleBarcode(barcodes.first.rawValue!);
              }
            },
          ),
          // Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Searching for product...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
