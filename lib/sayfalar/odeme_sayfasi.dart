import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/product.dart';
import '../services/user_auth_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/firebase_data_service.dart';
import '../widgets/error_handler.dart';
import '../config/app_routes.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';

class OdemeSayfasi extends StatefulWidget {
  final List<Product> cartProducts;
  final String appliedCoupon;
  final double couponDiscount;
  final bool isCouponApplied;
  final String? orderId;

  const OdemeSayfasi({
    super.key,
    required this.cartProducts,
    this.appliedCoupon = '',
    this.couponDiscount = 0.0,
    this.isCouponApplied = false,
    this.orderId,
  });

  @override
  State<OdemeSayfasi> createState() => _OdemeSayfasiState();
}

class _OdemeSayfasiState extends State<OdemeSayfasi> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String _selectedPaymentMethod = 'credit_card';
  String _selectedDeliveryMethod = 'address'; // 'address' veya 'pickup'
  String _selectedInstallment = '1'; // Taksit seçeneği
  bool _isLoading = false;
  bool _showCardForm = false;
  bool _isGuestUser = true; // Misafir kullanıcı kontrolü
  bool _sameAddressForInvoice = true; // Fatura adresi aynı mı
  bool _use3DSecure = false; // 3D Secure kullan
  bool _agreeToTerms = false; // Şartları onayla
  
  // Kupon sistemi
  String _appliedCoupon = '';
  double _couponDiscount = 0.0;
  bool _isCouponApplied = false;
  
  // Çark ödülleri kaldırıldı
  // Seçilen kayıtlı adres ve kart
  Adres? _selectedSavedAddress;
  OdemeYontemi? _selectedSavedCard;
  
  // Ödeme servisi
  final PaymentService _paymentService = PaymentService();
  
  // Firebase Data Service
  final FirebaseDataService _firebaseDataService = FirebaseDataService();
  
  // Kredi kartı bilgileri
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _couponController = TextEditingController();
  final _notesController = TextEditingController();
  

  @override
  void initState() {
    super.initState();
    _nameController.text = '';
    _emailController.text = '';
    _phoneController.text = '';
    _addressController.text = '';
    _postalCodeController.text = '';
    _checkUserLoginStatus();
    _loadUserData();
    _loadSavedAddresses();
    _loadSavedPaymentMethods();
    // Çark ödülleri kaldırıldı
    
    // Sepet sayfasından gelen kupon bilgilerini ayarla
    _appliedCoupon = widget.appliedCoupon;
    _couponDiscount = widget.couponDiscount;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _couponController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Kullanıcı giriş durumunu kontrol et
  void _checkUserLoginStatus() {
    final userAuthService = UserAuthService();
    setState(() {
      _isGuestUser = userAuthService.getCurrentUser() == null;
    });
  }

  // Kayıtlı adresleri Firebase'den yükle
  Future<void> _loadSavedAddresses() async {
    if (!_isGuestUser) {
      try {
        final addresses = await _firebaseDataService.getAddresses();
        if (addresses.isNotEmpty && mounted) {
          // Varsayılan adresi bul veya ilk adresi seç
          final defaultAddress = addresses.firstWhere(
            (addr) => addr['isDefault'] == true,
            orElse: () => addresses.first,
          );
          
          setState(() {
            _selectedSavedAddress = Adres(
              id: defaultAddress['id'] ?? '',
              title: defaultAddress['title'] ?? 'Ev',
              fullName: defaultAddress['fullName'] ?? '',
              phone: defaultAddress['phone'] ?? '',
              address: defaultAddress['address'] ?? '',
              city: defaultAddress['city'] ?? '',
              district: defaultAddress['district'] ?? '',
              postalCode: defaultAddress['postalCode'] ?? '',
              isDefault: defaultAddress['isDefault'] ?? false,
            );
            
            // Form alanlarını doldur
            _nameController.text = _selectedSavedAddress!.fullName;
            _phoneController.text = _selectedSavedAddress!.phone;
            _addressController.text = _selectedSavedAddress!.address;
            _cityController.text = _selectedSavedAddress!.city;
            _districtController.text = _selectedSavedAddress!.district;
            _postalCodeController.text = _selectedSavedAddress!.postalCode;
          });
        }
      } catch (e) {
        debugPrint('Adresler Firebase\'den yüklenirken hata: $e');
      }
    }
  }

  // Kullanıcı bilgilerini Firebase'den otomatik doldur
  Future<void> _loadUserData() async {
    if (!_isGuestUser) {
      try {
        // Önce FirebaseAuth'tan temel bilgileri al
        final userAuthService = UserAuthService();
        final user = userAuthService.getCurrentUser();
        
        if (user != null) {
          // Firebase Firestore'dan detaylı profil bilgilerini çek
          final userProfile = await _firebaseDataService.getUserProfile();
          
          if (mounted) {
            setState(() {
              // Ad Soyad - önce Firestore'dan, yoksa FirebaseAuth'tan
              _nameController.text = userProfile?['fullName']?.toString().trim() ?? 
                                    user.displayName?.trim() ?? '';
              
              // E-posta - önce Firestore'dan, yoksa FirebaseAuth'tan
              _emailController.text = userProfile?['email']?.toString().trim() ?? 
                                     user.email?.trim() ?? '';
              
              // Telefon - Firestore'dan
              _phoneController.text = userProfile?['phone']?.toString().trim() ?? '';
              
              // Adres - Firestore'dan (varsa)
              final address = userProfile?['address']?.toString().trim() ?? '';
              if (address.isNotEmpty) {
                _addressController.text = address;
              }
              
              // Şehir ve ilçe bilgileri varsa ayır (opsiyonel)
              // Adres formatı: "Adres, Şehir, İlçe" şeklinde olabilir
              if (address.contains(',')) {
                final parts = address.split(',');
                if (parts.length >= 2) {
                  _cityController.text = parts[parts.length - 2].trim();
                  if (parts.length >= 3) {
                    _districtController.text = parts[parts.length - 3].trim();
                  }
                }
              }
            });
          }
        }
      } catch (e) {
        debugPrint('Kullanıcı bilgileri Firebase\'den yüklenirken hata: $e');
        // Hata durumunda en azından FirebaseAuth bilgilerini kullan
        try {
          final userAuthService = UserAuthService();
          final user = userAuthService.getCurrentUser();
          if (user != null && mounted) {
            setState(() {
              _nameController.text = user.displayName ?? '';
              _emailController.text = user.email ?? '';
            });
          }
        } catch (e2) {
          debugPrint('FirebaseAuth bilgileri yüklenirken hata: $e2');
        }
      }
    }
  }
  
  void _applyCoupon() {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen kupon kodunu girin')),
      );
      return;
    }
    
    // Çark kupon sistemi kaldırıldı
    
    // Manuel kupon kodlarını kontrol et
    switch (couponCode.toUpperCase()) {
      case 'DISCOUNT5':
        setState(() {
          _appliedCoupon = 'DISCOUNT5';
          _couponDiscount = 0.05; // %5 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %5 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT10':
        setState(() {
          _appliedCoupon = 'DISCOUNT10';
          _couponDiscount = 0.10; // %10 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %10 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT15':
        setState(() {
          _appliedCoupon = 'DISCOUNT15';
          _couponDiscount = 0.15; // %15 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %15 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT20':
        setState(() {
          _appliedCoupon = 'DISCOUNT20';
          _couponDiscount = 0.20; // %20 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %20 İndirim kuponu uygulandı!')),
        );
        break;
      case 'DISCOUNT25':
        setState(() {
          _appliedCoupon = 'DISCOUNT25';
          _couponDiscount = 0.25; // %25 indirim
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 %25 İndirim kuponu uygulandı!')),
        );
        break;
      case 'FREESHIP':
        setState(() {
          _appliedCoupon = 'FREESHIP';
          _couponDiscount = 0.0; // Ücretsiz kargo
          _isCouponApplied = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Ücretsiz kargo kuponu uygulandı!')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('❌ Geçersiz kupon kodu')),
        );
    }
  }
  
  void _removeCoupon() {
    setState(() {
      _appliedCoupon = '';
      _couponDiscount = 0.0;
      _isCouponApplied = false;
      _couponController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kupon kaldırıldı')),
    );
  }
  
  // Çark ödülleri metodları kaldırıldı

  // Kayıtlı ödeme yöntemlerini yükle
  // Kayıtlı ödeme yöntemlerini Firebase'den yükle
  Future<void> _loadSavedPaymentMethods() async {
    if (!_isGuestUser) {
      try {
        final paymentMethods = await _firebaseDataService.getPaymentMethods();
        if (paymentMethods.isNotEmpty && mounted) {
          // Varsayılan ödeme yöntemini bul veya ilk ödeme yöntemini seç
          final defaultPaymentMethod = paymentMethods.firstWhere(
            (pm) => pm['isDefault'] == true,
            orElse: () => paymentMethods.first,
          );
          
          // Kart numarasını maskele (son 4 haneyi göster)
          final cardNumber = defaultPaymentMethod['cardNumber'] ?? '';
          final maskedNumber = cardNumber.length > 4 
              ? '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}'
              : '**** **** **** ****';
          
          setState(() {
            _selectedSavedCard = OdemeYontemi(
              id: defaultPaymentMethod['id'] ?? '',
              type: 'card', // Varsayılan olarak kart
              name: defaultPaymentMethod['name'] ?? 'Kart',
              number: maskedNumber,
              expiryDate: defaultPaymentMethod['expiryDate'] ?? '',
              isDefault: defaultPaymentMethod['isDefault'] ?? false,
            );
          });
        }
      } catch (e) {
        debugPrint('Ödeme yöntemleri Firebase\'den yüklenirken hata: $e');
      }
    }
  }


  double get _subtotal => widget.cartProducts.fold(0.0, (sum, product) => sum + product.totalPrice);
  double _shippingCost = 44.99; // Trendyol tarzı kargo ücreti
  double get _couponDiscountAmount => _subtotal * _couponDiscount;
  double get _finalShippingCost {
    // 100 TL üzeri ücretsiz kargo veya kupon ile ücretsiz kargo
    if (_subtotal >= 100 || _appliedCoupon == 'FREESHIP') {
      return 0.0;
    }
    return _shippingCost;
  }
  double get _total => _subtotal - _couponDiscountAmount + _finalShippingCost;


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFFAFBFC),
      appBar: AppBar(
        title: Text(
          'Ödeme',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F0F0F),
        elevation: 0,
        shadowColor: Colors.black.withOpacity(0.05),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : isDesktop
            ? _buildDesktopLayout()
            : _buildMobileLayout(),
    );
  }
  
  // Desktop layout: Sol form, sağ sidebar özet
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sol taraf - Form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sepetimdeki Ürünler başlığı
                  _buildCartProductsHeader(),
                  const SizedBox(height: 24),
                  
                  // Teslimat Adresi
                  _buildDeliveryAddressSection(),
                  const SizedBox(height: 24),
                  
                  // Ödeme Seçenekleri
                  _buildPaymentOptionsSection(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        // Sağ taraf - Sipariş Özeti (Sabit sidebar)
        Container(
          width: 400,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(
                color: const Color(0xFFE8E8E8),
                width: 1,
              ),
            ),
          ),
          child: _buildOrderSummarySidebar(),
        ),
      ],
    );
  }
  
  // Mobil layout: Üst form, alt özet
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sepetimdeki Ürünler başlığı
            _buildCartProductsHeader(),
            const SizedBox(height: 16),
            
            // Teslimat Adresi
            _buildDeliveryAddressSection(),
            const SizedBox(height: 16),
            
            // Ödeme Seçenekleri
            _buildPaymentOptionsSection(),
            const SizedBox(height: 16),
            
            // Sipariş Özeti
            _buildOrderSummarySidebar(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCartProductsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Sepetimdeki Ürünler (${widget.cartProducts.length})',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
          ),
        ),
        // Dil seçici ikonu (opsiyonel)
        IconButton(
          icon: const Icon(Icons.language, size: 20),
          onPressed: () {},
          color: const Color(0xFF6A6A6A),
        ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kredi Kartı Bilgileri',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (!_isGuestUser)
                  TextButton.icon(
                    onPressed: _showSaveCardDialog,
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Kart Kaydet'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                    ),
                  ),
              ],
                  ),
                  const SizedBox(height: 16),
            
                  TextFormField(
              controller: _cardNameController,
                    decoration: InputDecoration(
                labelText: 'Kart Üzerindeki İsim',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
              validator: (value) => value?.isEmpty == true ? 'Kart üzerindeki isim gerekli' : null,
                  ),
            
                  const SizedBox(height: 16),
            
                  TextFormField(
              controller: _cardNumberController,
                    decoration: InputDecoration(
                labelText: 'Kart Numarası',
                hintText: '1234 5678 9012 3456',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
              keyboardType: TextInputType.number,
              validator: (value) => value?.isEmpty == true ? 'Kart numarası gerekli' : null,
                  ),
            
                  const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: 'Son Kullanma Tarihi',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'Son kullanma tarihi gerekli' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) => value?.isEmpty == true ? 'CVV gerekli' : null,
                            ),
                          ),
                        ],
            ),
          ],
        ),
      ),
    );
  }


  // Ödeme butonu davranışı
  Future<void> _onPayPressed() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPaymentMethod == 'credit_card') {
      if (_isGuestUser || (_selectedSavedCard == null && !_showCardForm)) {
        // Kart formunu göster
        setState(() {
          _showCardForm = true;
        });
        if (_cardNumberController.text.isEmpty ||
            _cardNameController.text.isEmpty ||
            _expiryController.text.isEmpty ||
            _cvvController.text.isEmpty) {
          ErrorHandler.showError(context, 'Lütfen kart bilgilerini doldurun');
          return;
        }
      }
    }

    if (_selectedSavedAddress == null && _addressController.text.trim().isEmpty) {
      ErrorHandler.showError(context, 'Lütfen teslimat adresini doldurun veya seçin');
      return;
    }

    await _processPayment();
  }

  void _showSaveCardDialog() {
    if (_isGuestUser) {
      _showGuestUserDialog();
      return;
    }

    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();

    final parentContext = context;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kart Kaydet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Kart Üzerindeki İsim',
                    border: OutlineInputBorder(),
                  ),
                ),
              const SizedBox(height: 16),
                TextField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Kart Numarası',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  textCapitalization: TextCapitalization.none,
                ),
              const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: expiryController,
                        decoration: const InputDecoration(
                        labelText: 'Son Kullanma',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                  const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: cvvController,
                        decoration: const InputDecoration(
                          labelText: 'CVV',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        textCapitalization: TextCapitalization.none,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Kart bilgilerini kaydet
                if (nameController.text.isNotEmpty && 
                    numberController.text.isNotEmpty && 
                    expiryController.text.isNotEmpty && 
                    cvvController.text.isNotEmpty) {
                  
                  // Firestore'a kaydet
                  try {
                    await _firebaseDataService.savePaymentMethod(
                      name: nameController.text.trim(),
                      cardNumber: numberController.text.trim(),
                      expiryDate: expiryController.text.trim(),
                      cvv: cvvController.text.trim(),
                      isDefault: false, // İlk kart varsayılan olabilir
                    );
                    
                    // Mevcut form alanlarını doldur
                    _cardNameController.text = nameController.text;
                    _cardNumberController.text = numberController.text;
                    _expiryController.text = expiryController.text;
                    _cvvController.text = cvvController.text;
                    
                    Navigator.of(context).pop();
                    
                    // Dialog context deaktive olacağı için parent context ile göster
                    Future.microtask(() {
                      if (mounted) {
                        ErrorHandler.showSuccess(parentContext, 'Kart başarıyla kaydedildi!');
                        // Ödeme yöntemlerini yeniden yükle
                        _loadSavedPaymentMethods();
                      }
                    });
                  } catch (e) {
                    Navigator.of(context).pop();
                    Future.microtask(() {
                      if (mounted) {
                        ErrorHandler.showError(parentContext, 'Kart kaydedilirken hata oluştu: ${e.toString()}');
                      }
                    });
                  }
                } else {
                  ErrorHandler.showError(parentContext, 'Lütfen tüm alanları doldurun');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Kaydet'),
            ),
          ],
      ),
    );
  }

  void _showGuestUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kayıt Gerekli'),
        content: const Text(
          'Gelişmiş özellikleri kullanmak ve sipariş vermek için kayıt olmanız gerekiyor. '
          'Kayıt olmak ister misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppRoutes.navigateToRegister(context).then((_) => _checkUserLoginStatus());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('Kayıt Ol'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final orderService = OrderService();
      final totalAmount = _total; // Kupon indirimini de içeren toplam

      // Gelişmiş stok kontrolü - Firebase'den güncel stok bilgisini al
      for (final product in widget.cartProducts) {
        try {
          // Güncel stok bilgisini al (offline desteği için Source.server kaldırıldı)
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(product.id)
              .get();
          
          if (productDoc.exists) {
            final currentStock = (productDoc.data()?['stock'] ?? 0) as int;
            if (product.quantity > currentStock) {
              if (mounted) {
                ErrorHandler.showError(
                  context, 
                  '${product.name} için yeterli stok yok. Mevcut stok: $currentStock, İstediğiniz: ${product.quantity}'
                );
              }
              return; // finally bloğu loading'i kapatacak
            }
          } else {
            if (mounted) {
              ErrorHandler.showError(context, '${product.name} ürünü bulunamadı');
            }
            return; // finally bloğu loading'i kapatacak
          }
        } catch (e) {
          debugPrint('Stok kontrolü hatası: $e');
          // Hata durumunda kullanıcıya bilgi ver ve işlemi durdur
          if (mounted) {
            ErrorHandler.showError(context, 'Stok kontrolü yapılamadı. Lütfen tekrar deneyin.');
          }
          return; // finally bloğu loading'i kapatacak
        }
      }

      PaymentResult paymentResult;

      // Ödeme yöntemine göre işlem
      debugPrint('=== ÖDEME İŞLEMİ BAŞLIYOR ===');
      debugPrint('Seçilen ödeme yöntemi: $_selectedPaymentMethod');
      debugPrint('Toplam tutar: $totalAmount');
      
      if (_selectedPaymentMethod == 'credit_card') {
        if (_selectedSavedCard != null) {
          // Kayıtlı kart ile ödeme
          paymentResult = await _paymentService.processCardPayment(
            cardNumber: _selectedSavedCard!.number,
            cardHolderName: _selectedSavedCard!.name,
            expiryDate: _selectedSavedCard!.expiryDate,
            cvv: '***',
            amount: totalAmount,
            description: 'Sipariş ödemesi - ${widget.cartProducts.length} ürün',
          );
        } else if (_cardNumberController.text.isNotEmpty) {
          // Yeni kart ile ödeme
          paymentResult = await _paymentService.processCardPayment(
            cardNumber: _cardNumberController.text,
            cardHolderName: _cardNameController.text,
            expiryDate: _expiryController.text,
            cvv: _cvvController.text,
            amount: totalAmount,
            description: 'Sipariş ödemesi - ${widget.cartProducts.length} ürün',
          );
        } else {
          ErrorHandler.showError(context, 'Lütfen kart bilgilerini girin');
          return; // finally bloğu loading'i kapatacak
        }

        if (!paymentResult.success) {
          if (mounted) {
            ErrorHandler.showError(context, paymentResult.message);
          }
          return; // finally bloğu loading'i kapatacak
        }
      } else if (_selectedPaymentMethod == 'cash_on_delivery') {
        paymentResult = PaymentResult(
          success: true,
          paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
          message: 'Kapıda ödeme kaydı oluşturuldu',
        );
      } else if (_selectedPaymentMethod == 'bank_transfer') {
        paymentResult = PaymentResult(
          success: true,
          paymentId: DateTime.now().millisecondsSinceEpoch.toString(),
          message: 'Banka havalesi kaydı oluşturuldu',
        );
      } else {
        debugPrint('✗ Geçersiz ödeme yöntemi: $_selectedPaymentMethod');
        paymentResult = PaymentResult(
          success: false,
          message: 'Geçersiz ödeme yöntemi: $_selectedPaymentMethod',
        );
      }
      
      debugPrint('Ödeme sonucu: ${paymentResult.success ? "Başarılı" : "Başarısız"}');
      debugPrint('Ödeme mesajı: ${paymentResult.message}');

      // Ödeme başarılı ise siparişi oluştur
      if (paymentResult.success && paymentResult.paymentId != null) {
        String fullAddress = _addressController.text.trim();
        if (_cityController.text.trim().isNotEmpty) {
          fullAddress += ', ${_cityController.text.trim()}';
        }
        if (_districtController.text.trim().isNotEmpty) {
          fullAddress += ', ${_districtController.text.trim()}';
        }
        if (_postalCodeController.text.trim().isNotEmpty) {
          fullAddress += ' - ${_postalCodeController.text.trim()}';
        }

        final orderId = await orderService.createOrder(
          products: widget.cartProducts,
          totalAmount: totalAmount,
          customerName: _nameController.text,
          customerEmail: _emailController.text,
          customerPhone: _phoneController.text,
          shippingAddress: fullAddress.isNotEmpty ? fullAddress : _addressController.text,
          paymentMethod: _getPaymentMethodName(_selectedPaymentMethod),
          notes: _notesController.text.isNotEmpty 
              ? '${_notesController.text}${_appliedCoupon.isNotEmpty ? ' | Kupon: $_appliedCoupon' : ''}'
              : (_appliedCoupon.isNotEmpty ? 'Kupon: $_appliedCoupon' : ''),
        );

        // Ödeme kaydını sipariş ile ilişkilendir
        if (orderId.isNotEmpty && paymentResult.paymentId != null) {
          await _paymentService.processPayment(
            paymentData: {'method': _selectedPaymentMethod},
            amount: totalAmount,
            description: 'Sipariş #$orderId',
            orderId: orderId,
          );
        }

        // Sipariş bilgilerini al
        final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
        final orderNumber = orderDoc.data()?['orderNumber'] as String? ?? orderId;

        // Sepeti temizle - sipariş başarıyla oluşturulduktan sonra
        try {
          final firebaseDataService = FirebaseDataService();
          for (final product in widget.cartProducts) {
            await firebaseDataService.removeFromCart(product.id);
          }
          debugPrint('✅ Sepet başarıyla temizlendi');
        } catch (e) {
          debugPrint('⚠️ Sepet temizleme hatası: $e');
          // Hata olsa bile devam et
        }

        if (mounted) {
          // Profesyonel sipariş onay sayfasına yönlendir
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.orderConfirmation,
            arguments: {
              'orderId': orderId,
              'orderNumber': orderNumber,
              'products': widget.cartProducts,
              'totalAmount': totalAmount,
              'paymentMethod': _getPaymentMethodName(_selectedPaymentMethod),
              'customerName': _nameController.text,
              'customerEmail': _emailController.text,
              'shippingAddress': fullAddress.isNotEmpty ? fullAddress : _addressController.text,
              'paymentId': paymentResult.paymentId,
            },
          );
        }
      } else {
        if (mounted) {
          ErrorHandler.showError(context, paymentResult.message);
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, 'Ödeme işlemi sırasında hata oluştu: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPaymentMethodName(String method) {
    switch (method) {
      case 'credit_card':
        return 'Kredi Kartı';
      case 'cash_on_delivery':
        return 'Kapıda Ödeme';
      case 'bank_transfer':
        return 'Banka Havalesi';
      default:
        return 'Bilinmeyen';
    }
  }
  
  // Trendyol tarzı Teslimat Adresi bölümü
  Widget _buildDeliveryAddressSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Teslimat Adresi',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const SizedBox(height: 20),
          
          // Adrese Teslim Edilsin
          RadioListTile<String>(
            title: Text(
              'Adrese Teslim Edilsin',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            value: 'address',
            groupValue: _selectedDeliveryMethod,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryMethod = value!;
              });
            },
            activeColor: const Color(0xFFFF6000),
            contentPadding: EdgeInsets.zero,
          ),
          
          if (_selectedDeliveryMethod == 'address') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      hintText: 'Teslimat Adresi',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE8E8E8)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFBFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!_isGuestUser) {
                      final selected = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdresYonetimiSayfasi(selectMode: true),
                        ),
                      );
                      if (selected != null && mounted) {
                        setState(() {
                          _selectedSavedAddress = selected as Adres;
                          _addressController.text = _selectedSavedAddress!.address;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(
                    'Adres Ekle/Değiştir',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFFFF6000),
                    side: const BorderSide(color: Color(0xFFFF6000)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: Text(
                'Faturamı Aynı Adrese Gönder',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              value: _sameAddressForInvoice,
              onChanged: (value) {
                setState(() {
                  _sameAddressForInvoice = value ?? false;
                });
              },
              activeColor: const Color(0xFFFF6000),
              contentPadding: EdgeInsets.zero,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Gel Al Noktası
          RadioListTile<String>(
            title: Row(
              children: [
                Text(
                  'Gel Al Noktası',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    // "Nedir?" açıklama göster
                  },
                  child: Text(
                    'Nedir?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFFF6000),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Sana en yakın noktadan güvenle al!',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6A6A6A),
              ),
            ),
            value: 'pickup',
            groupValue: _selectedDeliveryMethod,
            onChanged: (value) {
              setState(() {
                _selectedDeliveryMethod = value!;
              });
            },
            activeColor: const Color(0xFFFF6000),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
  
  // Trendyol tarzı Ödeme Seçenekleri bölümü
  Widget _buildPaymentOptionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ödeme Seçenekleri',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F0F0F),
            ),
          ),
          const SizedBox(height: 20),
          
          // Kart ile Öde
          RadioListTile<String>(
            title: Text(
              'Kart ile Öde',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Kart ile ödemeyi seçtiniz. Banka veya Kredi Kartı kullanarak ödemenizi güvenle yapabilirsiniz.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6A6A6A),
              ),
            ),
            value: 'credit_card',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
                if (!_isGuestUser && _selectedSavedCard == null) {
                  _showCardForm = true;
                }
              });
            },
            activeColor: const Color(0xFFFF6000),
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 12),
          
          // Kapıda Ödeme
          RadioListTile<String>(
            title: Text(
              'Kapıda Ödeme',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Teslimat sırasında nakit veya kredi kartı ile ödeme yapabilirsiniz.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6A6A6A),
              ),
            ),
            value: 'cash_on_delivery',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
                _showCardForm = false;
              });
            },
            activeColor: const Color(0xFFFF6000),
            contentPadding: EdgeInsets.zero,
          ),
          
          const SizedBox(height: 12),
          
          // Banka Havalesi
          RadioListTile<String>(
            title: Text(
              'Banka Havalesi',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Banka hesabımıza havale/EFT yaparak ödeme yapabilirsiniz. Manuel onay gereklidir.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF6A6A6A),
              ),
            ),
            value: 'bank_transfer',
            groupValue: _selectedPaymentMethod,
            onChanged: (value) {
              setState(() {
                _selectedPaymentMethod = value!;
                _showCardForm = false;
              });
            },
            activeColor: const Color(0xFFFF6000),
            contentPadding: EdgeInsets.zero,
          ),
          
          if (_selectedPaymentMethod == 'credit_card') ...[
            const SizedBox(height: 16),
            
            // Kart Bilgileri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kart Bilgileri',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    if (!_isGuestUser) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OdemeYontemleriSayfasi(selectMode: true),
                        ),
                      ).then((selected) {
                        if (selected != null && mounted) {
                          setState(() {
                            _selectedSavedCard = selected as OdemeYontemi;
                          });
                        }
                      });
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    'Kart Ekle/Değiştir',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF6000),
                  ),
                ),
              ],
            ),
            
            if (_selectedSavedCard != null) ...[
              const SizedBox(height: 12),
              _buildSavedCardDisplay(),
            ] else if (_showCardForm) ...[
              const SizedBox(height: 12),
              _buildCreditCardForm(),
            ],
            
            const SizedBox(height: 16),
            
            // 3D Secure checkbox
            CheckboxListTile(
              title: Text(
                '3D Secure ile ödemek istiyorum.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              value: _use3DSecure,
              onChanged: (value) {
                setState(() {
                  _use3DSecure = value ?? false;
                });
              },
              activeColor: const Color(0xFFFF6000),
              contentPadding: EdgeInsets.zero,
            ),
            
            const SizedBox(height: 20),
            
            // Taksit Seçenekleri
            Text(
              'Taksit Seçenekleri',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildInstallmentOptions(),
          ],
          
          // Banka Havalesi bilgileri
          if (_selectedPaymentMethod == 'bank_transfer') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE8E8E8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Banka Havalesi Bilgileri',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F0F0F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Aşağıdaki hesap bilgilerine ödemenizi yapabilirsiniz:',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF6A6A6A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE8E8E8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Banka: Türkiye İş Bankası',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0F0F0F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hesap Adı: Tuning Store',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0F0F0F),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'IBAN: TR12 0006 4000 0011 2345 6789 01',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0F0F0F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tutar: ${_total.toStringAsFixed(2)} TL',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFF0F0F0F),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ödeme yaptıktan sonra dekontu WhatsApp hattımıza gönderebilirsiniz.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF6A6A6A),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSavedCardDisplay() {
    if (_selectedSavedCard == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Row(
        children: [
          // Kart logosu (örnek)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6000),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.credit_card, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSavedCard!.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_selectedSavedCard!.number.substring(0, 4)} ${_selectedSavedCard!.number.substring(4, 6)}******${_selectedSavedCard!.number.substring(_selectedSavedCard!.number.length - 4)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF6A6A6A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _selectedSavedCard!.expiryDate,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OdemeYontemleriSayfasi(selectMode: true),
                ),
              ).then((selected) {
                if (selected != null && mounted) {
                  setState(() {
                    _selectedSavedCard = selected as OdemeYontemi;
                  });
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF6000),
              side: const BorderSide(color: Color(0xFFFF6000)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Değiştir',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstallmentOptions() {
    final installmentOptions = [
      {'months': 1, 'label': 'Tek Çekim'},
      {'months': 2, 'label': '2 Taksit'},
      {'months': 3, 'label': '3 Taksit'},
      {'months': 4, 'label': '4 Taksit'},
      {'months': 6, 'label': '6 Taksit'},
      {'months': 8, 'label': '8 Taksit'},
      {'months': 9, 'label': '9 Taksit'},
      {'months': 12, 'label': '12 Taksit'},
    ];
    
    return Column(
      children: installmentOptions.map((option) {
        final months = option['months'] as int;
        final label = option['label'] as String;
        final monthlyAmount = _total / months;
        
        return RadioListTile<String>(
          title: Text(
            label,
            style: GoogleFonts.inter(fontSize: 14),
          ),
          subtitle: months == 1
              ? Text(
                  '${_total.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F0F0F),
                  ),
                )
              : Text(
                  '$months x ${monthlyAmount.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
          value: months.toString(),
          groupValue: _selectedInstallment,
          onChanged: (value) {
            setState(() {
              _selectedInstallment = value!;
            });
          },
          activeColor: const Color(0xFFFF6000),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
  
  // Trendyol tarzı Sipariş Özeti sidebar
  Widget _buildOrderSummarySidebar() {
    final hasFreeShipping = _subtotal >= 100 || _finalShippingCost == 0;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sipariş Özeti',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    '+ Kurumsal Adres Ekle',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFFF6000),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Ara Toplam
            _buildSummaryRow('Ara Toplam', _subtotal.toStringAsFixed(2)),
            
            const SizedBox(height: 12),
            
            // Kargo Toplam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Kargo Toplam',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6A6A6A),
                  ),
                ),
                Text(
                  '${_finalShippingCost.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            
            if (hasFreeShipping) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kargo Bedava',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    '-${_shippingCost.toStringAsFixed(2)} TL',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.card_giftcard, color: const Color(0xFF10B981), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bu siparişinde ücretsiz kargo hakkı kullanılacaktır.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE8E8E8)),
            const SizedBox(height: 16),
            
            // Toplam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Toplam',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
                Text(
                  '${_total.toStringAsFixed(2)} TL',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F0F0F),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Ödeme Yap butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _agreeToTerms ? (_isLoading ? null : _onPayPressed) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _agreeToTerms && !_isLoading 
                      ? const Color(0xFFFF6000) 
                      : const Color(0xFFE8E8E8),
                  foregroundColor: _agreeToTerms && !_isLoading 
                      ? Colors.white 
                      : const Color(0xFF9CA3AF),
                  elevation: _agreeToTerms && !_isLoading ? 2 : 0,
                  shadowColor: _agreeToTerms && !_isLoading 
                      ? const Color(0xFFFF6000).withOpacity(0.3) 
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _agreeToTerms ? Colors.white : const Color(0xFF9CA3AF),
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Ödeme Yap',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: _agreeToTerms && !_isLoading 
                                ? Colors.white 
                                : const Color(0xFF9CA3AF),
                          ),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Onay checkbox
            CheckboxListTile(
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF6A6A6A),
                  ),
                  children: [
                    const TextSpan(text: "Ön Bilgilendirme Koşulları'nı ve "),
                    TextSpan(
                      text: 'Mesafeli Satış Sözleşmesi',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFF6000),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: "'ni okudum, onaylıyorum."),
                  ],
                ),
              ),
              value: _agreeToTerms,
              onChanged: (value) {
                setState(() {
                  _agreeToTerms = value ?? false;
                });
              },
              activeColor: const Color(0xFFFF6000),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF6A6A6A),
          ),
        ),
        Text(
          '$value TL',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
