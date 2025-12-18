import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'external_image_upload_service.dart';
import '../config/external_image_storage_config.dart';

/// Cloudinary image storage yönetimi için servis
/// Firebase Storage kullanılmaz, sadece Cloudinary kullanılır
class StorageService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _safeId(String value) => value.replaceAll(RegExp(r'[^\w\-]'), '_');

  String _guessExtension(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return '.jpg';
    return '.jpg';
  }

  String _reviewFolder(String userId, String reviewId) {
    final cleanUser = _safeId(userId);
    final cleanReview = _safeId(reviewId);
    return '${ExternalImageStorageConfig.cloudinaryReviewFolder}/$cleanUser/$cleanReview';
  }

  void _validateCloudinaryConfig() {
    if (!ExternalImageStorageConfig.enabled) {
      throw Exception('Cloudinary yükleme özelliği devre dışı. `ExternalImageStorageConfig.enabled = true` yapın.');
    }
    if (ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
        ExternalImageStorageConfig.cloudinaryCloudName.isEmpty) {
      throw Exception('Cloudinary cloud name ayarlı değil. `ExternalImageStorageConfig.cloudinaryCloudName` doldurun.');
    }
    if (ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset == 'YOUR_UPLOAD_PRESET' ||
        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
      throw Exception('Cloudinary upload preset ayarlı değil. `ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset` doldurun.');
    }
  }

  /// Fotoğrafı yükle (bytes'tan - web için)
  Future<String> uploadReviewImageBytes(
    List<int> imageBytes,
    String reviewId, {
    int? index,
    String? fileName,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      _validateCloudinaryConfig();

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = imageBytes.length;
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Fotoğraf çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      final bytes = Uint8List.fromList(imageBytes);
      final ext = _guessExtension(fileName);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final uploadName = 'review_${_safeId(reviewId)}_$ts${index != null ? '_$index' : ''}$ext';
      final external = ExternalImageUploadService();
      return await external.uploadImageBytes(
        bytes: bytes,
        fileName: uploadName,
        folder: _reviewFolder(user.uid, reviewId),
      );
    } catch (e, stackTrace) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fotoğrafı yükle (File ile)
  Future<String> uploadReviewImage(File imageFile, String reviewId, {int? index}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Dosya varlığını kontrol et
      if (!await imageFile.exists()) {
        throw Exception('Fotoğraf dosyası bulunamadı');
      }

      _validateCloudinaryConfig();

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Fotoğraf çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      final bytes = await imageFile.readAsBytes();
      final ext = _guessExtension(imageFile.path.split('/').last);
      final ts = DateTime.now().millisecondsSinceEpoch;
      final uploadName = 'review_${_safeId(reviewId)}_$ts${index != null ? '_$index' : ''}$ext';
      final external = ExternalImageUploadService();
      return await external.uploadImageBytes(
        bytes: bytes,
        fileName: uploadName,
        folder: _reviewFolder(user.uid, reviewId),
      );
    } catch (e, stackTrace) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Birden fazla fotoğrafı yükle (XFile veya File kabul eder)
  Future<List<String>> uploadReviewImages(
    List<dynamic> imageFiles, // XFile veya File
    String reviewId,
  ) async {
    try {
      if (imageFiles.isEmpty) {
        debugPrint('Yüklenecek fotoğraf yok');
        return [];
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME BAŞLIYOR ===');
      debugPrint('Fotoğraf sayısı: ${imageFiles.length}');
      debugPrint('Review ID: $reviewId');

      _validateCloudinaryConfig();

      final urls = <String>[];
      int successCount = 0;
      int failCount = 0;
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          debugPrint('Fotoğraf ${i + 1}/${imageFiles.length} yükleniyor...');
          
          // XFile veya File'ı işle
          dynamic imageFile = imageFiles[i];
          Uint8List bytes;
          
          if (imageFile is XFile) {
            bytes = await imageFile.readAsBytes();
          } else if (imageFile is File) {
            if (!await imageFile.exists()) {
              debugPrint('✗ Fotoğraf ${i + 1} dosyası bulunamadı: ${imageFile.path}');
              failCount++;
              continue;
            }
            bytes = await imageFile.readAsBytes();
          } else {
            debugPrint('✗ Fotoğraf ${i + 1} geçersiz tip: ${imageFile.runtimeType}');
            failCount++;
            continue;
          }
          
          final url = await uploadReviewImageBytes(bytes, reviewId, index: i);
          urls.add(url);
          successCount++;
          debugPrint('✓ Fotoğraf ${i + 1} başarıyla yüklendi: $url');
        } catch (e, stackTrace) {
          debugPrint('✗ Fotoğraf ${i + 1} yüklenemedi: $e');
          debugPrint('Stack trace: $stackTrace');
          failCount++;
        }
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME SONUÇLARI ===');
      debugPrint('Başarılı: $successCount/${imageFiles.length}');
      debugPrint('Başarısız: $failCount/${imageFiles.length}');
      
      if (urls.isEmpty && imageFiles.isNotEmpty) {
        throw Exception('Tüm fotoğraflar yüklenemedi. Lütfen tekrar deneyin.');
      }
      
      if (failCount > 0 && urls.isNotEmpty) {
        debugPrint('⚠ UYARI: $failCount fotoğraf yüklenemedi ama $successCount fotoğraf başarıyla yüklendi');
      }

      return urls;
    } catch (e, stackTrace) {
      debugPrint('✗ Toplu fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fotoğrafı sil (Cloudinary'de silme işlemi client-side'dan yapılamaz)
  Future<void> deleteImage(String imageUrl) async {
    try {
      debugPrint('Cloudinary image delete: Client-side silme desteklenmiyor. URL: $imageUrl');
      // Cloudinary unsigned upload preset ile client-side'dan silme yapılamaz
      // Bu işlem backend'de yapılmalı
    } catch (e) {
      debugPrint('Error deleting image: $e');
    }
  }

  /// Birden fazla fotoğrafı sil
  Future<void> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
    } catch (e) {
      debugPrint('Error deleting images: $e');
    }
  }

  /// Ürün resmini Cloudinary'ye yükle (Byte data ile)
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      _validateCloudinaryConfig();

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = imageBytes.length;
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Resim çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      final external = ExternalImageUploadService();
      return await external.uploadImageBytes(
        bytes: imageBytes,
        fileName: fileName,
        folder: ExternalImageStorageConfig.cloudinaryProductFolder,
      );
    } catch (e, stackTrace) {
      debugPrint('✗ Ürün resmi yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Ürün resmini Cloudinary'ye yükle (File ile)
  Future<String> uploadProductImageFile(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Dosya varlığını kontrol et
      if (!await imageFile.exists()) {
        throw Exception('Resim dosyası bulunamadı');
      }

      _validateCloudinaryConfig();

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Resim çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      final bytes = await imageFile.readAsBytes();
      final fileName = imageFile.path.split('/').last;
      final external = ExternalImageUploadService();
      return await external.uploadImageBytes(
        bytes: bytes,
        fileName: fileName,
        folder: ExternalImageStorageConfig.cloudinaryProductFolder,
      );
    } catch (e, stackTrace) {
      debugPrint('✗ Ürün resmi yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
