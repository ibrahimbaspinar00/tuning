import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../providers/theme_provider.dart';
import '../services/firebase_data_service.dart';
import '../services/order_service.dart';
import '../services/external_image_upload_service.dart';
import '../config/external_image_storage_config.dart';
import 'adres_yonetimi_sayfasi.dart';
import 'odeme_yontemleri_sayfasi.dart';
import 'bildirim_ayarlari_sayfasi.dart';
import '../config/app_routes.dart';
import 'siparisler_sayfasi.dart';
import 'favoriler_sayfasi.dart';
import 'sepetim_sayfasi.dart';
import 'profil_duzenleme_sayfasi.dart';

class ProfilSayfasi extends StatefulWidget {
  final List<Product> favoriteProducts;
  final List<Product> cartProducts;
  final List<Order> orders;
  final Function(Product, {bool showMessage})? onFavoriteToggle;
  final Function(Product, {bool showMessage})? onAddToCart;
  final Function(Product)? onRemoveFromCart;
  final Function(Product, int)? onUpdateQuantity;
  final Function(List<Product>)? onPlaceOrder;
  final Function(List<Product>)? onOrderPlaced;
  
  const ProfilSayfasi({
    super.key,
    required this.favoriteProducts,
    required this.cartProducts,
    required this.orders,
    this.onFavoriteToggle,
    this.onAddToCart,
    this.onRemoveFromCart,
    this.onUpdateQuantity,
    this.onPlaceOrder,
    this.onOrderPlaced,
  });

  @override
  State<ProfilSayfasi> createState() => _ProfilSayfasiState();
}

