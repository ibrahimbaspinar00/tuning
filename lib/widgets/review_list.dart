import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/product_review.dart';
import '../services/review_service.dart';
import 'star_rating.dart';
import 'review_form.dart';

class ReviewList extends StatefulWidget {
  final String productId;
  final List<ProductReview>? reviews;
  final VoidCallback? onReviewUpdated;

  const ReviewList({
    super.key,
    required this.productId,
    this.reviews,
    this.onReviewUpdated,
  });

  @override
  State<ReviewList> createState() => _ReviewListState();
}

class _ReviewListState extends State<ReviewList> {
  List<ProductReview> _reviews = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void didUpdateWidget(ReviewList oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    bool shouldReload = false;
    
    // Eğer reviews prop'u değiştiyse güncelle
    if (widget.reviews != null && widget.reviews != oldWidget.reviews) {
      final oldLength = oldWidget.reviews?.length ?? 0;
      final newLength = widget.reviews!.length;
      
      debugPrint('ReviewList: Widget.reviews değişti (${oldLength} → ${newLength}), güncelleniyor...');
      
      // Eğer yeni yorum eklendiyse (sayı arttı), Firestore'dan da yükle
      if (newLength > oldLength) {
        debugPrint('ReviewList: Yeni yorum eklendi görünüyor, Firestore\'dan yeniden yüklenecek');
        shouldReload = true;
      } else {
        // Sadece state'i güncelle
        setState(() {
          _reviews = widget.reviews!;
          _isLoading = false;
        });
      }
    } else if (widget.reviews == null && oldWidget.reviews != null) {
      // Reviews null olduysa yeniden yükle
      debugPrint('ReviewList: Widget.reviews null oldu, yeniden yükleniyor...');
      shouldReload = true;
    }
    
    // ProductId değiştiyse yeniden yükle
    if (widget.productId != oldWidget.productId) {
      debugPrint('ReviewList: ProductId değişti, yeniden yükleniyor...');
      shouldReload = true;
    }
    
    // Key değiştiyse de yeniden yükle (zorla refresh için)
    if (widget.key != oldWidget.key) {
      debugPrint('ReviewList: Key değişti, yeniden yükleniyor...');
      shouldReload = true;
    }
    
    if (shouldReload) {
      _loadReviews();
    }
  }

