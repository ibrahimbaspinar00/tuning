import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../model/order.dart';
import '../model/product.dart';
import '../services/order_service.dart';
import 'siparis_detay_sayfasi.dart';
import '../theme/app_design_system.dart';

class SiparislerSayfasi extends StatefulWidget {
  final List<Order> orders;
  final Function(List<Product>)? onOrderPlaced;

  const SiparislerSayfasi({
    super.key,
    this.orders = const [],
    this.onOrderPlaced,
  });

  @override
  State<SiparislerSayfasi> createState() => _SiparislerSayfasiState();
}

class _SiparislerSayfasiState extends State<SiparislerSayfasi> {
  String _selectedTab = 'Tümü'; // Trendyol tarzı tab
  String _searchQuery = '';
  String _selectedDateFilter = 'Tüm tarihler';
  List<Order> _orders = [];
  bool _isLoading = true;
  DateTime? _lastLoadTime;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her görünür olduğunda siparişleri yeniden yükle
    // Ancak çok sık yüklemeyi önlemek için son yüklemeden 2 saniye geçmiş olmalı
    final now = DateTime.now();
    if (!_isLoading && (_lastLoadTime == null || now.difference(_lastLoadTime!).inSeconds > 2)) {
      _loadOrders();
    }
  }
  
  Future<void> _loadOrders() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final orderService = OrderService();
      final userOrders = await orderService.getUserOrders();
      
      if (mounted) {
        setState(() {
          _orders = userOrders;
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
        debugPrint('Loaded ${_orders.length} orders from Firebase');
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _lastLoadTime = DateTime.now();
        });
      }
    }
  }
  
  List<Order> get _filteredOrders {
    // Önce widget.orders'ı kullan, eğer boşsa _orders'ı kullan
    var orders = widget.orders.isNotEmpty ? widget.orders : _orders;
    
    // Tab filtresi
    switch (_selectedTab) {
      case 'Devam Eden':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status != 'delivered' && 
                 status != 'teslim edildi' && 
                 status != 'cancelled' && 
                 status != 'iptal edildi' &&
                 status != 'returned' &&
                 status != 'iade edildi';
        }).toList();
        break;
      case 'İptal Edilen':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status == 'cancelled' || status == 'iptal edildi';
        }).toList();
        break;
      case 'İade Edilen':
        orders = orders.where((o) {
          final status = o.status.toLowerCase();
          return status == 'returned' || status == 'iade edildi';
        }).toList();
        break;
      case 'Tümü':
      default:
        // Tüm siparişler
        break;
    }
    
    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      orders = orders.where((order) {
        return order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               order.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Tarih sıralaması (en yeni önce) - Web'de güvenli
    try {
      orders.sort((a, b) {
        try {
          return b.orderDate.compareTo(a.orderDate);
        } catch (e) {
          // Sıralama hatası durumunda orijinal sırayı koru
          return 0;
        }
      });
    } catch (e) {
      debugPrint('Sıralama hatası (görmezden geliniyor): $e');
      // Sıralama başarısız olsa bile siparişleri döndür
    }
    
    return orders;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppDesignSystem.background,
      appBar: AppBar(
        backgroundColor: AppDesignSystem.surface,
        elevation: 0,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppDesignSystem.textPrimary,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 80 : 24,
            vertical: 16,
          ),
          child: Row(
            children: [
              // Sol tarafta başlık
              Text(
                'Siparişlerim',
                style: AppDesignSystem.heading2,
              ),
              const Spacer(),
              // Sağ tarafta arama ve tarih filtresi
              Row(
                children: [
                  // Arama çubuğu
                  Container(
                    width: 200,
                    height: 40,
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF0F0F0F),
                      ),
                      decoration: AppDesignSystem.inputDecoration(
                        label: '',
                        hint: 'Sipariş ara',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppDesignSystem.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tarih filtresi
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppDesignSystem.surfaceVariant,
                      borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                      border: Border.all(
                        color: AppDesignSystem.borderLight,
                        width: 1,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDateFilter,
                        style: AppDesignSystem.bodyMedium,
                        items: ['Tüm tarihler', 'Son 7 gün', 'Son 30 gün', 'Son 3 ay'].map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDateFilter = value!;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Trendyol tarzı tab'lar
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 80 : 24,
                vertical: 12,
              ),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton('Tümü'),
                    const SizedBox(width: 8),
                    _buildTabButton('Devam Eden'),
                    const SizedBox(width: 8),
                    _buildTabButton('İptal Edilen'),
                    const SizedBox(width: 8),
                    _buildTabButton('İade Edilen'),
                  ],
                ),
              ),
            ),
            // Sipariş listesi
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppDesignSystem.primary,
                      ),
                    )
                  : _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(AppDesignSystem.spacingL),
                                decoration: BoxDecoration(
                                  color: AppDesignSystem.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppDesignSystem.textTertiary,
                                ),
                              ),
                              const SizedBox(height: AppDesignSystem.spacingM),
                              Text(
                                (widget.orders.isEmpty && _orders.isEmpty)
                                    ? 'Henüz siparişiniz yok'
                                    : 'Bu kategoride sipariş bulunamadı',
                                style: AppDesignSystem.heading4,
                              ),
                              if (widget.orders.isEmpty && _orders.isEmpty) ...[
                                const SizedBox(height: AppDesignSystem.spacingS),
                                Text(
                                  'Ürünleri sepete ekleyip sipariş verin',
                                  style: AppDesignSystem.bodyMedium.copyWith(
                                    color: AppDesignSystem.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          color: AppDesignSystem.primary,
                          child: ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 80 : 24,
                              vertical: 16,
                            ),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildTrendyolOrderCard(order);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Trendyol tarzı tab butonu
  Widget _buildTabButton(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppDesignSystem.primary : AppDesignSystem.surface,
          borderRadius: BorderRadius.circular(AppDesignSystem.radiusRound),
          border: Border.all(
            color: isSelected ? AppDesignSystem.primary : AppDesignSystem.borderLight,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppDesignSystem.labelMedium.copyWith(
            color: isSelected ? AppDesignSystem.textOnPrimary : AppDesignSystem.textPrimary,
          ),
        ),
      ),
    );
  }

  // Trendyol tarzı sipariş kartı
  Widget _buildTrendyolOrderCard(Order order) {
    final deliveryCount = 1; // Demo: 1 teslimat
    final productCount = order.products.length;
    final isDelivered = order.status.toLowerCase() == 'delivered' || 
                       order.status.toLowerCase() == 'teslim edildi';
    final isCreated = order.status.toLowerCase() == 'pending' || 
                     order.status.toLowerCase() == 'beklemede';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDesignSystem.cardDecoration(
        borderRadius: AppDesignSystem.radiusM,
        shadows: AppDesignSystem.shadowS,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDesignSystem.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst kısım: Tarih, özet, alıcı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sipariş tarihi
                      Text(
                        _formatOrderDate(order.orderDate),
                        style: AppDesignSystem.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spacingS),
                      // Sipariş özeti
                      Text(
                        '$deliveryCount Teslimat, $productCount Ürün',
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppDesignSystem.spacingXS),
                      // Alıcı
                      Text(
                        'Alıcı: ${order.customerName}',
                        style: AppDesignSystem.bodySmall.copyWith(
                          color: AppDesignSystem.textSecondary,
                        ),
                      ),
                      if (order.totalAmount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Toplam: ${order.totalAmount.toStringAsFixed(2)} TL',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F0F0F),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Sağ tarafta ürün görselleri
                SizedBox(
                  width: 120,
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: order.products.length > 4 ? 4 : order.products.length,
                    itemBuilder: (context, index) {
                      final product = order.products[index];
                      return Container(
                        width: 60,
                        height: 60,
                        margin: const EdgeInsets.only(right: AppDesignSystem.spacingS),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                          border: Border.all(
                            color: AppDesignSystem.borderLight,
                            width: 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDesignSystem.radiusS - 1),
                          child: (product.imageUrl.isNotEmpty && product.imageUrl != '')
                              ? Image.network(
                                  product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(
                                    color: AppDesignSystem.surfaceVariant,
                                    child: Icon(
                                      Icons.image_not_supported, 
                                      color: AppDesignSystem.textTertiary,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : Container(
                                  color: AppDesignSystem.surfaceVariant,
                                  child: Icon(
                                    Icons.image,
                                    color: AppDesignSystem.textTertiary,
                                    size: 20,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Durum ve detaylar butonu
            Row(
              children: [
                // Durum kutusu
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignSystem.spacingM,
                    vertical: AppDesignSystem.spacingS,
                  ),
                  decoration: BoxDecoration(
                    color: isDelivered 
                        ? AppDesignSystem.successLight
                        : AppDesignSystem.infoLight,
                    borderRadius: BorderRadius.circular(AppDesignSystem.radiusS),
                    border: Border.all(
                      color: isDelivered 
                          ? AppDesignSystem.success
                          : AppDesignSystem.info,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDelivered ? Icons.check_circle : Icons.thumb_up,
                        size: 16,
                        color: isDelivered 
                            ? AppDesignSystem.success
                            : AppDesignSystem.info,
                      ),
                      const SizedBox(width: AppDesignSystem.spacingS),
                      Text(
                        isDelivered 
                            ? 'Teslim edildi'
                            : isCreated
                                ? 'Sipariş oluşturuldu'
                                : order.statusText,
                        style: AppDesignSystem.bodySmall.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDelivered 
                              ? AppDesignSystem.success
                              : AppDesignSystem.info,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppDesignSystem.spacingS),
                Text(
                  isDelivered 
                      ? '$productCount ürün teslim edildi'
                      : isCreated
                          ? '$productCount ürün için sipariş oluşturuldu'
                          : '',
                  style: AppDesignSystem.bodySmall.copyWith(
                    color: AppDesignSystem.textSecondary,
                  ),
                ),
                const Spacer(),
                // Detaylar butonu
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SiparisDetaySayfasi(order: order),
                      ),
                    );
                  },
                  style: AppDesignSystem.primaryButtonStyle(
                    padding: AppDesignSystem.spacingM,
                    borderRadius: AppDesignSystem.radiusS,
                  ),
                  child: Text(
                    'Detaylar',
                    style: AppDesignSystem.buttonSmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatOrderDate(DateTime date) {
    final months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

}
