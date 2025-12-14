import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/product.dart';
import '../services/product_service.dart';
import '../widgets/optimized_image.dart';
import '../widgets/professional_components.dart';
import '../config/app_routes.dart';
import '../utils/responsive_helper.dart';

class KategorilerSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final Future<void> Function(Product) onFavoriteToggle;
  final Future<void> Function(Product) onAddToCart;
  final Function(Product) onRemoveFromCart;
  final String? initialCategory;

  const KategorilerSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.onFavoriteToggle,
    required this.onAddToCart,
    required this.onRemoveFromCart,
    this.initialCategory,
  });

  @override
  State<KategorilerSayfasi> createState() => _KategorilerSayfasiState();
}

class _KategorilerSayfasiState extends State<KategorilerSayfasi> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  String _selectedCategory = 'Tümü';
  String _sortBy = 'Popülerlik';
  double _minPrice = 0;
  double _maxPrice = 10000;
  bool _showFilters = false;


  final List<String> _sortOptions = [
    'Popülerlik',
    'Fiyat (Düşük-Yüksek)',
    'Fiyat (Yüksek-Düşük)',
    'Yeni',
    'Değerlendirme',
    'Stok Durumu',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      final productService = ProductService();
      final products = await productService.getAllProducts();
      if (!mounted) return;
      setState(() {
        _allProducts = products;
        _filteredProducts = List.from(_allProducts);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      // Firebase hatası durumunda boş liste
      _allProducts = [];
      _filteredProducts = [];
    }
  }

  void _filterProducts() {
    List<Product> filtered = _allProducts;

    // Kategori filtresi
    if (_selectedCategory != 'Tümü') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    // Fiyat filtresi
    filtered = filtered.where((product) => 
        product.price >= _minPrice && product.price <= _maxPrice).toList();

    // Stok filtresi
    filtered = filtered.where((product) => product.stock > 0).toList();

    // Sıralama
    switch (_sortBy) {
      case 'Fiyat (Düşük-Yüksek)':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Fiyat (Yüksek-Düşük)':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Yeni':
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Değerlendirme':
        filtered.shuffle(); // Demo için
        break;
      case 'Stok Durumu':
        filtered.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }

    if (!mounted) return;
    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: Text(
          'Kategoriler',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
        actions: [
          // Mobil ve tablet için filtre toggle butonu
          if (!isDesktop)
            IconButton(
              icon: Icon(
                _showFilters ? Icons.filter_list_off : Icons.filter_list,
                color: const Color(0xFF1A1A1A),
              ),
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              tooltip: _showFilters ? 'Filtreleri Gizle' : 'Filtreleri Göster',
            ),
        ],
      ),
      body: SafeArea(
        child: isDesktop
            ? _buildDesktopLayout(isSmallScreen, isTablet, isDesktop)
            : _buildMobileLayout(isSmallScreen, isTablet, isDesktop),
      ),
    );
  }

  // Desktop layout: Sol sidebar filtreler, sağ tarafta ürün listesi
  Widget _buildDesktopLayout(bool isSmallScreen, bool isTablet, bool isDesktop) {
    final screenWidth = ResponsiveHelper.screenWidth(context);
    final isVeryNarrow = screenWidth < 900; // Çok dar ekranlar için
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol sidebar - Filtreler (dar ekranlarda gizle veya küçült)
        if (!isVeryNarrow)
          Container(
            width: ResponsiveHelper.responsiveValue(
              context,
              mobile: 0.0, // Mobilde gösterilmez
              tablet: 240.0,
              desktop: 280.0,
            ),
            color: Colors.white,
            child: SingleChildScrollView(
              child: _buildFilters(isSmallScreen, isTablet, ResponsiveHelper.responsiveValue(
                context,
                mobile: 0.0,
                tablet: 240.0,
                desktop: 280.0,
              )),
            ),
          ),
        // Sağ taraf - Ürün listesi
        Expanded(
          child: _isLoading
              ? ProfessionalComponents.createLoadingIndicator(
                  message: 'Ürünler yükleniyor...',
                )
              : _filteredProducts.isEmpty
                  ? SingleChildScrollView(
                      child: ProfessionalComponents.createEmptyState(
                        title: 'Ürün Bulunamadı',
                        message: 'Seçilen kriterlere uygun ürün bulunamadı.',
                        icon: Icons.search_off,
                        buttonText: 'Filtreleri Temizle',
                        onButtonPressed: _clearFilters,
                      ),
                    )
                  : _buildProductGrid(isSmallScreen, isTablet, isDesktop),
        ),
      ],
    );
  }

  // Mobil/Tablet layout: Üstte filtreler (toggle ile), altta ürün listesi
  Widget _buildMobileLayout(bool isSmallScreen, bool isTablet, bool isDesktop) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filtreler
        if (_showFilters) 
          Flexible(
            child: SingleChildScrollView(
              child: _buildFilters(isSmallScreen, isTablet, MediaQuery.of(context).size.width),
            ),
          ),
        
        // Ürün listesi
        Expanded(
          child: _isLoading
              ? ProfessionalComponents.createLoadingIndicator(
                  message: 'Ürünler yükleniyor...',
                )
              : _filteredProducts.isEmpty
                  ? SingleChildScrollView(
                      child: ProfessionalComponents.createEmptyState(
                        title: 'Ürün Bulunamadı',
                        message: 'Seçilen kriterlere uygun ürün bulunamadı.',
                        icon: Icons.search_off,
                        buttonText: 'Filtreleri Temizle',
                        onButtonPressed: _clearFilters,
                      ),
                    )
                  : _buildProductGrid(isSmallScreen, isTablet, isDesktop),
        ),
      ],
    );
  }


  Widget _buildFilters(bool isSmallScreen, bool isTablet, double maxWidth) {
    final isDesktop = maxWidth >= 1024;
    
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : isTablet ? 14 : isDesktop ? 20 : 16),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtreler',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: isSmallScreen ? 16 : isDesktop ? 20 : 18,
                  color: const Color(0xFF0F0F0F),
                ),
              ),
              TextButton.icon(
                onPressed: _clearFilters,
                icon: Icon(Icons.refresh, size: isDesktop ? 20 : 18),
                label: Text(
                  'Temizle',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 12 : isDesktop ? 14 : 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF6000),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Sıralama
          Text(
            'Sırala:',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : isDesktop ? 15 : 14,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _sortBy,
            isDense: true,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFFF6000), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 12 : isDesktop ? 18 : 16,
                vertical: isSmallScreen ? 10 : isDesktop ? 14 : 12,
              ),
              filled: true,
              fillColor: const Color(0xFFFAFBFC),
            ),
            items: _sortOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option,
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 13 : isDesktop ? 15 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (!mounted || value == null) return;
              setState(() {
                _sortBy = value;
                _filterProducts();
              });
            },
          ),
          
          const SizedBox(height: 20),
          
          // Fiyat aralığı
          Text(
            'Fiyat Aralığı',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: isSmallScreen ? 13 : isDesktop ? 15 : 14,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : isDesktop ? 14 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    '${_minPrice.toInt()}₺',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : isDesktop ? 15 : 14,
                      color: const Color(0xFF0F0F0F),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 12),
                child: Text(
                  '-',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6A6A6A),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : isDesktop ? 14 : 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFBFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE8E8E8)),
                  ),
                  child: Text(
                    '${_maxPrice.toInt()}₺',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: isSmallScreen ? 12 : isDesktop ? 15 : 14,
                      color: const Color(0xFF0F0F0F),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: 10000,
            divisions: 100,
            activeColor: const Color(0xFFFF6000),
            inactiveColor: const Color(0xFFE8E8E8),
            labels: RangeLabels(
              '${_minPrice.toInt()}₺',
              '${_maxPrice.toInt()}₺',
            ),
            onChanged: (values) {
              if (!mounted) return;
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
                _filterProducts();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(bool isSmallScreen, bool isTablet, bool isDesktop) {
    final crossAxisCount = ResponsiveHelper.responsiveProductGridColumns(context);
    final bool veryNarrow = ResponsiveHelper.screenWidth(context) < 360;
    
    // Responsive aspect ratio - Container yeterince büyük (overflow önleme)
    // Filtreleme paneli varsa daha küçük, yoksa daha büyük
    final hasFilterPanel = ResponsiveHelper.screenWidth(context) >= 900;
    final double aspect = ResponsiveHelper.responsiveValue<double>(
      context,
      mobile: veryNarrow ? 0.68 : 0.73, // Daha büyük - overflow önleme
      tablet: hasFilterPanel ? 0.78 : 0.83, // Daha büyük - overflow önleme
      desktop: hasFilterPanel ? 0.83 : 0.88, // Daha büyük - overflow önleme
    );

    return GridView.builder(
      padding: ResponsiveHelper.responsivePadding(
        context,
        mobile: 12.0, // Üst-alt-sağ-sol boşluk
        tablet: 16.0,
        desktop: 24.0,
      ),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspect,
        crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(
          context,
          mobile: 10.0, // Kartlar arası yatay boşluk
          tablet: 14.0,
          desktop: 20.0,
        ),
        mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(
          context,
          mobile: 10.0, // Kartlar arası dikey boşluk
          tablet: 14.0,
          desktop: 20.0,
        ),
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product, isSmallScreen, isTablet);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSmallScreen, bool isTablet) {
    final isFavorite = widget.favoriteProducts.any((p) => p.id == product.id);
    final inCart = widget.cartProducts.any((p) => p.id == product.id);

    return GestureDetector(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ürün resmi - Dengeli yükseklik
            AspectRatio(
              aspectRatio: 1, // 1:1 - standart kare
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFBFC),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: OptimizedImage(
                          imageUrl: product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // İndirim badge - Dengeli
                    if (product.discountPercentage > 0)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '%${product.discountPercentage.toStringAsFixed(0)}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    // Favori butonu - Dengeli
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
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFF6A6A6A),
                            size: ResponsiveHelper.responsiveIconSize(
                              context,
                              mobile: 16.0,
                              desktop: 18.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Ürün bilgileri - Optimize padding (overflow önleme)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveHelper.responsiveSpacing(context, mobile: 10.0, desktop: 14.0),
                vertical: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ürün adı - Optimize yükseklik
                  SizedBox(
                    height: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 34.0, // Optimize
                      tablet: 38.0,
                      desktop: 42.0,
                    ),
                    child: Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          mobile: 13.0,
                          tablet: 14.0,
                          desktop: 15.0,
                        ),
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF0F0F0F),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 5.0, desktop: 7.0)),
                  
                  // Fiyat - Optimize
                  Text(
                    '${product.price.toStringAsFixed(2)} ₺',
                    style: GoogleFonts.inter(
                      fontSize: ResponsiveHelper.responsiveFontSize(
                        context,
                        mobile: 15.0,
                        tablet: 16.0,
                        desktop: 17.0,
                      ),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F0F0F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 5.0, desktop: 7.0)),
                  
                  // Sepete ekle butonu - Optimize boyut
                  SizedBox(
                    width: double.infinity,
                    height: ResponsiveHelper.responsiveValue(
                      context,
                      mobile: 34.0, // Optimize
                      tablet: 36.0,
                      desktop: 38.0,
                    ),
                    child: ElevatedButton(
                      onPressed: () => widget.onAddToCart(product),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: inCart 
                            ? const Color(0xFF10B981) 
                            : const Color(0xFFFF6000),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0),
                          vertical: ResponsiveHelper.responsiveSpacing(context, mobile: 6.0, desktop: 8.0),
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            inCart ? Icons.check : Icons.shopping_cart,
                            size: ResponsiveHelper.responsiveIconSize(
                              context,
                              mobile: 16.0, // Biraz büyük icon
                              desktop: 18.0,
                            ),
                            color: Colors.white,
                          ),
                          SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 5.0, desktop: 7.0)),
                          Flexible(
                            child: Text(
                              inCart ? 'Sepette' : 'Sepete Ekle',
                              style: GoogleFonts.inter(
                                fontSize: ResponsiveHelper.responsiveFontSize(
                                  context,
                                  mobile: 13.0, // Biraz büyük font
                                  tablet: 13.5,
                                  desktop: 14.0,
                                ),
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    if (!mounted) return;
    setState(() {
      _selectedCategory = 'Tümü';
      _sortBy = 'Popülerlik';
      _minPrice = 0;
      _maxPrice = 10000;
      _filterProducts();
    });
  }
}

