import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:image_picker/image_picker.dart';

/// Firebase Storage yönetimi için servis
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fotoğrafı Firebase Storage'a yükle (bytes'tan - web için)
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

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = imageBytes.length;
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Fotoğraf çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // Dosya uzantısını belirle
      String contentType = 'image/jpeg';
      String fileExtension = '.jpg';
      if (fileName != null) {
        final lowerName = fileName.toLowerCase();
        if (lowerName.contains('.png')) {
          contentType = 'image/png';
          fileExtension = '.png';
        } else if (lowerName.contains('.jpg') || lowerName.contains('.jpeg')) {
          contentType = 'image/jpeg';
          fileExtension = '.jpg';
        } else if (lowerName.contains('.webp')) {
          contentType = 'image/webp';
          fileExtension = '.webp';
        } else if (lowerName.contains('.gif')) {
          contentType = 'image/gif';
          fileExtension = '.gif';
        }
      }

      // Dosya adı oluştur
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = index != null ? '${timestamp}_$index$fileExtension' : '$timestamp$fileExtension';
      final cleanReviewId = reviewId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final path = 'reviews/${user.uid}/$cleanReviewId/$finalFileName';
      final cleanPath = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');

      // Fotoğrafı yükle
      final ref = _storage.ref().child(cleanPath);
      final uploadTask = ref.putData(
        Uint8List.fromList(imageBytes),
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFileName': fileName ?? 'image',
          },
        ),
      );

      await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Fotoğraf yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );

      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Fotoğraf URL alınamadı. Lütfen tekrar deneyin.');
        },
      );

      if (downloadUrl.isEmpty) {
        throw Exception('Geçersiz fotoğraf URL\'si alındı');
      }

      return downloadUrl;
    } catch (e, stackTrace) {
      debugPrint('✗ Fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fotoğrafı Firebase Storage'a yükle
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

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Fotoğraf çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // Dosya uzantısını kontrol et
      final fileName = imageFile.path.split('/').last.toLowerCase();
      String contentType = 'image/jpeg'; // Varsayılan
      String fileExtension = '.jpg';
      
      // Dosya uzantısını belirle (daha güvenli)
      if (fileName.contains('.png')) {
        contentType = 'image/png';
        fileExtension = '.png';
      } else if (fileName.contains('.jpg') || fileName.contains('.jpeg')) {
        contentType = 'image/jpeg';
        fileExtension = '.jpg';
      } else if (fileName.contains('.webp')) {
        contentType = 'image/webp';
        fileExtension = '.webp';
      } else if (fileName.contains('.gif')) {
        contentType = 'image/gif';
        fileExtension = '.gif';
      }
      
      debugPrint('Dosya uzantısı tespit edildi: $fileExtension, Content Type: $contentType');

      // Dosya adı oluştur: reviews/{userId}/{reviewId}/{timestamp}_{index}.{ext}
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final finalFileName = index != null ? '${timestamp}_$index$fileExtension' : '$timestamp$fileExtension';
      
      // ReviewId'yi temizle (özel karakterleri kaldır)
      final cleanReviewId = reviewId.replaceAll(RegExp(r'[^\w\-]'), '_');
      
      final path = 'reviews/${user.uid}/$cleanReviewId/$finalFileName';
      
      // Path'teki özel karakterleri temizle (sadece güvenli karakterler kalmalı)
      final cleanPath = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');
      
      debugPrint('Review ID temizleme: $reviewId -> $cleanReviewId');

      debugPrint('=== FOTOĞRAF YÜKLEME BAŞLIYOR ===');
      debugPrint('Dosya: ${imageFile.path}');
      debugPrint('Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      debugPrint('Orijinal Path: $path');
      debugPrint('Temizlenmiş Path: $cleanPath');
      debugPrint('Content Type: $contentType');

      // Fotoğrafı yükle (temizlenmiş path ile)
      final ref = _storage.ref().child(cleanPath);
      
      debugPrint('Firebase Storage referansı oluşturuldu: $cleanPath');
      
      // Upload task'ı başlat
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFileName': fileName,
          },
        ),
      );

      // Upload progress'i bekle (timeout ile)
      debugPrint('Upload task başlatıldı, bekleniyor...');
      try {
        // Timeout: 60 saniye
        await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('✗ Upload timeout (60 saniye)');
            throw Exception('Fotoğraf yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Upload task tamamlandı');
      } catch (e) {
        debugPrint('✗ Upload task hatası: $e');
        rethrow;
      }

      // Download URL'yi al (timeout ile)
      debugPrint('Download URL alınıyor...');
      try {
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('✗ Download URL timeout (30 saniye)');
            throw Exception('Fotoğraf URL alınamadı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Download URL alındı: $downloadUrl');
        
        // URL'nin geçerli olduğunu kontrol et
        if (downloadUrl.isEmpty) {
          throw Exception('Geçersiz fotoğraf URL\'si alındı');
        }
        
        return downloadUrl;
      } catch (e) {
        debugPrint('✗ Download URL alma hatası: $e');
        rethrow;
      }
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

      final urls = <String>[];
      int successCount = 0;
      int failCount = 0;
      
      for (int i = 0; i < imageFiles.length; i++) {
        try {
          debugPrint('Fotoğraf ${i + 1}/${imageFiles.length} yükleniyor...');
          
          // XFile veya File'ı işle
          dynamic imageFile = imageFiles[i];
          File? file;
          
          if (imageFile is XFile) {
            // XFile'dan File'a çevir (web'de çalışmaz, ama mobil için)
            if (!kIsWeb) {
              file = File(imageFile.path);
              // Dosya varlığını kontrol et
              if (!await file.exists()) {
                debugPrint('✗ Fotoğraf ${i + 1} dosyası bulunamadı: ${imageFile.path}');
                failCount++;
                continue;
              }
            } else {
              // Web'de XFile'dan bytes oku ve upload et
              final bytes = await imageFile.readAsBytes();
              final url = await uploadReviewImageBytes(bytes, reviewId, index: i, fileName: imageFile.name);
              urls.add(url);
              successCount++;
              debugPrint('✓ Fotoğraf ${i + 1} başarıyla yüklendi: $url');
              continue;
            }
          } else if (imageFile is File) {
            file = imageFile;
            // Dosya varlığını kontrol et
            if (!await file.exists()) {
              debugPrint('✗ Fotoğraf ${i + 1} dosyası bulunamadı: ${file.path}');
              failCount++;
              continue;
            }
          } else {
            debugPrint('✗ Fotoğraf ${i + 1} geçersiz tip: ${imageFile.runtimeType}');
            failCount++;
            continue;
          }
          
          // At this point, file is guaranteed to be non-null
          // (either assigned from XFile on non-web, or from File)
          final url = await uploadReviewImage(file, reviewId, index: i);
          urls.add(url);
          successCount++;
          debugPrint('✓ Fotoğraf ${i + 1} başarıyla yüklendi: $url');
        } catch (e, stackTrace) {
          debugPrint('✗ Fotoğraf ${i + 1} yüklenemedi: $e');
          debugPrint('Stack trace: $stackTrace');
          failCount++;
          // Bir fotoğraf yüklenemezse diğerlerini denemeye devam et
          // Tüm fotoğraflar başarısız olursa hata fırlat
        }
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME SONUÇLARI ===');
      debugPrint('Başarılı: $successCount/${imageFiles.length}');
      debugPrint('Başarısız: $failCount/${imageFiles.length}');
      
      // Eğer hiç fotoğraf yüklenemediyse hata fırlat
      if (urls.isEmpty && imageFiles.isNotEmpty) {
        throw Exception('Tüm fotoğraflar yüklenemedi. Lütfen tekrar deneyin.');
      }
      
      // Eğer bazı fotoğraflar yüklenemediyse uyarı ver ama devam et
      if (failCount > 0 && urls.isNotEmpty) {
        debugPrint('⚠ UYARI: $failCount fotoğraf yüklenemedi ama $successCount fotoğraf başarıyla yüklendi');
      }

      debugPrint('=== TOPLU FOTOĞRAF YÜKLEME TAMAMLANDI ===');
      debugPrint('Başarıyla yüklenen: ${urls.length}/${imageFiles.length}');
      
      return urls;
    } catch (e, stackTrace) {
      debugPrint('✗ Toplu fotoğraf yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fotoğrafı sil
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Hata durumunda sessizce devam et
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

  /// Ürün resmini Firebase Storage'a yükle (Byte data ile)
  Future<String> uploadProductImage(Uint8List imageBytes, String fileName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = imageBytes.length;
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Resim çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // Dosya uzantısını kontrol et
      final fileNameLower = fileName.toLowerCase();
      String contentType = 'image/jpeg'; // Varsayılan
      String fileExtension = '.jpg';
      
      // Dosya uzantısını belirle
      if (fileNameLower.endsWith('.png')) {
        contentType = 'image/png';
        fileExtension = '.png';
      } else if (fileNameLower.endsWith('.jpg') || fileNameLower.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
        fileExtension = '.jpg';
      } else if (fileNameLower.endsWith('.webp')) {
        contentType = 'image/webp';
        fileExtension = '.webp';
      } else if (fileNameLower.endsWith('.gif')) {
        contentType = 'image/gif';
        fileExtension = '.gif';
      }

      debugPrint('=== ÜRÜN RESMİ YÜKLEME BAŞLIYOR ===');
      debugPrint('Dosya adı: $fileName');
      debugPrint('Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      debugPrint('Content Type: $contentType');

      // Dosya adını temizle ve benzersiz yap
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final finalFileName = cleanFileName.endsWith(fileExtension) 
          ? '${timestamp}_$cleanFileName'
          : '${timestamp}_$cleanFileName$fileExtension';
      
      final path = 'product_images/$finalFileName';
      
      // Path'teki özel karakterleri temizle
      final cleanPath = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');

      debugPrint('Orijinal Path: $path');
      debugPrint('Temizlenmiş Path: $cleanPath');

      // Firebase Storage referansı oluştur
      final ref = _storage.ref().child(cleanPath);
      
      debugPrint('Firebase Storage referansı oluşturuldu: $cleanPath');

      // Upload task'ı başlat (putData kullan)
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFileName': fileName,
          },
        ),
      );

      // Upload progress'i bekle (timeout ile)
      debugPrint('Upload task başlatıldı, bekleniyor...');
      try {
        // Timeout: 60 saniye
        await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('✗ Upload timeout (60 saniye)');
            throw Exception('Resim yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Upload task tamamlandı');
      } catch (e) {
        debugPrint('✗ Upload task hatası: $e');
        rethrow;
      }

      // Download URL'yi al (timeout ile)
      debugPrint('Download URL alınıyor...');
      try {
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('✗ Download URL timeout (30 saniye)');
            throw Exception('Resim URL alınamadı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Download URL alındı: $downloadUrl');
        
        // URL'nin geçerli olduğunu kontrol et
        if (downloadUrl.isEmpty) {
          throw Exception('Geçersiz resim URL\'si alındı');
        }
        
        return downloadUrl;
      } catch (e) {
        debugPrint('✗ Download URL alma hatası: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Ürün resmi yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Ürün resmini Firebase Storage'a yükle (File ile)
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

      // Dosya boyutunu kontrol et (max 10MB)
      final fileSize = await imageFile.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        throw Exception('Resim çok büyük (Maksimum 10MB). Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      }

      // Dosya uzantısını kontrol et
      final fileName = imageFile.path.split('/').last.toLowerCase();
      String contentType = 'image/jpeg'; // Varsayılan
      String fileExtension = '.jpg';
      
      // Dosya uzantısını belirle
      if (fileName.endsWith('.png')) {
        contentType = 'image/png';
        fileExtension = '.png';
      } else if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) {
        contentType = 'image/jpeg';
        fileExtension = '.jpg';
      } else if (fileName.endsWith('.webp')) {
        contentType = 'image/webp';
        fileExtension = '.webp';
      } else if (fileName.endsWith('.gif')) {
        contentType = 'image/gif';
        fileExtension = '.gif';
      }

      debugPrint('=== ÜRÜN RESMİ YÜKLEME BAŞLIYOR ===');
      debugPrint('Dosya: ${imageFile.path}');
      debugPrint('Boyut: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB');
      debugPrint('Content Type: $contentType');

      // Dosya adını temizle ve benzersiz yap
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanFileName = fileName.replaceAll(RegExp(r'[^\w\-.]'), '_');
      final finalFileName = cleanFileName.endsWith(fileExtension) 
          ? '${timestamp}_$cleanFileName'
          : '${timestamp}_$cleanFileName$fileExtension';
      
      final path = 'product_images/$finalFileName';
      
      // Path'teki özel karakterleri temizle
      final cleanPath = path.replaceAll(RegExp(r'[^\w\-/.]'), '_');

      debugPrint('Temizlenmiş Path: $cleanPath');

      // Firebase Storage referansı oluştur
      final ref = _storage.ref().child(cleanPath);
      
      debugPrint('Firebase Storage referansı oluşturuldu: $cleanPath');

      // Upload task'ı başlat
      final uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'originalFileName': fileName,
          },
        ),
      );

      // Upload progress'i bekle (timeout ile)
      debugPrint('Upload task başlatıldı, bekleniyor...');
      try {
        // Timeout: 60 saniye
        await uploadTask.timeout(
          const Duration(seconds: 60),
          onTimeout: () {
            debugPrint('✗ Upload timeout (60 saniye)');
            throw Exception('Resim yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Upload task tamamlandı');
      } catch (e) {
        debugPrint('✗ Upload task hatası: $e');
        rethrow;
      }

      // Download URL'yi al (timeout ile)
      debugPrint('Download URL alınıyor...');
      try {
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            debugPrint('✗ Download URL timeout (30 saniye)');
            throw Exception('Resim URL alınamadı. Lütfen tekrar deneyin.');
          },
        );
        debugPrint('✓ Download URL alındı: $downloadUrl');
        
        // URL'nin geçerli olduğunu kontrol et
        if (downloadUrl.isEmpty) {
          throw Exception('Geçersiz resim URL\'si alındı');
        }
        
        return downloadUrl;
      } catch (e) {
        debugPrint('✗ Download URL alma hatası: $e');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Ürün resmi yükleme hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

