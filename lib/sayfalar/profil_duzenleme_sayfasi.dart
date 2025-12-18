import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_data_service.dart';
import '../services/user_auth_service.dart';
import '../services/external_image_upload_service.dart';
import '../config/external_image_storage_config.dart';
import '../widgets/error_handler.dart';
import '../config/app_routes.dart';

class ProfilDuzenlemeSayfasi extends StatefulWidget {
  const ProfilDuzenlemeSayfasi({super.key});

  @override
  State<ProfilDuzenlemeSayfasi> createState() => _ProfilDuzenlemeSayfasiState();
}

class _ProfilDuzenlemeSayfasiState extends State<ProfilDuzenlemeSayfasi> {
  final FirebaseDataService _dataService = FirebaseDataService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserAuthService _userAuthService = UserAuthService();
  final ImagePicker _picker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneCountryCodeController = TextEditingController(text: '+90');
  final _phoneNumberController = TextEditingController();
  
  int? _selectedDay;
  int? _selectedMonth;
  int? _selectedYear;
  bool _isCorporate = false;
  
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _dataService.getUserProfile();
      final user = _auth.currentUser;
      
      if (mounted) {
        // Ad Soyad: Firestore'dan, yoksa FirebaseAuth displayName'den, o da yoksa email'den
        String fullName = '';
        if (userData != null && userData['fullName'] != null) {
          fullName = userData['fullName'].toString().trim();
        }
        if (fullName.isEmpty && user?.displayName != null) {
          fullName = user!.displayName!.trim();
        }
        if (fullName.isEmpty && user?.email != null) {
          fullName = user!.email!.split('@')[0];
        }
        
        // Ad ve Soyadı ayır
        String firstName = '';
        String lastName = '';
        if (fullName.isNotEmpty) {
          final parts = fullName.split(' ');
          if (parts.isNotEmpty) {
            firstName = parts.first;
            if (parts.length > 1) {
              lastName = parts.sublist(1).join(' ');
            }
          }
        }
        
        // Email: Firestore'dan, yoksa FirebaseAuth'tan
        String email = '';
        if (userData != null && userData['email'] != null) {
          email = userData['email'].toString().trim();
        }
        if (email.isEmpty && user?.email != null) {
          email = user!.email!.trim();
        }
        
        // Telefon: Firestore'dan
        String phone = '';
        if (userData != null && userData['phone'] != null) {
          phone = userData['phone'].toString().trim();
        }
        
        // Telefon numarasını ülke kodu ve numara olarak ayır
        String countryCode = '+90';
        String phoneNumber = '';
        if (phone.isNotEmpty) {
          if (phone.startsWith('+90')) {
            countryCode = '+90';
            phoneNumber = phone.substring(3).trim();
          } else if (phone.startsWith('0')) {
            countryCode = '+90';
            phoneNumber = phone.substring(1).trim();
          } else {
            phoneNumber = phone;
          }
        }
        
        // Doğum tarihi
        int? day, month, year;
        if (userData != null && userData['birthDate'] != null) {
          final birthDate = userData['birthDate'];
          if (birthDate is Map) {
            day = birthDate['day'] as int?;
            month = birthDate['month'] as int?;
            year = birthDate['year'] as int?;
          }
        }
        
        // Kurumsal
        bool isCorporate = false;
        if (userData != null && userData['isCorporate'] != null) {
          isCorporate = userData['isCorporate'] as bool;
        }
        
        // Profil fotoğrafı
        String? profileImageUrl;
        if (userData != null && userData['profileImageUrl'] != null) {
          profileImageUrl = userData['profileImageUrl'].toString();
        }
        
        setState(() {
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
          _emailController.text = email;
          _phoneCountryCodeController.text = countryCode;
          _phoneNumberController.text = phoneNumber;
          _selectedDay = day;
          _selectedMonth = month;
          _selectedYear = year;
          _isCorporate = isCorporate;
          _profileImageUrl = profileImageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Hata durumunda FirebaseAuth'tan bilgileri al
        final user = _auth.currentUser;
        if (user != null) {
          final fullName = user.displayName ?? 
                          (user.email != null ? user.email!.split('@')[0] : '');
          final parts = fullName.split(' ');
          setState(() {
            _firstNameController.text = parts.isNotEmpty ? parts.first : '';
            _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            _emailController.text = user.email ?? '';
            _phoneCountryCodeController.text = '+90';
            _phoneNumberController.text = '';
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          ErrorHandler.showError(context, 'Profil bilgileri yüklenirken hata: $e');
        }
      }
    }
  }

  Future<void> _pickProfileImage() async {
    // Cloudinary ayarları kontrolü
    if (!ExternalImageStorageConfig.enabled ||
        ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
        ExternalImageStorageConfig.cloudinaryCloudName.isEmpty ||
        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset == 'YOUR_UPLOAD_PRESET' ||
        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı yükleme özelliği şu anda kullanılamıyor. Cloudinary ayarları yapılandırılmalıdır.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    try {
      // Web için özel kontrol
      if (kIsWeb) {
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
        final ImageSource? source = await showModalBottomSheet<ImageSource>(
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
      
      final user = _auth.currentUser;
      if (user == null) return;
      
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) return;

      const maxSize = 3 * 1024 * 1024; // 3MB
      if (bytes.length > maxSize) {
        throw Exception('Dosya boyutu çok büyük. Maksimum 3MB olmalıdır.');
      }

      // Cloudinary ayarları kontrolü
      if (!ExternalImageStorageConfig.enabled) {
        throw Exception('Profil fotoğrafı yükleme özelliği şu anda devre dışı. Cloudinary ayarları yapılandırılmalıdır.');
      }

      if (ExternalImageStorageConfig.cloudinaryCloudName == 'YOUR_CLOUD_NAME' ||
          ExternalImageStorageConfig.cloudinaryCloudName.isEmpty) {
        throw Exception('Cloudinary ayarları eksik. Lütfen https://console.cloudinary.com/ adresinden ücretsiz hesap oluşturup cloud name alın ve `lib/config/external_image_storage_config.dart` dosyasına ekleyin.');
      }

      if (ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset == 'YOUR_UPLOAD_PRESET' ||
          ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isEmpty) {
        throw Exception('Cloudinary upload preset ayarlı değil. Cloudinary dashboard\'da Settings > Upload > Upload presets bölümünden unsigned preset oluşturun ve `lib/config/external_image_storage_config.dart` dosyasına ekleyin.');
      }

      // Cloudinary'ye yükle
      final external = ExternalImageUploadService();
      final url = await external.uploadImageBytes(
        bytes: bytes,
        fileName: image.name.isNotEmpty ? image.name : 'profile_${user.uid}.jpg',
        folder: ExternalImageStorageConfig.cloudinaryProfileFolder,
      );
      
      if (mounted) {
        setState(() {
          _profileImageUrl = url;
        });
        
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Profil fotoğrafı başarıyla yüklendi!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final phone = _phoneNumberController.text.trim().isNotEmpty
          ? '${_phoneCountryCodeController.text.trim()}${_phoneNumberController.text.trim()}'
          : null;
      
      Map<String, dynamic>? birthDate;
      if (_selectedDay != null && _selectedMonth != null && _selectedYear != null) {
        birthDate = {
          'day': _selectedDay,
          'month': _selectedMonth,
          'year': _selectedYear,
        };
      }
      
      // Kullanıcı adını koru (varsa)
      final userData = await _dataService.getUserProfile();
      final existingUsername = userData?['username'] ?? '';
      
      await _dataService.saveUserProfile(
        fullName: fullName,
        username: existingUsername.toString(),
        email: _emailController.text.trim(),
        phone: phone,
        profileImageUrl: _profileImageUrl,
      );
      
      // Doğum tarihi ve kurumsal bilgisini kaydet
      final user = _auth.currentUser;
      if (user != null) {
        await _dataService.updateUserData({
          'birthDate': birthDate,
          'isCorporate': _isCorporate,
        });
      }

      // Email değişikliği yapılmıyor - email alanı disabled
      // Sadece mevcut email'i Firestore'da sakla (değişiklik yok)

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil bilgileri başarıyla güncellendi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        // Hata mesajını daha anlaşılır hale getir
        String errorMessage = 'Profil güncellenirken hata oluştu: $e';
        
        if (e.toString().contains('operation-not-allowed') || 
            e.toString().contains('email-already-in-use') ||
            e.toString().contains('requires-recent-login')) {
          errorMessage = 'E-posta değişikliği için doğrulama gereklidir. Profil bilgileriniz Firestore\'da güncellendi, ancak Firebase Authentication e-posta değişikliği için lütfen e-postanızı doğrulayın.';
        }
        
        ErrorHandler.showError(
          context,
          errorMessage,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneCountryCodeController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  List<int> get _days => List.generate(31, (i) => i + 1);
  List<int> get _months => List.generate(12, (i) => i + 1);
  List<int> get _years => List.generate(100, (i) => DateTime.now().year - 100 + i + 1).reversed.toList();

  String _getMonthName(int month) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kullanıcı Bilgilerim',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve Profil Fotoğrafı
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Column(
                        children: [
                          // Profil fotoğrafı
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: (_profileImageUrl != null && _profileImageUrl!.isNotEmpty)
                                    ? NetworkImage(_profileImageUrl!)
                                    : null,
                                child: _profileImageUrl == null
                                    ? const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              // Kamera ikonu overlay (sadece Cloudinary ayarlıysa tıklanabilir)
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: (ExternalImageStorageConfig.enabled &&
                                        ExternalImageStorageConfig.cloudinaryCloudName != 'YOUR_CLOUD_NAME' &&
                                        ExternalImageStorageConfig.cloudinaryCloudName.isNotEmpty &&
                                        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset != 'YOUR_UPLOAD_PRESET' &&
                                        ExternalImageStorageConfig.cloudinaryUnsignedUploadPreset.isNotEmpty)
                                    ? GestureDetector(
                                        onTap: _pickProfileImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF27A1A),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[400],
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
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Kişisel Bilgilerim',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 1),
                    
                    // Form içeriği
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Ad
                          Text(
                            'Ad',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _firstNameController,
                            decoration: InputDecoration(
                              hintText: 'Adınızı girin',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ad gereklidir';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                          // Soyadı
                          Text(
                            'Soyadı',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: InputDecoration(
                              hintText: 'Soyadınızı girin',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(4),
                                borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            style: GoogleFonts.inter(fontSize: 14),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Soyadı gereklidir';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          
                           // E-posta Adresi - Sadece görüntüleme (düzenlenemez)
                           Text(
                             'E-posta Adresi',
                             style: GoogleFonts.inter(
                               fontSize: 14,
                               fontWeight: FontWeight.w500,
                               color: Colors.black87,
                             ),
                           ),
                           const SizedBox(height: 8),
                           TextFormField(
                             controller: _emailController,
                             enabled: false, // Düzenlenemez
                             keyboardType: TextInputType.emailAddress,
                             decoration: InputDecoration(
                               hintText: 'E-posta adresiniz',
                               border: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(4),
                                 borderSide: BorderSide(color: Colors.grey[300]!),
                               ),
                               enabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(4),
                                 borderSide: BorderSide(color: Colors.grey[300]!),
                               ),
                               disabledBorder: OutlineInputBorder(
                                 borderRadius: BorderRadius.circular(4),
                                 borderSide: BorderSide(color: Colors.grey[300]!),
                               ),
                               filled: true,
                               fillColor: Colors.grey[100], // Disabled görünümü
                               contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                               suffixIcon: Icon(
                                 Icons.lock_outline,
                                 size: 18,
                                 color: Colors.grey[600],
                               ),
                             ),
                             style: GoogleFonts.inter(
                               fontSize: 14,
                               color: Colors.grey[700], // Disabled text rengi
                             ),
                           ),
                           const SizedBox(height: 4),
                           Text(
                             'E-posta adresi güvenlik nedeniyle değiştirilemez',
                             style: GoogleFonts.inter(
                               fontSize: 12,
                               color: Colors.grey[600],
                               fontStyle: FontStyle.italic,
                             ),
                           ),
                          const SizedBox(height: 20),
                          
                          // Cep Telefonu
                          Text(
                            'Cep Telefonu',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Ülke kodu
                              SizedBox(
                                width: 80,
                                child: TextFormField(
                                  controller: _phoneCountryCodeController,
                                  decoration: InputDecoration(
                                    hintText: '+90',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                  ),
                                  style: GoogleFonts.inter(fontSize: 14),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Telefon numarası
                              Expanded(
                                child: TextFormField(
                                  controller: _phoneNumberController,
                                  keyboardType: TextInputType.phone,
                                  decoration: InputDecoration(
                                    hintText: '5XX XXX XX XX',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  style: GoogleFonts.inter(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Doğum Tarihi
                          Text(
                            'Doğum Tarihi',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Gün
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedDay,
                                  decoration: InputDecoration(
                                    hintText: 'Gün',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  items: _days.map((day) {
                                    return DropdownMenuItem<int>(
                                      value: day,
                                      child: Text('$day', style: GoogleFonts.inter(fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedDay = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Ay
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedMonth,
                                  decoration: InputDecoration(
                                    hintText: 'Ay',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  items: _months.map((month) {
                                    return DropdownMenuItem<int>(
                                      value: month,
                                      child: Text(_getMonthName(month), style: GoogleFonts.inter(fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedMonth = value);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Yıl
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  value: _selectedYear,
                                  decoration: InputDecoration(
                                    hintText: 'Yıl',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: BorderSide(color: Colors.grey[300]!),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(4),
                                      borderSide: const BorderSide(color: Color(0xFFF27A1A)),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  ),
                                  items: _years.map((year) {
                                    return DropdownMenuItem<int>(
                                      value: year,
                                      child: Text('$year', style: GoogleFonts.inter(fontSize: 14)),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => _selectedYear = value);
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          
                          // Kurumsal checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _isCorporate,
                                onChanged: (value) {
                                  setState(() => _isCorporate = value ?? false);
                                },
                                activeColor: const Color(0xFFF27A1A),
                              ),
                              Expanded(
                                child: Text(
                                  'İşyeri alışverişlerim için fırsatlardan haberdar olmak istiyorum.',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // Güncelle Butonu
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[300],
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                                      ),
                                    )
                                  : Text(
                                      'Güncelle',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Hesabımı Kapat
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Hesabı kapatma işlemi
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hesabımı Kapat'),
                                    content: const Text('Hesabınızı kapatmak istediğinizden emin misiniz? Bu işlem geri alınamaz.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('İptal'),
                                      ),
                                      TextButton(
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await _deleteAccount();
                                        },
                                        child: const Text('Kapat', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                'Hesabımı Kapat',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _deleteAccount() async {
    // Onay dialogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı Sil'),
        content: const Text(
          'Hesabınızı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz ve tüm verileriniz kalıcı olarak silinecektir. E-postanız tekrar kullanılabilir olacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    // Loading göster
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Hesabı sil (Firebase Auth + Firestore)
      await _userAuthService.deleteAccount();

      if (!mounted) return;
      
      // Loading dialogunu kapat
      Navigator.pop(context);
      
      // Başarı mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesabınız başarıyla silindi. E-postanız artık kullanılabilir.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Ana sayfaya yönlendir
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.main,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      
      // Loading dialogunu kapat
      Navigator.pop(context);
      
      String errorMessage = 'Hesap silinirken bir hata oluştu.';
      if (e.code == 'requires-recent-login') {
        errorMessage = 'Güvenlik nedeniyle lütfen tekrar giriş yapın ve işlemi tekrar deneyin.';
      }
      
      ErrorHandler.showError(context, errorMessage);
    } catch (e) {
      if (!mounted) return;
      
      // Loading dialogunu kapat
      Navigator.pop(context);
      
      ErrorHandler.showError(
        context,
        'Hesap silinirken bir hata oluştu: $e',
      );
    }
  }
}