  Future<void> _loadReviews() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }
      
      debugPrint('=== ReviewList: Yorumlar yükleniyor ===');
      debugPrint('Product ID: ${widget.productId}');
      
      // Her zaman Firestore'dan yükle (güncel veri için - Source.server ile)
      final reviews = await ReviewService.getProductReviews(widget.productId);
      
      debugPrint('ReviewList: Firestore\'dan ${reviews.length} yorum yüklendi');
      
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _isLoading = false;
        });
        
        debugPrint('✓ ReviewList state güncellendi: ${_reviews.length} yorum gösteriliyor');
        
        // Callback'i çağır (ana sayfa bilgilendirmesi için)
        // Ama sadece gerçekten bir değişiklik varsa çağır (sonsuz döngü önlemek için)
        // Not: Bu callback artık sadece bilgilendirme amaçlı, otomatik yenileme yapmıyor
        // if (widget.onReviewUpdated != null) {
        //   widget.onReviewUpdated!();
        // }
      }
    } catch (e, stackTrace) {
      debugPrint('ReviewList: Yorumlar yüklenirken hata: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorumlar yüklenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Public metod - dışarıdan çağrılabilir
  Future<void> refreshReviews() async {
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Icons.comment_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz yorum yok',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'İlk yorumu siz yapın!',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showReviewForm,
              icon: const Icon(Icons.add_comment),
              label: const Text('Yorum Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Yorum başlığı ve istatistikler
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Yorumlar (${_reviews.length})',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _showReviewForm,
                    icon: const Icon(Icons.add_comment, size: 16),
                    label: const Text('Yorum Yap'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Yorum listesi
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviews.length,
          itemBuilder: (context, index) {
            final review = _reviews[index];
            return _buildReviewCard(review, isSmallScreen, isTablet);
          },
        ),
      ],
    );
  }

  Widget _buildReviewCard(ProductReview review, bool isSmallScreen, bool isTablet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kullanıcı bilgileri ve rating
          Row(
            children: [
              CircleAvatar(
                radius: isSmallScreen ? 18 : 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  (review.userName.trim().isNotEmpty)
                      ? review.userName.trim()[0].toUpperCase()
                      : 'A',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSmallScreen ? 14 : 16,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    StarRating(
                      rating: review.rating.toDouble(),
                      size: isSmallScreen ? 14 : 16,
                    ),
                  ],
                ),
              ),
              // Tarih ve düzenleme butonu - Expanded ile sarmala
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _formatDate(review.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: isSmallScreen ? 11 : 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Düzenleme butonu (sadece kullanıcının kendi yorumu için)
                    if (FirebaseAuth.instance.currentUser != null &&
                        FirebaseAuth.instance.currentUser!.uid == review.userId) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.edit, size: isSmallScreen ? 16 : 18, color: Colors.blue[600]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditReviewDialog(context, review),
                        tooltip: 'Yorumu Düzenle',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Yorum metni
          Text(
            review.comment,
            style: TextStyle(
              fontSize: isSmallScreen ? 13 : 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
          
          // Fotoğraflar
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.photo_library, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Fotoğraflar (${review.imageUrls.length})',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: review.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => _showImageGallery(context, review.imageUrls, index),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CachedNetworkImage(
                                      imageUrl: review.imageUrls[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Fotoğraf sayısı badge (birden fazla fotoğraf varsa)
                                if (review.imageUrls.length > 1 && index == 0)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '+${review.imageUrls.length}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Admin yanıtı
          if (review.adminResponse != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: isSmallScreen ? 14 : 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Admin Yanıtı',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                          fontSize: isSmallScreen ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.adminResponse!,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      color: Colors.green[800],
                      height: 1.3,
                    ),
                  ),
                  if (review.adminResponseDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(review.adminResponseDate!),
                      style: TextStyle(
                        fontSize: isSmallScreen ? 10 : 11,
                        color: Colors.green[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black87,
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageGallery(BuildContext context, List<String> imageUrls, int initialIndex) {
    int currentIndex = initialIndex;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.black87,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: CachedNetworkImage(
                        imageUrl: imageUrls[index],
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Container(
                          color: Colors.black87,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: Colors.black87,
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              if (imageUrls.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${currentIndex + 1} / ${imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditReviewDialog(BuildContext context, ProductReview review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Başlık
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Yorumu Düzenle',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Review Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ReviewForm(
                  productId: review.productId,
                  existingReview: review,
                  onReviewAdded: () {
                    Navigator.pop(context); // Dialog'u kapat
                    // Yorumları yenile
                    if (widget.onReviewUpdated != null) {
                      widget.onReviewUpdated!();
                    }
                    _loadReviews(); // Yorumları yeniden yükle
                  },
                  hasPurchased: true, // Düzenleme modunda zaten satın alınmış
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Az önce';
    }
  }

  void _showReviewForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.add_comment, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Yorum Yap',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            // Review form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildReviewForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewForm() {
    return FutureBuilder<bool>(
      future: _checkPurchaseStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final hasPurchased = snapshot.data ?? false;

        if (!hasPurchased) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_cart, color: Colors.orange[600], size: 48),
                const SizedBox(height: 12),
                Text(
                  'Bu ürünü satın aldıktan sonra yorum yapabilirsiniz',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ürünü satın almak için ürün detay sayfasına gidin.',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        int rating = 5;
        final commentController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating
                const Text(
                  'Puanınız:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StarRating(
                  rating: rating.toDouble(),
                  onRatingChanged: (newRating) {
                    setState(() {
                      rating = newRating.round();
                    });
                  },
                ),
                const SizedBox(height: 20),
                
                // Comment
                const Text(
                  'Yorumunuz:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Ürün hakkındaki düşüncelerinizi yazın...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (commentController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Lütfen yorum yazın')),
                        );
                        return;
                      }
                      
                      try {
                        await ReviewService.addReview(
                          productId: widget.productId,
                          rating: rating,
                          comment: commentController.text.trim(),
                        );
                        
                        Navigator.pop(context);
                        _loadReviews();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Yorumunuz başarıyla eklendi!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        String errorMessage = 'Yorum eklenirken hata oluştu';
                        if (e.toString().toLowerCase().contains('satın al')) {
                          errorMessage = 'Bu ürünü satın aldıktan sonra yorum yapabilirsiniz';
                        } else if (e.toString().toLowerCase().contains('zaten yorum')) {
                          errorMessage = 'Bu ürün için zaten yorum yaptınız';
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Yorumu Gönder',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<bool> _checkPurchaseStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return false;
      }
      
      return await ReviewService.hasUserPurchasedProduct(widget.productId, user.uid);
    } catch (e) {
      debugPrint('Purchase check error: $e');
      return false;
    }
  }
}
