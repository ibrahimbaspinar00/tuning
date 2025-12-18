import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

import '../config/external_image_storage_config.dart';

/// Upload images to an external (non-Firebase) provider and return a public URL.
///
/// Current implementation: Cloudinary unsigned upload preset.
class ExternalImageUploadService {
  const ExternalImageUploadService();

  bool get isEnabled => ExternalImageStorageConfig.enabled;

  Uri _cloudinaryUploadUri() {
    final cloudName = ExternalImageStorageConfig.cloudinaryCloudName.trim();
    return Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
  }

  void _validateConfig() {
    final cloudName = ExternalImageStorageConfig.cloudinaryCloudName.trim();
    final preset = ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.trim();

    if (cloudName.isEmpty || cloudName == 'YOUR_CLOUD_NAME') {
      throw Exception('Cloudinary cloud name ayarlı değil. `ExternalImageStorageConfig.cloudinaryCloudName` doldurun.');
    }
    if (preset.isEmpty || preset == 'YOUR_UPLOAD_PRESET') {
      throw Exception(
        'Cloudinary upload preset ayarlı değil. `ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset` doldurun.',
      );
    }
  }

  /// Upload raw bytes to Cloudinary and return the `secure_url`.
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? folder,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (!isEnabled) {
      throw Exception('External image upload kapalı (ExternalImageStorageConfig.enabled=false).');
    }
    _validateConfig();

    final preset = ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.trim();
    final targetFolder = (folder ?? ExternalImageStorageConfig.cloudinaryProductFolder).trim();

    if (bytes.isEmpty) {
      throw Exception('Boş dosya (0 byte) yüklenemez.');
    }

    debugPrint('☁️ Cloudinary upload: fileName=$fileName bytes=${bytes.length} folder=$targetFolder');

    final request = http.MultipartRequest('POST', _cloudinaryUploadUri())
      ..fields['upload_preset'] = preset
      ..fields['folder'] = targetFolder;

    // Cloudinary is fine without an explicit contentType here.
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
      ),
    );

    final streamed = await request.send().timeout(timeout);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('❌ Cloudinary upload failed: ${response.statusCode} ${response.body}');
      try {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final error = (json['error'] as Map?)?['message']?.toString();
        throw Exception(error ?? 'Cloudinary upload hatası (HTTP ${response.statusCode}).');
      } catch (_) {
        throw Exception('Cloudinary upload hatası (HTTP ${response.statusCode}).');
      }
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = json['secure_url']?.toString().trim();
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary response içinde `secure_url` bulunamadı.');
    }

    return secureUrl;
  }
}