class _ProfilSayfasiState extends State<ProfilSayfasi> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final FirebaseDataService _dataService = FirebaseDataService();
  
  String? _profileImageUrl;
  String? _fullName;
  String? _username;
  String? _email;
  String? _phone;
  String? _address;
  
  // İstatistik verileri
  Map<String, dynamic> _userStats = {};
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final userData = await _dataService.getUserProfile();
      final userStats = await _dataService.getUserStats();
      
      if (mounted) {
        setState(() {
          if (userData != null) {
            _fullName = userData['fullName'] ?? '';
            _username = userData['username'] ?? '';
            _email = userData['email'] ?? '';
            _phone = userData['phone'] ?? '';
            _address = userData['address'] ?? '';
            _profileImageUrl = userData['profileImageUrl'];
          }
          _userStats = userStats;
        });
      }
    } catch (e) {
      // Kullanıcı bilgileri yüklenirken hata
    }
  }
  
  Future<void> _pickProfileImage() async {
    try {
      // Web için özel kontrol
      if (kIsWeb) {
        // Web'de image picker kullan
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          await _processAndUploadImage(image);
        }
      } else {
        // Mobil platformlar için
        ImageSource? source;
        
        // Kullanıcıya seçenek sun (sadece mobilde)
        if (!kIsWeb) {
          source = await showModalBottomSheet<ImageSource>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Galeriden Seç'),
                    onTap: () => Navigator.pop(context, ImageSource.gallery),
                  ),
                  if (!kIsWeb)
                    ListTile(
                      leading: const Icon(Icons.camera_alt),
                      title: const Text('Kamera ile Çek'),
                      onTap: () => Navigator.pop(context, ImageSource.camera),
                    ),
                ],
              ),
            ),
          );
        } else {
          source = ImageSource.gallery;
        }
        
        if (source != null) {
          final XFile? image = await _picker.pickImage(
            source: source,
            maxWidth: 800,
            maxHeight: 800,
            imageQuality: 85,
          );
          
          if (image != null) {
            await _processAndUploadImage(image);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profil fotoğrafı yüklenirken hata: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  Future<void> _processAndUploadImage(XFile image) async {
    try {
      // Yükleme başladı mesajı
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Profil fotoğrafı yükleniyor...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }
      
      // Cloudinary (external) upload
      final String? downloadUrl = await _uploadProfileImage(image);
      
      if (downloadUrl != null) {
        // Kullanıcı profilini güncelle
        await _dataService.saveUserProfile(
          fullName: _fullName ?? '',
          username: _username ?? '',
          email: _email ?? '',
          phone: _phone,
          address: _address,
          profileImageUrl: downloadUrl,
        );
        
        if (mounted) {
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Profil fotoğrafı başarıyla güncellendi!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil fotoğrafı yüklenemedi. Lütfen tekrar deneyin.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<String?> _uploadProfileImage(XFile image) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return null;

      // Basic size guard (3MB)
      const maxSize = 3 * 1024 * 1024;
      if (bytes.length > maxSize) {
        throw Exception('Dosya boyutu çok büyük. Maksimum 3MB olmalıdır.');
      }

      // Cloudinary ayarları kontrolü
      if (!ExternalImageStorageConfig.enabled) {
        throw Exception('Profil fotoğrafı yükleme özelliği şu anda devre dışı. Lütfen yöneticiye başvurun.');
      }

      if (ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
          ExternalImageStorageConfig.cloudinaryCloudName.isEmpty) {
        throw Exception('Cloudinary cloud name ayarlı değil. `ExternalImageStorageConfig.cloudinaryCloudName` doldurun.');
      }

      if (ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset == 'YOUR_UPLOAD_PRESET' ||
          ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
        throw Exception('Cloudinary upload preset ayarlı değil. `ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset` doldurun.');
      }

      // Cloudinary'ye yükle
      final external = ExternalImageUploadService();
      final url = await external.uploadImageBytes(
        bytes: bytes,
        fileName: image.name.isNotEmpty ? image.name : 'profile_${user.uid}.jpg',
        folder: ExternalImageStorageConfig.cloudinaryProfileFolder,
      );
      
      return url;
    } catch (e) {
      debugPrint('Profil fotoğrafı upload hatası: $e');
      rethrow; // Hata mesajını yukarı fırlat
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false, // Klavye performansı için
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.purple[600]!, Colors.blue[600]!],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Dil değiştirme özelliği kaldırıldı
                    // Üst profil kartı
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Profil fotoğrafı
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.purple[400]!, Colors.blue[400]!],
                              ),
                            ),
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.grey[100],
                                    backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                            ? NetworkImage(_profileImageUrl!) 
                                        : null,
                                    child: _profileImageUrl == null 
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.grey[400],
                                          )
                                        : null,
                                  ),
                                ),
                                // Kamera ikonu overlay
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: _pickProfileImage,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[600],
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _fullName?.isNotEmpty == true ? _fullName! : 'Misafir Kullanıcı',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _email?.isNotEmpty == true ? _email! : 'Giriş yapılmadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_username?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '@$_username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.purple[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_phone?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📞 $_phone',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_address?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              '📍 $_address',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          // Giriş/Kayıt butonları veya Çıkış butonu
                          if (_auth.currentUser == null) ...[
                            Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.purple[600]!, Colors.blue[600]!],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kayıt sayfasına yönlendiriliyor...')),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.person_add, color: Colors.white),
                                    label: Text(
                                      'Kayıt Ol',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.purple[600]!, width: 2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ElevatedButton.icon(
                                    onPressed: _auth.currentUser == null ? () async {
                                      await AppRoutes.navigateToLogin(context);
                                      // Giriş sayfasından döndükten sonra kullanıcı bilgilerini yeniden yükle
                                      if (mounted) {
                                        await _loadUserData();
                                      }
                                    } : () async {
                                      await _auth.signOut();
                                      if (mounted) {
                                        // Başlangıç sayfasına (LandingPage) yönlendir
                                        AppRoutes.navigateToLanding(context);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: Icon(Icons.login, color: Colors.purple[600]),
                                    label: Text(
                                      _auth.currentUser == null ? 'Giriş Yap' : 'Çıkış Yap',
                                      style: TextStyle(
                                        color: Colors.purple[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Kullanıcı İstatistikleri
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap İstatistikleri',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.favorite,
                                  title: 'Favori Ürün',
                                  value: '${_userStats['favoriteCount'] ?? 0}',
                                  color: Colors.red,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FavorilerSayfasi(
                                          favoriteProducts: widget.favoriteProducts,
                                          onFavoriteToggle: widget.onFavoriteToggle ?? (product, {bool showMessage = true}) {},
                                          onAddToCart: widget.onAddToCart,
                                          cartProducts: widget.cartProducts,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.shopping_cart,
                                  title: 'Sepet Tutarı',
                                  value: '${(_userStats['cartTotal'] ?? 0.0).toStringAsFixed(2)} TL',
                                  color: Colors.green,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SepetimSayfasi(
                                          cartProducts: widget.cartProducts,
                                          onRemoveFromCart: widget.onRemoveFromCart!,
                                          onUpdateQuantity: widget.onUpdateQuantity!,
                                          onPlaceOrder: () => widget.onPlaceOrder!(widget.cartProducts),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.star,
                                  title: 'Toplam Harcama',
                                  value: '${(_userStats['totalSpent'] ?? 0.0).toStringAsFixed(2)} TL',
                                  color: Colors.orange,
                                  onTap: () {
                                    _openOrdersPage();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Hesap Yönetimi
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hesap Yönetimi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildAccountTile(
                            icon: Icons.receipt_long,
                            title: 'Siparişlerim',
                            subtitle: 'Tüm geçmiş ve aktif siparişler',
                            onTap: _openOrdersPage,
                          ),
                          _buildAccountTile(
                            icon: Icons.person,
                            title: 'Profil Bilgileri',
                            subtitle: 'Ad, soyad, e-posta düzenle',
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfilDuzenlemeSayfasi(),
                                ),
                              );
                              // Profil güncellendiyse verileri yeniden yükle
                              if (result == true) {
                                _loadUserData();
                              }
                            },
                          ),
                          _buildAccountTile(
                            icon: Icons.location_on,
                            title: 'Adreslerim',
                            subtitle: 'Teslimat adreslerini yönet',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdresYonetimiSayfasi(),
                                ),
                              );
                            },
                          ),
                          _buildAccountTile(
                            icon: Icons.credit_card,
                            title: 'Ödeme Yöntemleri',
                            subtitle: 'Kart ve ödeme bilgileri',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const OdemeYontemleriSayfasi(),
                                ),
                              );
                            },
                          ),
                          if (_auth.currentUser != null)
                            _buildAccountTile(
                              icon: Icons.logout,
                              title: 'Çıkış Yap',
                              subtitle: 'Hesabından çıkış yap',
                              onTap: () {
                                _showLogoutDialog();
                              },
                              isDestructive: true,
                            ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Sosyal Medya ve İletişim
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sosyal Medya & İletişim',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.facebook,
                                  label: 'Facebook',
                                  color: Colors.blue[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Facebook sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.camera_alt,
                                  label: 'Instagram',
                                  color: Colors.pink[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Instagram sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.alternate_email,
                                  label: 'Twitter',
                                  color: Colors.blue[400]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Twitter sayfasına yönlendiriliyor...')),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSocialButton(
                                  icon: Icons.phone,
                                  label: 'İletişim',
                                  color: Colors.green[600]!,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('İletişim bilgileri gösteriliyor...')),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Ayarlar kartı
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ayarlar',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildSettingTile(
                            icon: Icons.notifications,
                            title: 'Bildirim Ayarları',
                            subtitle: 'Bildirimleri yönet',
                            themeProvider: themeProvider,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const BildirimAyarlariSayfasi(),
                                ),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.lock,
                            title: 'Gizlilik Ayarları',
                            subtitle: 'Hesap güvenliği',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gizlilik ayarları tıklandı')),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.info,
                            title: 'Uygulama Hakkında',
                            subtitle: 'Versiyon ve bilgiler',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Uygulama hakkında tıklandı')),
                              );
                            },
                          ),
                          _buildSettingTile(
                            icon: Icons.help,
                            title: 'Yardım & Destek',
                            subtitle: 'Sorularınız için',
                            themeProvider: themeProvider,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Yardım & Destek tıklandı')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeProvider themeProvider,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.purple[600], size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }


  Future<void> _openOrdersPage() async {
    try {
      final orders = await OrderService().getUserOrders();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiparislerSayfasi(
            orders: orders,
            onOrderPlaced: widget.onOrderPlaced,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SiparislerSayfasi(
            orders: widget.orders,
            onOrderPlaced: widget.onOrderPlaced,
          ),
        ),
      );
    }
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool isAdmin = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red[50] : (isAdmin ? Colors.blue[50] : Colors.grey[50]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDestructive ? Colors.red[200]! : (isAdmin ? Colors.blue[200]! : Colors.grey[200]!),
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[50] : (isAdmin ? Colors.blue[50] : Colors.purple[50]),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon, 
            color: isDestructive ? Colors.red[600] : (isAdmin ? Colors.blue[600] : Colors.purple[600]), 
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red[700] : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isDestructive ? Colors.red[600] : Colors.grey[600],
            fontSize: 12,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDestructive ? Colors.red[400] : Colors.grey[400],
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    final parentContext = context;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Çıkış Yap'),
          content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  await _auth.signOut();
                } catch (_) {}
                if (mounted) {
                  // Başlangıç sayfasına (LandingPage) yönlendir
                  AppRoutes.navigateToLanding(parentContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}