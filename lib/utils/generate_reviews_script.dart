import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../services/product_service.dart';

/// Yorum oluşturma scripti
/// Her ürüne 50 yorum ekler, 10 tanesi fotoğraflı
class GenerateReviewsScript {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ProductService _productService = ProductService();

  // Yorum metinleri (farklı puanlar için)
  final List<String> _positiveComments = [
    'Harika bir ürün! Kesinlikle tavsiye ederim. Kalitesi çok iyi.',
    'Çok memnun kaldım. Beklentilerimi karşıladı ve daha fazlası.',
    'Mükemmel kalite, hızlı kargo. Teşekkürler!',
    'Ürün çok kaliteli, fiyatına göre çok iyi. Beğendim.',
    'Kesinlikle tekrar alırım. Çok memnun kaldım.',
    'Ürün tam istediğim gibi. Çok beğendim.',
    'Kaliteli ve dayanıklı. Uzun süre kullanacağım.',
    'Hızlı teslimat, kaliteli ürün. Teşekkürler.',
    'Çok güzel bir ürün. Arkadaşlarıma da tavsiye ettim.',
    'Beklentilerimi aştı. Çok memnunum.',
    'Mükemmel! Kesinlikle öneririm.',
    'Kaliteli malzeme, güzel tasarım. Beğendim.',
    'Çok iyi bir ürün. Fiyatına göre çok değerli.',
    'Hızlı kargo, kaliteli ürün. Teşekkürler.',
    'Ürün çok güzel, kalitesi çok iyi.',
  ];

  final List<String> _neutralComments = [
    'Ürün fena değil ama beklentilerimi tam karşılamadı.',
    'Orta seviye bir ürün. Fiyatına göre idare eder.',
    'Ürün normal, özel bir şey yok.',
    'Beklediğim gibi değildi ama kötü de değil.',
    'İdare eder, fiyatına göre makul.',
    'Ürün normal, özel bir beklentim yoktu zaten.',
    'Orta kalite, fiyatına göre uygun.',
    'Beklentilerimi tam karşılamadı ama kötü de değil.',
    'Normal bir ürün, özel bir şey yok.',
    'Fiyatına göre idare eder.',
  ];

  final List<String> _negativeComments = [
    'Ürün beklentilerimi karşılamadı. Kalitesi düşük.',
    'Maalesef memnun kalmadım. Kalite sorunları var.',
    'Ürün çok kötü, kesinlikle tavsiye etmem.',
    'Kalitesi çok düşük, parama yazık oldu.',
    'Beklentilerimin çok altında kaldı.',
    'Ürün bozuk geldi, değişim istedim.',
    'Kalite çok kötü, fiyatına göre değmez.',
    'Memnun kalmadım, ürün sorunlu.',
    'Beklediğim gibi değildi, hayal kırıklığı.',
    'Ürün kalitesiz, tavsiye etmem.',
  ];

  // Kullanıcı isimleri
  final List<String> _userNames = [
    'Ahmet Yılmaz',
    'Mehmet Demir',
    'Ayşe Kaya',
    'Fatma Şahin',
    'Ali Çelik',
    'Zeynep Arslan',
    'Mustafa Öztürk',
    'Elif Yıldız',
    'Burak Aydın',
    'Selin Doğan',
    'Can Özdemir',
    'Deniz Kılıç',
    'Emre Yücel',
    'Gizem Aktaş',
    'Hakan Şimşek',
    'İpek Çınar',
    'Kemal Yıldırım',
    'Leyla Özkan',
    'Murat Güneş',
    'Nazlı Karaca',
    'Onur Bulut',
    'Pınar Ateş',
    'Rıza Çakır',
    'Seda Yılmaz',
    'Tolga Korkmaz',
    'Umut Aslan',
    'Vildan Özer',
    'Yasin Çelik',
    'Zehra Demir',
    'Arda Yıldız',
    'Beren Öztürk',
    'Cem Aydın',
    'Derya Doğan',
    'Ege Özdemir',
    'Fulya Kılıç',
    'Gökhan Yücel',
    'Hilal Aktaş',
    'İrem Şimşek',
    'Kaan Çınar',
    'Melisa Yıldırım',
    'Nihan Özkan',
    'Okan Güneş',
    'Pelin Karaca',
    'Rüya Bulut',
    'Serkan Ateş',
    'Tuğba Çakır',
    'Utku Yılmaz',
    'Vera Korkmaz',
    'Yusuf Aslan',
    'Zara Özer',
  ];

  // Fotoğraflı yorumlar için placeholder URL'ler (Cloudinary veya başka bir servis)
  final List<String> _imageUrls = [
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_1.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_2.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_3.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_4.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_5.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_6.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_7.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_8.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_9.jpg',
    'https://res.cloudinary.com/dobjrnkea/image/upload/v1/reviews/review_10.jpg',
  ];

