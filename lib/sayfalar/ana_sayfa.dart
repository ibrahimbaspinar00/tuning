import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../model/product.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import '../config/app_routes.dart';
import '../theme/app_design_system.dart';

class AnaSayfa extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Future<void> Function(Product) onFavoriteToggle;
  final Future<void> Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final VoidCallback? onNavigateToCart;
  final bool Function(String)? isAddingToCart;
  final String? initialSearchQuery; // Header'dan gelen arama sorgusu
  final Function(String)? onNavigateToCategory; // Kategoriye gitmek için callback

  const AnaSayfa({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.onNavigateToCart,
    this.isAddingToCart,
    this.initialSearchQuery,
    this.onNavigateToCategory,
  });

  @override
  State<AnaSayfa> createState() => _AnaSayfaState();
}

class _AnaSayfaState extends State<AnaSayfa> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey _productsSectionKey = GlobalKey(); // Ürünler bölümü için key
  // FocusNode kaldırıldı - klavye sorunu için
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  List<Product> _popularProducts = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  String _sortBy = 'Popülerlik';
  bool _showOnlyDiscounted = false; // Sadece indirimli ürünleri göster
  Timer? _updateTimer;
  Timer? _debounceTimer; // Stream güncellemeleri için debounce
  
  // Services
  final ProductService _productService = ProductService();
  
  // Stream subscription for real-time updates
  StreamSubscription<List<Product>>? _productsSubscription;


  @override
  void initState() {
    super.initState();
    // Header'dan gelen arama sorgusunu ayarla
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = widget.initialSearchQuery!;
    }
    // İlk yükleme için Stream'i başlat - sadece kritik olanı
    _loadProducts();
    
    // Special products ve continuous updates'i lazy yükle - UI render'dan sonra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // UI render olduktan sonra yükle - performans için
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _loadSpecialProducts();
            _startContinuousUpdates();
          }
        });
        
        // İlk yüklemede de filtreleme yap (eğer arama sorgusu varsa)
        if (_searchQuery.isNotEmpty) {
          _filterProducts();
        }
      }
    });
    // Otomatik scroll kapatıldı - klavye sorunu için
    // _setupScrollListener();
    // _setupFocusListener();
    
    // Otomatik scroll tamamen kapatıldı
    // Timer(const Duration(seconds: 2), () {
    //   if (mounted) {
    //     _startAutoScroll();
    //   }
    // });
  }

  // _setupFocusListener kaldırıldı - klavye sorunu için

  @override
  void didUpdateWidget(AnaSayfa oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Header'dan yeni arama sorgusu geldiğinde güncelle
    if (widget.initialSearchQuery != oldWidget.initialSearchQuery) {
      final newQuery = widget.initialSearchQuery?.trim() ?? '';
      
      // Arama sorgusunu güncelle
      if (newQuery.isNotEmpty) {
        _searchQuery = newQuery;
        _searchController.text = newQuery;
      } else {
        _searchQuery = '';
        _searchController.clear();
      }
      
      // State güncelle
      setState(() {});
      
      // Ürünler yüklendikten sonra filtreleme yap
      if (_allProducts.isNotEmpty) {
        // Hemen filtreleme yap (postFrameCallback ile state güncellemesinin tamamlanmasını bekle)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _allProducts.isNotEmpty) {
            _filterProducts();
          }
        });
      }
      // Ürünler henüz yüklenmemişse, _loadProducts içinde zaten filtreleme yapılacak
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Timer'ları iptal et ve null yap
    _updateTimer?.cancel();
    _updateTimer = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    // Stream subscription'ı iptal et ve null yap
    _productsSubscription?.cancel();
    _productsSubscription = null;
    super.dispose();
  }

  void _loadProducts() {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    // Önceki subscription'ı iptal et
    _productsSubscription?.cancel();
    
    // Stream'den ürünleri dinle (anlık güncelleme) - Debounce ile optimize edildi
    _productsSubscription = _productService.getAllProductsStream().listen(
      (products) {
        if (!mounted) return;
        
        debugPrint('📦 Stream\'den ürünler geldi: ${products.length} adet');
        
        if (products.isEmpty) {
          debugPrint('⚠️ Stream\'den boş liste geldi! Firestore\'da ürün var mı kontrol edin.');
        } else {
          debugPrint('✅ Stream\'den ${products.length} adet ürün geldi');
          for (final product in products.take(3)) {
            debugPrint('   - ${product.name} (${product.id}) - isActive kontrolü yapıldı');
          }
        }
        
        // Debounce: Çok sık güncellemeleri önle - performans için
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          
          // Real-time güncelleme: Her değişiklikte güncelle (admin panelinden eklenen ürünler için)
          setState(() {
            _allProducts = products;
            _isLoading = false;
          });
          
          debugPrint('✅ _allProducts güncellendi: ${_allProducts.length} adet');
          
          if (_allProducts.isEmpty) {
            debugPrint('⚠️ _allProducts boş! Firestore\'da ürün var mı kontrol edin.');
          }
          
          // Ürünler yüklendikten sonra filtreleme yap (her zaman, boş olsa bile)
          if (mounted) {
            // Kısa bir gecikme ile filtreleme yap (state güncellemesinin tamamlanması için)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _filterProducts();
                debugPrint('🔍 Filtreleme yapıldı: ${_filteredProducts.length} adet ürün gösteriliyor');
                
                if (_filteredProducts.isEmpty && _allProducts.isNotEmpty) {
                  debugPrint('⚠️ Filtreleme sonucu boş ama _allProducts dolu! Filtreleme mantığında sorun olabilir.');
                }
              }
            });
          }
        });
      },
      onError: (error, stackTrace) {
        debugPrint('❌ Error loading products stream: $error');
        debugPrint('📋 Stack trace: $stackTrace');
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          // Hata durumunda boş liste
          _allProducts = [];
          _filteredProducts = [];
        });
      },
    );
  }

  Future<void> _loadSpecialProducts() async {
    try {
      // En çok alınan ve yorumu yüksek olan ürünleri yükle
      final popular = await _productService.getPopularProducts(limit: 10);
      
      if (mounted) {
        setState(() {
          _popularProducts = popular;
        });
        
        // Otomatik scroll kapatıldı - klavye sorunu için
      }
    } catch (e) {
      debugPrint('Error loading special products: $e');
    }
  }

  void _startContinuousUpdates() {
    // Performans için timer kaldırıldı - sadece manuel refresh ile güncelleme
    // _updateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
    //   if (!mounted) return;
    //   _loadSpecialProducts();
    // });
  }


  void _filterProducts() {
    if (!mounted) return;
    
    // Eğer ürün yoksa, filteredProducts'ı boş yap
    if (_allProducts.isEmpty) {
      debugPrint('⚠️ _allProducts boş, _filteredProducts boş yapılıyor');
      setState(() {
        _filteredProducts = [];
      });
      return;
    }
    
    debugPrint('🔍 Filtreleme başlıyor: ${_allProducts.length} ürün, kategori: $_selectedCategory, arama: $_searchQuery');
    
    // Performance optimization: Use cached filtered list
    List<Product> filtered = List.from(_allProducts);

    // İndirimli ürünler filtresi
    if (_showOnlyDiscounted) {
      filtered = filtered.where((product) => product.discountPercentage > 0).toList();
    }

    // Kategori filtresi - optimize with early return
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Arama filtresi - optimize with cached lowercase
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      if (query.isNotEmpty) {
        filtered = filtered.where((product) {
          final name = product.name.toLowerCase();
          final description = product.description.toLowerCase();
          final category = product.category.toLowerCase();
          // Ürün adı, açıklama veya kategori içinde ara
          return name.contains(query) || 
                 description.contains(query) || 
                 category.contains(query);
        }).toList();
      }
    }

    // Sıralama - optimize with stable sort
    switch (_sortBy) {
      case 'Popülerlik':
        // Popülerlik skoru = satış sayısı * 0.4 + yorum sayısı * 0.3 + ortalama puan * 10 * 0.3
        filtered.sort((a, b) {
          final scoreA = (a.salesCount * 0.4) + (a.reviewCount * 0.3) + (a.averageRating * 10 * 0.3);
          final scoreB = (b.salesCount * 0.4) + (b.reviewCount * 0.3) + (b.averageRating * 10 * 0.3);
          return scoreB.compareTo(scoreA);
        });
        break;
      case 'Fiyat (Düşük-Yüksek)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat (Yüksek-Düşük)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Yeni':
        // ID'ye göre sıralama (demo için - gerçek uygulamada createdAt kullanılmalı)
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Değerlendirme':
        // Ortalama puana göre sıralama
        filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
    }

    // Sıralama sonrası state güncelle - Real-time güncelleme için her zaman güncelle
    if (mounted) {
      setState(() {
        _filteredProducts = filtered;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Scaffold(
      backgroundColor: AppDesignSystem.background,
      resizeToAvoidBottomInset: false,
      body: RefreshIndicator(
        onRefresh: () async {
          _loadProducts();
          await _loadSpecialProducts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özellik ikonları (Trendyol tarzı) - RepaintBoundary ile optimize edildi
                RepaintBoundary(
                  child: _buildFeatureIcons(),
                ),
                
                // Popüler Ürünler (Mobil uygulamadan)
                if (!_isLoading && _popularProducts.isNotEmpty) ...[
                  RepaintBoundary(
                    child: _buildSpecialProductsSection(),
                  ),
                ],
                
                // Önerilen Tuning Parçaları
                if (!_isLoading && _popularProducts.isNotEmpty) ...[
                  RepaintBoundary(
                    child: _buildPersonalizedSection(),
                  ),
                ],
                
                // En Çok Satan Tuning Parçaları
                if (!_isLoading && _filteredProducts.isNotEmpty) ...[
                  RepaintBoundary(
                    child: _buildBestSellersSection(),
                  ),
                ],
                
                // Tüm Tuning Parçaları
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(80),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_allProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz Ürün Yok',
                            style: AppDesignSystem.heading4,
                          ),
                          const SizedBox(height: AppDesignSystem.spacingS),
                          Text(
                            'Şu anda gösterilecek ürün bulunmamaktadır.',
                            style: AppDesignSystem.bodyMedium.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Ürün Bulunamadı',
                            style: AppDesignSystem.heading4,
                          ),
                          const SizedBox(height: AppDesignSystem.spacingS),
                          Text(
                            'Arama kriterlerinize uygun ürün bulunamadı.',
                            style: AppDesignSystem.bodyMedium.copyWith(
                              color: AppDesignSystem.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Padding(
                    key: _productsSectionKey,
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          _getSectionTitle(),
                          style: AppDesignSystem.heading2,
                        ),
                        const SizedBox(height: 16),
                        _buildProductGrid(),
                      ],
                    ),
                  ),
                const SizedBox(height: 40),
              ],
            ),
        ),
      ),
    );
  }


  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    final childAspectRatio = screenWidth > 600 ? 0.75 : 0.8;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        // Rebuild optimizasyonu: RepaintBoundary ile her item'ı izole et
        return RepaintBoundary(
          key: ValueKey('product_${product.id}'), // Sabit key - rebuild önleme
          child: _buildProductCard(product),
        );
      },
    );
  }

  // Mobil uygulamadan uyarlanan ürün kartı
  Widget _buildProductCard(Product product) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts.any((p) => p.id == product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;

    return RepaintBoundary(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              AppRoutes.navigateToProductDetail(
                context,
                product,
                favoriteProducts: widget.favoriteProducts,
                cartProducts: widget.cartProducts,
                onFavoriteToggle: widget.onFavoriteToggle,
                onAddToCart: widget.onAddToCart,
                onRemoveFromCart: widget.onRemoveFromCart,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFE8E8E8),
                  width: 1,
                ),
              ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ürün resmi - Sabit yükseklik ile overflow önleme
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        OptimizedImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        // İndirim badge
                        if (product.discountPercentage > 0)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '%${product.discountPercentage.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppDesignSystem.surface,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        // Favori butonu
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () async {
                              await widget.onFavoriteToggle(product);
                              if (mounted) {
                                setState(() {}); // State'i güncelle
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: 18,
                                color: isFavorite ? Colors.red : Colors.grey[600],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Ürün bilgileri - Overflow koruması ile
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ürün adı - Sabit yükseklik
                    SizedBox(
                      height: 36, // 2 satır için yeterli alan
                      child: Text(
                        product.name,
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F0F0F),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Rating badge (Trendyol tarzı)
                    if (product.averageRating > 0)
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${product.averageRating.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F0F0F),
                            ),
                          ),
                          if (product.reviewCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '(${product.reviewCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF6A6A6A),
                              ),
                            ),
                          ],
                        ],
                      ),
                    
                    const SizedBox(height: 4),
                    
                    // Fiyat
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} ₺',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${(product.price * 1.11).toStringAsFixed(2)} ₺',
                            style: TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: const Color(0xFF6A6A6A),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Butonlar - Mobil uygulamadan
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Favori butonu
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await widget.onFavoriteToggle(product);
                                if (mounted) {
                                  setState(() {}); // State'i güncelle
                                }
                              },
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                size: isSmallScreen ? 14 : 16,
                                color: isFavorite ? Colors.red : Colors.grey[700],
                              ),
                              label: Text(
                                isFavorite ? 'Favoride' : 'Favori',
                                style: TextStyle(fontSize: isSmallScreen ? 10 : 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFavorite ? Colors.red[50] : Colors.grey[50],
                                foregroundColor: isFavorite ? Colors.red : Colors.grey[700],
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 4),
                        
                        // Sepete ekle butonu (profesyonel - loading state ile)
                        Expanded(
                          child: SizedBox(
                            height: isSmallScreen ? 28 : 32,
                            child: Builder(
                              builder: (context) {
                                final isAdding = widget.isAddingToCart?.call(product.id) ?? false;
                                final isDisabled = isAdding || inCart;
                                
                                return ElevatedButton(
                                  onPressed: isDisabled ? null : () async {
                                    if (inCart) {
                                      widget.onRemoveFromCart(product);
                                    } else {
                                      await widget.onAddToCart(product);
                                    }
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: inCart 
                                        ? Colors.green[50] 
                                        : isAdding 
                                            ? Colors.grey[200] 
                                            : Colors.blue[50],
                                    foregroundColor: inCart 
                                        ? Colors.green 
                                        : isAdding 
                                            ? Colors.grey[600] 
                                            : Colors.blue[700],
                                    elevation: 0,
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    disabledBackgroundColor: Colors.grey[200],
                                    disabledForegroundColor: Colors.grey[600],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isAdding)
                                        SizedBox(
                                          width: isSmallScreen ? 10 : 12,
                                          height: isSmallScreen ? 10 : 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blue[700]!,
                                            ),
                                          ),
                                        )
                                      else
                                        Icon(
                                          inCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                                          size: isSmallScreen ? 12 : 14,
                                        ),
                                      SizedBox(width: isSmallScreen ? 2 : 4),
                                      Flexible(
                                        child: Text(
                                          isAdding 
                                              ? 'Ekleniyor...' 
                                              : inCart 
                                                  ? 'Sepette' 
                                                  : 'Sepete',
                                          style: TextStyle(fontSize: isSmallScreen ? 9 : 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobil uygulamadan uyarlanan popüler ürünler bölümü
  Widget _buildSpecialProductsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 0, // Padding'i kaldırdık, ListView kendi padding'ini yönetecek
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: AppDesignSystem.background,
        border: Border(
          top: BorderSide(
            color: AppDesignSystem.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık - Padding ile
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : 24,
            ),
            child: Text(
              '🔥 Popüler Tuning Parçaları',
              style: AppDesignSystem.heading2.copyWith(
                fontSize: isSmallScreen ? 18 : 22,
              ),
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingM),
          // Ürünler - Horizontal scroll (sağa kaydırma)
          SizedBox(
            height: isDesktop ? 430 : 410, // Overflow'u tamamen önlemek için yükseklik ayarlandı
            width: double.infinity, // Genişliği tam yap
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(), // Web için scroll'u zorunlu kıl
              shrinkWrap: false, // Genişliği tam kullan
              primary: false, // SingleChildScrollView ile çakışmayı önle
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24, // Her iki tarafta padding
              ),
              itemCount: _popularProducts.length,
              itemBuilder: (context, index) {
                final product = _popularProducts[index];
                return Container(
                  width: isDesktop ? 280 : 240,
                  margin: EdgeInsets.only(
                    right: AppDesignSystem.spacingM,
                  ),
                  child: _buildTrendyolProductCard(product),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tuning tarzı özellik ikonları - Araç parçaları ve tuning malzemeleri
  Widget _buildFeatureIcons() {
    final features = [
      {
        'icon': Icons.trending_down,
        'label': 'Fiyatı Düşenler',
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFFE5E5),
        'onTap': () => _filterByDiscount(),
      },
      {
        'icon': Icons.new_releases,
        'label': 'Yeni Ürünler',
        'color': const Color(0xFFD4AF37),
        'bgColor': const Color(0xFFFFF8E5),
        'onTap': () => _filterByNew(),
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Çok Satanlar',
        'color': const Color(0xFFFF6000),
        'bgColor': const Color(0xFFFFF0E5),
        'onTap': () => _filterByBestSellers(),
      },
      {
        'icon': Icons.speed,
        'label': 'Motor Tuning',
        'color': const Color(0xFF6366F1),
        'bgColor': const Color(0xFFE5E7FF),
        'onTap': () => _filterByCategory('Motor Parçaları'),
      },
      {
        'icon': Icons.auto_awesome,
        'label': 'Görünüm Tuning',
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFE5FFF0),
        'onTap': () => _filterByCategory('Görünüm & Body Kit'),
      },
      {
        'icon': Icons.tune,
        'label': 'Performans',
        'color': const Color(0xFFF59E0B),
        'bgColor': const Color(0xFFFFF4E5),
        'onTap': () => _filterByCategory('Elektronik & ECU'),
      },
      {
        'icon': Icons.percent,
        'label': 'Kuponlarım',
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFFE5E5),
        'onTap': () => _showCouponsDialog(),
      },
      {
        'icon': Icons.shopping_cart,
        'label': 'Sepetim',
        'color': const Color(0xFF8B5CF6),
        'bgColor': const Color(0xFFF3E5FF),
        'onTap': () {
          if (widget.onNavigateToCart != null) {
            widget.onNavigateToCart!();
          }
        },
      },
    ];

    return Container(
      color: AppDesignSystem.surface,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 0),
      child: SizedBox(
        height: 120, // Yeterli yükseklik - overflow'u önlemek için
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: features.length + 1,
          itemBuilder: (context, index) {
            if (index == features.length) {
              return const SizedBox(width: 24);
            }
            final feature = features[index];
            return GestureDetector(
              onTap: feature['onTap'] as VoidCallback,
              child: Container(
                width: 90,
                margin: const EdgeInsets.only(right: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // İkon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: feature['bgColor'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        feature['icon'] as IconData,
                        color: feature['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Label - Overflow koruması ile
                    SizedBox(
                      height: 32, // Sabit yükseklik - overflow'u önlemek için
                      child: Text(
                        feature['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF0F0F0F),
                          fontWeight: FontWeight.w500,
                          height: 1.1, // Daha sıkı satır aralığı
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
    );
  }

  void _filterByDiscount() {
    setState(() {
      _selectedCategory = 'Tümü';
      _searchQuery = '';
      _sortBy = 'Fiyat (Düşük-Yüksek)';
      _showOnlyDiscounted = true;
    });
    _filterProducts();
    
    // Sayfayı ürünler bölümüne kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productsSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _productsSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _filterByNew() {
    setState(() {
      _selectedCategory = 'Tümü';
      _searchQuery = '';
      _sortBy = 'Yeni';
      _showOnlyDiscounted = false;
    });
    _filterProducts();
    
    // Sayfayı ürünler bölümüne kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productsSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _productsSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _filterByBestSellers() {
    setState(() {
      _selectedCategory = 'Tümü';
      _searchQuery = '';
      _sortBy = 'Popülerlik';
      _showOnlyDiscounted = false;
    });
    _filterProducts();
    
    // Sayfayı ürünler bölümüne kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productsSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _productsSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  String _getSectionTitle() {
    if (_showOnlyDiscounted) {
      return 'İndirimli Tuning Parçaları';
    } else if (_selectedCategory != 'Tümü') {
      return '$_selectedCategory';
    } else if (_sortBy == 'Yeni') {
      return 'Yeni Tuning Parçaları';
    } else if (_sortBy == 'Popülerlik') {
      return 'Çok Satan Tuning Parçaları';
    }
    return 'Tüm Tuning Parçaları';
  }

  void _filterByCategory(String category) {
    // Ana sayfada kategoriye göre filtrele
    setState(() {
      _selectedCategory = category;
      _searchQuery = '';
      _showOnlyDiscounted = false;
      _sortBy = 'Popülerlik';
    });
    _filterProducts();
    
    // Sayfayı ürünler bölümüne kaydır
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _productsSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _productsSectionKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }


  void _showCouponsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kuponlarım',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Kupon özelliği yakında eklenecek.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF6A6A6A),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF6000),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sana Özel Ürünler bölümü
  Widget _buildPersonalizedSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return Container(
      color: AppDesignSystem.surface,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Önerilen Tuning Parçaları',
                  style: AppDesignSystem.heading3,
                ),
                TextButton(
                  onPressed: () {
                    widget.onNavigateToCategory?.call('Tümü');
                  },
                  child: Text(
                    'Tümünü Gör',
                    style: AppDesignSystem.labelMedium.copyWith(
                      color: AppDesignSystem.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingM),
          SizedBox(
            height: 380,
            width: double.infinity, // Genişliği tam yap
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(), // Web için scroll'u zorunlu kıl
              shrinkWrap: false, // Genişliği tam kullan
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
              ),
              itemCount: _popularProducts.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 240,
                  margin: EdgeInsets.only(
                    right: AppDesignSystem.spacingM,
                  ),
                  child: _buildTrendyolProductCard(_popularProducts[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Çok Satanlar bölümü
  Widget _buildBestSellersSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    final bestSellers = _filteredProducts.take(10).toList();

    return Container(
      color: AppDesignSystem.background,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80 : 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'En Çok Satan Tuning Parçaları',
                  style: AppDesignSystem.heading3,
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Tümünü Gör',
                    style: AppDesignSystem.labelMedium.copyWith(
                      color: AppDesignSystem.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDesignSystem.spacingM),
          SizedBox(
            height: 380,
            width: double.infinity, // Genişliği tam yap
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(), // Web için scroll'u zorunlu kıl
              shrinkWrap: false, // Genişliği tam kullan
              primary: false, // SingleChildScrollView ile çakışmayı önle
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
              ),
              itemCount: bestSellers.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 240,
                  margin: EdgeInsets.only(
                    right: AppDesignSystem.spacingM,
                  ),
                  child: _buildTrendyolProductCard(bestSellers[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Trendyol tarzı ürün kartı
  Widget _buildTrendyolProductCard(Product product) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    return GestureDetector(
      onTap: () {
        AppRoutes.navigateToProductDetail(context, product);
      },
      child: Container(
        height: isDesktop ? 410 : 390, // Sabit yükseklik - overflow önleme (biraz artırıldı)
        decoration: AppDesignSystem.cardDecoration(
          borderRadius: AppDesignSystem.radiusM,
          shadows: AppDesignSystem.shadowS,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ürün resmi - Sabit yükseklik ile overflow önleme
            Expanded(
              flex: 3, // Resim için 3 birim
              child: AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppDesignSystem.surfaceVariant,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDesignSystem.radiusM)),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDesignSystem.radiusM)),
                      child: OptimizedImage(
                        imageUrl: product.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // İndirim badge
                  if (product.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.error,
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                        ),
                        child: Text(
                          '%${product.discountPercentage.toStringAsFixed(0)}',
                          style: AppDesignSystem.labelSmall.copyWith(
                            color: AppDesignSystem.textOnPrimary,
                          ),
                        ),
                      ),
                    ),
                  // Favori butonu
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                        onTap: () async {
                              await widget.onFavoriteToggle(product);
                              if (mounted) {
                                setState(() {}); // State'i güncelle
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppDesignSystem.surface,
                          shape: BoxShape.circle,
                          boxShadow: AppDesignSystem.shadowXS,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? AppDesignSystem.favorite : AppDesignSystem.textSecondary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
            // Ürün bilgileri - Overflow koruması ile
            Expanded(
              flex: 2, // Bilgiler için 2 birim
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // all(12)'den düşürüldü
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ürün adı - Sabit yükseklik
                    SizedBox(
                      height: 30, // 32'den 30'a düşürüldü
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    // Fiyat
                    Row(
                      children: [
                        Text(
                          '${product.price.toStringAsFixed(2)} ₺',
                          style: AppDesignSystem.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.discountPercentage > 0) ...[
                          const SizedBox(width: AppDesignSystem.spacingS),
                          Text(
                            '${(product.price / (1 - product.discountPercentage / 100)).toStringAsFixed(2)} ₺',
                            style: AppDesignSystem.bodySmall.copyWith(
                              color: AppDesignSystem.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppDesignSystem.spacingXS),
                    // Yıldız puanı
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 12,
                          color: AppDesignSystem.accent,
                        ),
                        const SizedBox(width: AppDesignSystem.spacingXS),
                        Text(
                          product.averageRating.toStringAsFixed(1),
                          style: AppDesignSystem.bodySmall.copyWith(
                            color: AppDesignSystem.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Sepete ekle butonu - Spacer yerine sabit boşluk
                    const SizedBox(height: 4),
                    Builder(
                      builder: (context) {
                        final inCart = widget.cartProducts.any((p) => p.id == product.id);
                        final isAdding = widget.isAddingToCart?.call(product.id) ?? false;
                        
                        return SizedBox(
                          width: double.infinity,
                          height: 28, // 30'dan 28'e düşürüldü - overflow önleme
                          child: ElevatedButton(
                            onPressed: isAdding ? null : () async {
                              if (inCart) {
                                widget.onRemoveFromCart(product);
                              } else {
                                await widget.onAddToCart(product);
                              }
                              if (mounted) {
                                setState(() {});
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: inCart 
                                  ? AppDesignSystem.success
                                  : AppDesignSystem.primary,
                              foregroundColor: AppDesignSystem.textOnPrimary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: isAdding
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        inCart ? Icons.check : Icons.shopping_cart,
                                        size: 13,
                                        color: AppDesignSystem.textOnPrimary,
                                      ),
                                      const SizedBox(width: AppDesignSystem.spacingXS),
                                      Text(
                                        inCart ? 'Sepette' : 'Sepete Ekle',
                                        style: AppDesignSystem.labelSmall.copyWith(
                                          color: AppDesignSystem.textOnPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

