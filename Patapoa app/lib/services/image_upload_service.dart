import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'api_service.dart';

class ImageUploadService {
  final ApiService _apiService = ApiService();

  Future<String> uploadImage(File imageFile, {String folder = 'products'}) async {
    try {
      final fileName = imageFile.path.split('/').last;
      final bytes = await imageFile.readAsBytes();
      
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: fileName,
      );

      final response = await _apiService.multipartPost(
        ApiConfig.uploadImage,
        {'folder': folder},
        files: [multipartFile],
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final url = data['url'] ?? data['data']?['url'];
        if (url != null) {
          return url.toString();
        }
        throw Exception('Image upload response did not contain URL');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> imageFiles, {String folder = 'products'}) async {
    final urls = <String>[];
    for (final file in imageFiles) {
      final url = await uploadImage(file, folder: folder);
      urls.add(url);
    }
    return urls;
  }
}
