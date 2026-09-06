import 'package:flutter/material.dart';
import '../services/pexels_service.dart';
import '../models/pexels_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PexelsImagePicker extends StatefulWidget {
  final String initialQuery;
  const PexelsImagePicker({super.key, this.initialQuery = ''});

  @override
  State<PexelsImagePicker> createState() => _PexelsImagePickerState();
}

class _PexelsImagePickerState extends State<PexelsImagePicker> {
  final PexelsService _pexelsService = PexelsService();
  final TextEditingController _searchController = TextEditingController();
  List<PexelsImage> _images = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _performSearch();
    } else {
      _loadCurated();
    }
  }

  Future<void> _loadCurated() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final images = await _pexelsService.getCuratedImages();
      setState(() => _images = images);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final images = await _pexelsService.searchImages(_searchController.text);
      setState(() => _images = images);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Pexels Library', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search high-quality photos...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_forward),
                onPressed: _performSearch,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (_) => _performSearch(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final image = _images[index];
                          return GestureDetector(
                            onTap: () => Navigator.pop(context, image),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: image.src,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(color: Colors.grey[200]),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