  /// Tüm yorumları sil
  Future<void> deleteAllReviews() async {
    try {
      debugPrint('🗑️ Tüm yorumlar siliniyor...');
      
      final reviewsSnapshot = await _firestore
          .collection('product_reviews')
          .get();
      
      debugPrint('📊 Toplam ${reviewsSnapshot.docs.length} yorum bulundu');
      
      // Batch delete (500'lük gruplar halinde)
      final batchSize = 500;
      for (int i = 0; i < reviewsSnapshot.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < reviewsSnapshot.docs.length) 
            ? i + batchSize 
            : reviewsSnapshot.docs.length;
        
        for (int j = i; j < end; j++) {
          batch.delete(reviewsSnapshot.docs[j].reference);
        }
        
        await batch.commit();
        debugPrint('✅ ${end} yorum silindi...');
      }
      
      debugPrint('✅ Tüm yorumlar başarıyla silindi!');
    } catch (e) {
      debugPrint('❌ Yorum silme hatası: $e');
      rethrow;
    }
  }

  /// Bir ürün için yorum oluştur
  Future<void> generateReviewsForProduct(String productId, String productName) async {
    try {
      debugPrint('📝 Ürün için yorumlar oluşturuluyor: $productName');
      
      final batch = _firestore.batch();
      final reviewsRef = _firestore.collection('product_reviews');
      
      // 50 yorum oluştur
      for (int i = 0; i < 50; i++) {
        // Puan dağılımı: 1-5 arası, çoğu 3-5 arası
        int rating;
        if (i < 5) {
          rating = 1; // 5 tane 1 yıldız
        } else if (i < 10) {
          rating = 2; // 5 tane 2 yıldız
        } else if (i < 20) {
          rating = 3; // 10 tane 3 yıldız
        } else if (i < 35) {
          rating = 4; // 15 tane 4 yıldız
        } else {
          rating = 5; // 15 tane 5 yıldız
        }
        
        // Yorum metni seç
        String comment;
        if (rating >= 4) {
          comment = _positiveComments[i % _positiveComments.length];
        } else if (rating == 3) {
          comment = _neutralComments[i % _neutralComments.length];
        } else {
          comment = _negativeComments[i % _negativeComments.length];
        }
        
        // Kullanıcı bilgileri
        final userName = _userNames[i % _userNames.length];
        final userEmail = '${userName.toLowerCase().replaceAll(' ', '.')}@gmail.com';
        final userId = 'user_$i_${productId.substring(0, 8)}';
        
        // İlk 10 yorum fotoğraflı
        final List<String> imageUrls = (i < 10) 
            ? [_imageUrls[i % _imageUrls.length]]
            : [];
        
        // Tarih (son 6 ay içinde rastgele)
        final now = DateTime.now();
        final daysAgo = (i * 3) % 180; // Son 6 ay içinde
        final createdAt = now.subtract(Duration(days: daysAgo));
        final updatedAt = createdAt;
        
        // Review ID
        final reviewId = reviewsRef.doc().id;
        
        // Review data
        final reviewData = {
          'id': reviewId,
          'productId': productId,
          'userId': userId,
          'userName': userName,
          'userEmail': userEmail,
          'rating': rating,
          'comment': comment,
          'imageUrls': imageUrls,
          'createdAt': Timestamp.fromDate(createdAt),
          'updatedAt': Timestamp.fromDate(updatedAt),
          'isApproved': true, // Tüm yorumlar onaylı
          'isDemo': false, // Demo değil
          'isEdited': false,
        };
        
        batch.set(reviewsRef.doc(reviewId), reviewData);
      }
      
      // Batch commit
      await batch.commit();
      debugPrint('✅ $productName için 50 yorum oluşturuldu');
    } catch (e) {
      debugPrint('❌ Yorum oluşturma hatası ($productId): $e');
      rethrow;
    }
  }

  /// Tüm ürünler için yorum oluştur
  Future<void> generateAllReviews() async {
    try {
      debugPrint('🚀 Yorum oluşturma işlemi başlıyor...');
      
      // 1. Tüm yorumları sil
      await deleteAllReviews();
      
      // 2. Tüm ürünleri al
      debugPrint('📦 Ürünler getiriliyor...');
      final products = await _productService.getAllProductsForAdmin();
      debugPrint('📦 ${products.length} ürün bulundu');
      
      if (products.isEmpty) {
        debugPrint('⚠️ Ürün bulunamadı!');
        return;
      }
      
      // 3. Her ürün için yorum oluştur
      for (int i = 0; i < products.length; i++) {
        final product = products[i];
        debugPrint('📝 [${i + 1}/${products.length}] ${product.name} için yorumlar oluşturuluyor...');
        
        await generateReviewsForProduct(product.id, product.name);
        
        // Rate limiting (Firebase limitlerini aşmamak için)
        if (i < products.length - 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      debugPrint('✅ Tüm yorumlar başarıyla oluşturuldu!');
      debugPrint('📊 Toplam: ${products.length} ürün x 50 yorum = ${products.length * 50} yorum');
    } catch (e, stackTrace) {
      debugPrint('❌ Yorum oluşturma hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

