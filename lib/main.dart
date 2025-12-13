import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'model/product.dart';
import 'services/product_service.dart';
import 'config/app_routes.dart';
import 'sayfalar/main_screen.dart';
import 'sayfalar/giris_sayfasi.dart';
import 'utils/responsive_helper.dart';

/// Global navigator key for navigation from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Sepet yönetimi
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.price * quantity;
}

final ValueNotifier<List<CartItem>> cartItems = ValueNotifier<List<CartItem>>([]);

void addToCart(Product product) {
  final currentItems = cartItems.value;
  final existingIndex = currentItems.indexWhere((item) => item.product.id == product.id);
  
  if (existingIndex != -1) {
    currentItems[existingIndex].quantity++;
  } else {
    currentItems.add(CartItem(product: product, quantity: 1));
  }
  
  cartItems.value = List.from(currentItems);
}

void removeFromCart(Product product) {
  final currentItems = cartItems.value;
  currentItems.removeWhere((item) => item.product.id == product.id);
  cartItems.value = List.from(currentItems);
}

void updateCartQuantity(Product product, int quantity) {
  if (quantity <= 0) {
    removeFromCart(product);
    return;
  }
  
  final currentItems = cartItems.value;
  final existingIndex = currentItems.indexWhere((item) => item.product.id == product.id);
  
  if (existingIndex != -1) {
    currentItems[existingIndex].quantity = quantity;
    cartItems.value = List.from(currentItems);
  }
}

int getCartItemCount() {
  return cartItems.value.fold(0, (sum, item) => sum + item.quantity);
}

double getCartTotal() {
  return cartItems.value.fold(0.0, (sum, item) => sum + item.total);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Performans optimizasyonları - Önce UI optimizasyonları
  // Image cache ayarları - Web için optimize edilmiş
  PaintingBinding.instance.imageCache.maximumSize = 50; // 100'den 50'ye düşürüldü
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB (100 MB'dan düşürüldü)
  
  // Uygulamayı başlat
  runApp(const TuningWebApp());
}

class TuningWebApp extends StatelessWidget {
  const TuningWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = Theme.of(context).textTheme;

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Tuning Web',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD4AF37),
          brightness: Brightness.light,
          // Modern web-first renk paleti - Premium görünüm
          primary: const Color(0xFF0F0F0F),
          onPrimary: Colors.white,
          primaryContainer: const Color(0xFF1A1A1A),
          onPrimaryContainer: Colors.white,
          secondary: const Color(0xFFD4AF37),
          onSecondary: const Color(0xFF0F0F0F),
          secondaryContainer: const Color(0xFFFFF8E8),
          onSecondaryContainer: const Color(0xFF1A1A1A),
          tertiary: const Color(0xFF6366F1),
          onTertiary: Colors.white,
          error: const Color(0xFFEF4444),
          onError: Colors.white,
          surface: const Color(0xFFFFFFFF),
          onSurface: const Color(0xFF0F0F0F),
          surfaceContainerHighest: const Color(0xFFF8F9FA),
          surfaceContainer: const Color(0xFFFAFBFC),
          outline: const Color(0xFFE8E8E8),
          outlineVariant: const Color(0xFFF0F0F0),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAFBFC),
        // Web-optimize edilmiş tipografi - Desktop-first yaklaşım
        textTheme: GoogleFonts.interTextTheme(baseTextTheme).copyWith(
          displayLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 96, // Web için daha büyük
            letterSpacing: -3,
            color: const Color(0xFF1A1A1A),
            height: 1.1,
          ),
          displayMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 72, // Web için daha büyük
            letterSpacing: -2,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
          displaySmall: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 56, // Web için daha büyük
            letterSpacing: -1.5,
            color: const Color(0xFF1A1A1A),
            height: 1.2,
          ),
          headlineLarge: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 48, // Web için daha büyük
            letterSpacing: -1,
            color: const Color(0xFF1A1A1A),
            height: 1.3,
          ),
          headlineMedium: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 36, // Web için daha büyük
            letterSpacing: -0.5,
            color: const Color(0xFF1A1A1A),
            height: 1.3,
          ),
          headlineSmall: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 28, // Web için daha büyük
            letterSpacing: -0.3,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          titleLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 24, // Web için daha büyük
            letterSpacing: 0,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          titleMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 20, // Web için daha büyük
            letterSpacing: 0.1,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          titleSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 18, // Web için daha büyük
            letterSpacing: 0.1,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          bodyLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 20, // Web için daha büyük
            letterSpacing: 0.15,
            color: const Color(0xFF4A4A4A),
            height: 1.7, // Web için daha geniş satır aralığı
          ),
          bodyMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 18, // Web için daha büyük
            letterSpacing: 0.25,
            color: const Color(0xFF6A6A6A),
            height: 1.6, // Web için daha geniş satır aralığı
          ),
          bodySmall: GoogleFonts.inter(
            fontWeight: FontWeight.w400,
            fontSize: 16, // Web için daha büyük
            letterSpacing: 0.4,
            color: const Color(0xFF8A8A8A),
            height: 1.5,
          ),
          labelLarge: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            letterSpacing: 0.1,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          labelMedium: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            letterSpacing: 0.5,
            color: const Color(0xFF1A1A1A),
            height: 1.4,
          ),
          labelSmall: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 12,
            letterSpacing: 0.5,
            color: const Color(0xFF6A6A6A),
            height: 1.4,
          ),
        ),
        // Modern Web AppBar teması - Daha büyük ve premium
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 2,
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0F0F0F),
          shadowColor: Colors.black.withOpacity(0.08),
          centerTitle: false,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F0F0F),
            letterSpacing: -0.5,
          ),
          iconTheme: const IconThemeData(
            color: Color(0xFF0F0F0F),
            size: 26,
          ),
          toolbarHeight: 80,
        ),
        // Web-optimize edilmiş Card teması - Premium görünüm
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          shadowColor: Color(0x0F000000), // Colors.black.withOpacity(0.06) equivalent
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(28)), // Web için daha yuvarlak
            side: BorderSide(
              color: Color(0x80E8E8E8), // Color(0xFFE8E8E8).withOpacity(0.5) equivalent
              width: 1, // İnce border
            ),
          ),
          margin: EdgeInsets.all(16), // Web için daha büyük margin
        ),
        // Web-optimize edilmiş Button temaları - Premium ve büyük
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24), // Web için daha büyük
            minimumSize: const Size(140, 64), // Web için minimum boyut
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 19, // Web için daha büyük
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 24), // Web için daha büyük
            minimumSize: const Size(140, 64), // Web için minimum boyut
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 19, // Web için daha büyük
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20), // Web için daha büyük
            minimumSize: const Size(120, 56), // Web için minimum boyut
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16), // Web için daha yuvarlak
            ),
            side: BorderSide(
              color: const Color(0xFFE5E5E5),
              width: 2, // Web için daha kalın
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 18, // Web için daha büyük
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16), // Web için daha büyük
            minimumSize: const Size(80, 48), // Web için minimum boyut
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Web için daha yuvarlak
            ),
            textStyle: GoogleFonts.inter(
              fontSize: 18, // Web için daha büyük
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        // Web-optimize edilmiş Input temaları - Premium ve büyük
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFBFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26), // Web için daha büyük
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            borderSide: BorderSide(
              color: const Color(0xFFE8E8E8),
              width: 1.5, // İnce border
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            borderSide: BorderSide(
              color: const Color(0xFFE8E8E8),
              width: 1.5, // İnce border
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            borderSide: const BorderSide(
              color: Color(0xFFD4AF37),
              width: 2.5, // Focus için kalın
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 1.5,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18), // Web için daha yuvarlak
            borderSide: const BorderSide(
              color: Color(0xFFEF4444),
              width: 2.5,
            ),
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 17, // Web için daha büyük
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6A6A6A),
          ),
          hintStyle: GoogleFonts.inter(
            fontSize: 17, // Web için daha büyük
            fontWeight: FontWeight.w400,
            color: const Color(0xFFB0B0B0),
          ),
        ),
        // Modern Divider teması
        dividerTheme: DividerThemeData(
          color: const Color(0xFFE5E5E5),
          thickness: 1,
          space: 1,
        ),
        // Modern Chip teması
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFF5F5F5),
          selectedColor: const Color(0xFFD4AF37),
          disabledColor: const Color(0xFFF0F0F0),
          labelStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}


class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _heroAnimationController;
  // Floating animation kaldırıldı - performans için
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  int _currentTestimonialIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // Main animation controller - daha hızlı başlat
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800), // 1500'den 800'e düşürüldü
      vsync: this,
    );
    
    // Hero animation controller - daha hızlı başlat
    _heroAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 2000'den 1000'e düşürüldü
      vsync: this,
    );
    
    // Floating animation controller (infinite) - Kaldırıldı performans için
    // _floatingAnimationController = AnimationController(
    //   duration: const Duration(milliseconds: 3000),
    //   vsync: this,
    // )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _heroAnimationController, curve: Curves.elasticOut),
    );
    
    // _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
    //   CurvedAnimation(parent: _floatingAnimationController, curve: Curves.easeInOut),
    // );
    
    _mainAnimationController.forward();
    _heroAnimationController.forward();
    
    // Auto-rotate testimonials
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _rotateTestimonials();
      }
    });
  }

  void _rotateTestimonials() {
    if (mounted) {
      setState(() {
        _currentTestimonialIndex = (_currentTestimonialIndex + 1) % 3;
      });
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          _rotateTestimonials();
        }
      });
    }
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _heroAnimationController.dispose();
    // _floatingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1024;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A0A0A),
                  const Color(0xFF111111),
                  const Color(0xFF0D0D0D),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated background elements
                _buildAnimatedBackground(),
                
                // Main content
                SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            // Hero Section - Full width with gradient
                            _buildHeroSection(isDesktop, isTablet, textTheme),
                            
                            // Features Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
                                vertical: isDesktop ? 80 : isTablet ? 60 : 48,
                              ),
                              child: _buildFeaturesSection(isDesktop, isTablet, textTheme),
                            ),
                            
                            // Popular Products Preview
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
                                vertical: isDesktop ? 60 : isTablet ? 48 : 40,
                              ),
                              child: _buildPopularProductsSection(isDesktop, isTablet, textTheme),
                            ),
                            
                            // Testimonials Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
                                vertical: isDesktop ? 60 : isTablet ? 48 : 40,
                              ),
                              child: _buildTestimonialsSection(isDesktop, isTablet, textTheme),
                            ),
                            
                            // Stats Section
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 80 : isTablet ? 40 : 24,
                                vertical: isDesktop ? 60 : isTablet ? 48 : 40,
                              ),
                              child: _buildStatsSection(isDesktop, isTablet, textTheme),
                            ),
                            
                            // CTA Section
                            Padding(
                              padding: EdgeInsets.only(
                                left: isDesktop ? 80 : isTablet ? 40 : 24,
                                right: isDesktop ? 80 : isTablet ? 40 : 24,
                                top: isDesktop ? 60 : isTablet ? 48 : 40,
                                bottom: isDesktop ? 80 : isTablet ? 60 : 48,
                              ),
                              child: _buildCTASection(isDesktop, isTablet, textTheme),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    // Basitleştirilmiş background - performans için ağır animasyonlar kaldırıldı
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0A),
            const Color(0xFF111111),
            const Color(0xFF0D0D0D),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 100 : isTablet ? 60 : 24,
        vertical: isDesktop ? 120 : isTablet ? 80 : 60,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Premium Badge with glassmorphism
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      size: 16,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'PREMIUM TUNİNG PLATFORM',
                    style: GoogleFonts.inter(
                      color: const Color(0xFFD4AF37),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 48 : isTablet ? 40 : 32),
          
          // Main Title - Ultra Modern
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFD4AF37),
                Color(0xFFFFFFFF),
              ],
              stops: [0.0, 0.5, 1.0],
            ).createShader(bounds),
            child: Text(
              'ELİTE\nTUNİNG',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 96 : isTablet ? 72 : 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -3,
                height: 1.0,
              ),
            ),
          ),
          SizedBox(height: isDesktop ? 32 : isTablet ? 24 : 20),
          
          // Subtitle - Minimal
          Text(
            'Performansın Mükemmellikle Buluştuğu Yer',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
              color: Colors.white.withOpacity(0.7),
              height: 1.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 10),
          Text(
            'Premium otomotiv parçaları ve aksesuarları',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 16 : isTablet ? 14 : 13,
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
              letterSpacing: 0.3,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: isDesktop ? 56 : isTablet ? 44 : 36),
          
          // Premium CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              // Primary CTA - Glassmorphism
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user != null) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const MainScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isDesktop ? 48 : isTablet ? 40 : 32,
                          vertical: isDesktop ? 20 : isTablet ? 18 : 16,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'KOLEKSİYONU KEŞFET',
                              style: GoogleFonts.inter(
                                fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0A0A0A),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: Color(0xFF0A0A0A),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Secondary CTA - Glassmorphism
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 48 : isTablet ? 40 : 32,
                        vertical: isDesktop ? 20 : isTablet ? 18 : 16,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'HEMEN KATIL',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 15 : isTablet ? 14 : 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.person_add_rounded,
                            size: 20,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    final features = [
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'HIZLI TESLİMAT',
        'subtitle': '24 saat içinde kargo garantisi\nTürkiye geneli premium hizmet',
        'number': '01',
      },
      {
        'icon': Icons.verified_user_rounded,
        'title': 'ORİJİNAL PARÇALAR',
        'subtitle': '%100 orijinal ürünler\n2 yıl garanti dahil',
        'number': '02',
      },
      {
        'icon': Icons.workspace_premium_rounded,
        'title': 'PREMIUM KALİTE',
        'subtitle': 'Elite otomotiv parçaları\nProfesyonel sınıf malzemeler',
        'number': '03',
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': '7/24 DESTEK',
        'subtitle': 'Uzman yardım her zaman\nÖzel müşteri hizmeti',
        'number': '04',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Text(
              'NEDEN BİZİ SEÇMELİSİNİZ',
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 14 : isTablet ? 12 : 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFD4AF37),
                letterSpacing: 4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 8),
            Text(
              'Her Detayda Mükemmellik',
              style: GoogleFonts.poppins(
                fontSize: isDesktop ? 48 : isTablet ? 40 : 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 56 : isTablet ? 44 : 32),
            if (isDesktop)
              Row(
                children: features.map((feature) => 
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _buildFeatureCard(feature, isDesktop, isTablet, textTheme),
                    ),
                  ),
                ).toList(),
              )
            else
              Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: features.map((feature) => 
                  SizedBox(
                    width: isTablet ? (constraints.maxWidth - 80) / 2 : double.infinity,
                    child: _buildFeatureCard(feature, isDesktop, isTablet, textTheme),
                  ),
                ).toList(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> feature, bool isDesktop, bool isTablet, TextTheme textTheme) {
    // AnimatedBuilder kaldırıldı - performans için
    return Container(
            padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 32 : 24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Number badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    feature['number'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFD4AF37),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                // Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.4),
                        blurRadius: 25,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    size: isDesktop ? 36 : isTablet ? 32 : 28,
                    color: const Color(0xFF0A0A0A),
                  ),
                ),
                SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
                Text(
                  feature['title'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 18 : isTablet ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
                Text(
                  feature['subtitle'] as String,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 13 : isTablet ? 12 : 11,
                    color: Colors.white.withOpacity(0.6),
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
  }

  Widget _buildPopularProductsSection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    final products = [
      {'name': 'EGZOZ SİSTEMİ', 'price': '₺24.999', 'category': 'PERFORMANS', 'image': '🚗'},
      {'name': 'BODY KİT SETİ', 'price': '₺49.999', 'category': 'AERODİNAMİK', 'image': '🏎️'},
      {'name': 'SPOR JANT SETİ', 'price': '₺32.999', 'category': 'JANTLAR', 'image': '⚙️'},
      {'name': 'CHİP TUNİNG', 'price': '₺17.999', 'category': 'MOTOR', 'image': '💨'},
    ];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÖNE ÇIKAN',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 14 : isTablet ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFD4AF37),
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: isDesktop ? 12 : isTablet ? 10 : 8),
                Text(
                  'Premium Koleksiyon',
                  style: GoogleFonts.poppins(
                    fontSize: isDesktop ? 48 : isTablet ? 40 : 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                  );
                }
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: isDesktop ? 32 : 24, vertical: isDesktop ? 16 : 12),
                backgroundColor: Colors.white.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TÜMÜNÜ GÖR',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 40 : isTablet ? 32 : 24),
        SizedBox(
          height: isDesktop ? 320 : isTablet ? 280 : 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(right: 20),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Container(
                width: isDesktop ? 280 : isTablet ? 240 : 200,
                margin: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Product Image
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.2),
                              const Color(0xFFD4AF37).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                product['image'] as String,
                                style: TextStyle(fontSize: isDesktop ? 90 : isTablet ? 80 : 70),
                              ),
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD4AF37).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFD4AF37).withOpacity(0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  product['category'] as String,
                                  style: GoogleFonts.inter(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFD4AF37),
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Text(
                        product['name'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 16 : isTablet ? 15 : 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestimonialsSection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    final testimonials = [
      {
        'name': 'MEHMET YILMAZ',
        'role': 'OTOMOTİV TUTKUNU',
        'comment': 'Olağanüstü kalite ve hizmet. Egzoz sistemi aracımın performansını tamamen değiştirdi.',
        'rating': 5,
        'location': 'İSTANBUL',
      },
      {
        'name': 'AYŞE DEMİR',
        'role': 'YARIŞ ARABASI SAHİBİ',
        'comment': 'Beklentileri aşan premium parçalar. Hızlı kargo ve profesyonel destek her zaman.',
        'rating': 5,
        'location': 'ANKARA',
      },
      {
        'name': 'CAN ÖZKAN',
        'role': 'TUNİNG UZMANI',
        'comment': 'Chip tuning modülü inanılmaz sonuçlar verdi. Performans artışı için en iyi yatırım.',
        'rating': 5,
        'location': 'İZMİR',
      },
    ];

    return Column(
      children: [
        Text(
          'MÜŞTERİ YORUMLARI',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 14 : isTablet ? 12 : 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFD4AF37),
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 8),
        Text(
          'Müşterilerimiz Ne Diyor',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 48 : isTablet ? 40 : 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 56 : isTablet ? 44 : 32),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: Container(
            key: ValueKey(_currentTestimonialIndex),
            padding: EdgeInsets.all(isDesktop ? 56 : isTablet ? 44 : 32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              children: [
                // Stars
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    testimonials[_currentTestimonialIndex]['rating'] as int,
                    (index) => const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFD4AF37),
                      size: 32,
                    ),
                  ),
                ),
                SizedBox(height: isDesktop ? 28 : isTablet ? 24 : 20),
                // Comment
                Text(
                  '"${testimonials[_currentTestimonialIndex]['comment'] as String}"',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: isDesktop ? 32 : isTablet ? 28 : 24),
                // User Info
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (testimonials[_currentTestimonialIndex]['name'] as String)[0],
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isDesktop ? 20 : isTablet ? 16 : 12),
                    Text(
                      testimonials[_currentTestimonialIndex]['name'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 8 : isTablet ? 6 : 4),
                    Text(
                      testimonials[_currentTestimonialIndex]['role'] as String,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 14 : isTablet ? 13 : 12,
                        color: Colors.white.withOpacity(0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 4 : isTablet ? 3 : 2),
                    Text(
                      testimonials[_currentTestimonialIndex]['location'] as String,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 12 : isTablet ? 11 : 10,
                        color: const Color(0xFFD4AF37),
                        letterSpacing: 2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 32 : isTablet ? 28 : 24),
                // Dots indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    testimonials.length,
                    (index) => Container(
                      width: _currentTestimonialIndex == index ? 32 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: _currentTestimonialIndex == index
                            ? const Color(0xFFD4AF37)
                            : Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCTASection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 100 : isTablet ? 80 : 60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD4AF37),
            Color(0xFFFFD700),
            Color(0xFFD4AF37),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withOpacity(0.6),
            blurRadius: 60,
            offset: const Offset(0, 30),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'HAZIR MISINIZ',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 14 : isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0A0A0A),
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 20 : isTablet ? 16 : 12),
          Text(
            'Performans Yolculuğunuz',
            style: GoogleFonts.poppins(
              fontSize: isDesktop ? 64 : isTablet ? 52 : 40,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0A0A0A),
              letterSpacing: -2.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 24 : isTablet ? 20 : 16),
          Text(
            'Mükemmellik için tasarlanmış premium otomotiv parçalarını keşfedin',
            style: GoogleFonts.inter(
              fontSize: isDesktop ? 20 : isTablet ? 18 : 16,
              color: const Color(0xFF0A0A0A).withOpacity(0.7),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isDesktop ? 48 : isTablet ? 40 : 32),
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0A),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MainScreen()),
                      );
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 56 : isTablet ? 48 : 40,
                      vertical: isDesktop ? 24 : isTablet ? 20 : 18,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'HEMEN KEŞFET',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD4AF37),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 22,
                          color: Color(0xFFD4AF37),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(bool isDesktop, bool isTablet, TextTheme textTheme) {
    final stats = [
      {'value': '50K+', 'label': 'MUTLU MÜŞTERİ', 'icon': Icons.people_rounded},
      {'value': '10K+', 'label': 'ÜRÜN ÇEŞİDİ', 'icon': Icons.inventory_2_rounded},
      {'value': '98%', 'label': 'MEMNUNİYET', 'icon': Icons.star_rounded},
      {'value': '7/24', 'label': 'DESTEK', 'icon': Icons.support_agent_rounded},
    ];

    return Column(
      children: [
        Text(
          'RAKAMLARIMIZ',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 14 : isTablet ? 12 : 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFD4AF37),
            letterSpacing: 4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 16 : isTablet ? 12 : 8),
        Text(
          'Rakamlarda Mükemmellik',
          style: GoogleFonts.poppins(
            fontSize: isDesktop ? 48 : isTablet ? 40 : 28,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -1.5,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isDesktop ? 56 : isTablet ? 44 : 32),
        Container(
          padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 40 : 32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: isDesktop
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: stats.map((stat) => _buildStatItem(stat, isDesktop, isTablet, textTheme)).toList(),
                )
              : Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 40,
                  runSpacing: 40,
                  children: stats.map((stat) => _buildStatItem(stat, isDesktop, isTablet, textTheme)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildStatItem(Map<String, dynamic> stat, bool isDesktop, bool isTablet, TextTheme textTheme) {
    // AnimatedBuilder kaldırıldı - performans için
    return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4AF37), Color(0xFFFFD700)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.4),
                      blurRadius: 25,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  stat['icon'] as IconData,
                  size: isDesktop ? 36 : isTablet ? 32 : 28,
                  color: const Color(0xFF0A0A0A),
                ),
              ),
              SizedBox(height: isDesktop ? 20 : isTablet ? 16 : 12),
              Text(
                stat['value'] as String,
                style: GoogleFonts.poppins(
                  fontSize: isDesktop ? 42 : isTablet ? 36 : 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1.5,
                ),
              ),
              SizedBox(height: isDesktop ? 10 : isTablet ? 8 : 6),
              Text(
                stat['label'] as String,
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 13 : isTablet ? 12 : 11,
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
  }

}

// Grid Pattern Painter for premium background
// _GridPatternPainter kaldırıldı - performans için artık kullanılmıyor

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ValueNotifier<Set<String>> selectedFilters = ValueNotifier<Set<String>>({});
  String selectedSort = 'Önerilen';
  String selectedCategory = 'Tüm Kategoriler';
  late final ProductService _productService;
  late final Stream<List<Product>> _productStream;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    // Stream'i başlat - cache sorunlarını önlemek için her seferinde yeni stream
    _productStream = _productService.getAllProductsStream();
    
    // Web'de cache sorunlarını önlemek için sayfa açıldığında sunucudan zorla çek
    _refreshProductsFromServer();
  }
  
  // Sunucudan ürünleri zorla çek - cache sorunlarını önlemek için
  Future<void> _refreshProductsFromServer() async {
    try {
      debugPrint('🔄 Ürünler sunucudan zorla çekiliyor (cache bypass)...');
      final products = await _productService.getAllProducts();
      debugPrint('✅ Sunucudan ${products.length} adet ürün çekildi');
      
      // Stream'i yeniden başlat - taze veri için
      if (mounted) {
        setState(() {
          _productStream = _productService.getAllProductsStream();
        });
      }
    } catch (e) {
      debugPrint('⚠️ Sunucudan ürün çekme hatası: $e');
    }
  }

  @override
  void dispose() {
    selectedFilters.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = ResponsiveHelper.isDesktop(context);
        final crossAxisCount = ResponsiveHelper.responsiveProductGridColumns(context);
        
        final appBarHeight = ResponsiveHelper.responsiveValue<double>(
          context,
          mobile: 250.0,
          tablet: 230.0,
          desktop: 190.0,
        );
        
    return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          drawer: isDesktop ? null : Builder(
            builder: (context) => Drawer(
              child: FiltersPanel(selectedFilters: selectedFilters),
            ),
          ),
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(appBarHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: const _TopActionBar(),
                ),
                Flexible(
                  child: _SearchBar(
                    selectedCategory: selectedCategory,
                    onCategoryChange: (category) => setState(() => selectedCategory = category),
                  ),
                ),
              ],
            ),
          ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: ResponsiveHelper.responsiveValue<double>(
                    context,
                    mobile: 0.0,
                    desktop: 180.0,
                    largeScreen: 200.0,
                  ),
                  child: FiltersPanel(selectedFilters: selectedFilters),
                ),
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: _productStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48),
                            const SizedBox(height: 12),
                            Text('Ürünler yüklenirken hata oluştu: ${snapshot.error}'),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => setState(() {}),
                              child: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      );
                    }

                    final allProducts = snapshot.data ?? [];

                    if (allProducts.isEmpty) {
                      return const Center(
                        child: Text('Gösterilecek ürün bulunamadı.'),
                      );
                    }

                    return ValueListenableBuilder<Set<String>>(
                      valueListenable: selectedFilters,
                      builder: (context, filters, _) {
                        final preparedProducts =
                            _applyFiltersAndSort(allProducts, filters, selectedCategory, selectedSort);
                        return Column(
                          children: [
                            SortBar(
                              selectedSort: selectedSort,
                              onSortSelected: (value) => setState(() => selectedSort = value),
                            ),
                            Expanded(
                              child: CustomScrollView(
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        HeroBanner(isCompact: !isDesktop),
                                        const SizedBox(height: 24),
                                        const InsightsRow(),
                                        const SizedBox(height: 24),
                                        FeaturedCollections(isCompact: !isDesktop),
                                        const SizedBox(height: 24),
                                      ],
                                    ),
                                  ),
                                  SliverPadding(
                                    padding: EdgeInsets.only(
                                      left: ResponsiveHelper.responsiveHorizontalPadding(context).horizontal / 2,
                                      right: ResponsiveHelper.responsiveHorizontalPadding(context).horizontal / 2,
                                      bottom: ResponsiveHelper.responsiveSpacing(
                                        context,
                                        mobile: 24.0,
                                        tablet: 28.0,
                                        desktop: 32.0,
                                      ),
                                    ),
                                    sliver: SliverGrid(
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                                        mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                                        childAspectRatio: ResponsiveHelper.responsiveProductAspectRatio(context),
                                      ),
                                      delegate: SliverChildBuilderDelegate(
                                        (context, index) {
                                          return ProductCard(product: preparedProducts[index]);
                                        },
                                        childCount: preparedProducts.length,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : const _MobileNavigationBar(),
        );
      },
    );
  }
}

List<Product> _applyFiltersAndSort(
  List<Product> products,
  Set<String> filters,
  String selectedCategory,
  String sortBy,
) {
  var filtered = products.where((product) {
    final matchesCategory =
        selectedCategory == 'Tüm Kategoriler' || product.category == selectedCategory;
    if (!matchesCategory) return false;

    bool matchesFilters = true;
    for (final filter in filters) {
      switch (filter) {
        case 'İndirimli':
          matchesFilters &= product.discountPercentage > 0;
          break;
        case 'Yüksek Puan':
          matchesFilters &= product.averageRating >= 4.5;
          break;
        case 'Çok Satan':
          matchesFilters &= product.salesCount >= 50;
          break;
        case '0-5.000 ₺':
          matchesFilters &= product.discountedPrice <= 5000;
          break;
        case '5.000-15.000 ₺':
          matchesFilters &= product.discountedPrice > 5000 && product.discountedPrice <= 15000;
          break;
        case '15.000+ ₺':
          matchesFilters &= product.discountedPrice > 15000;
          break;
        default:
          matchesFilters &= true;
      }
      if (!matchesFilters) break;
    }
    return matchesFilters;
  }).toList();

  switch (sortBy) {
    case 'Artan Fiyat':
      filtered.sort((a, b) => a.discountedPrice.compareTo(b.discountedPrice));
      break;
    case 'Azalan Fiyat':
      filtered.sort((a, b) => b.discountedPrice.compareTo(a.discountedPrice));
      break;
    case 'Yorum Sayısı':
      filtered.sort((b, a) => a.reviewCount.compareTo(b.reviewCount));
      break;
    default:
      filtered.sort((b, a) => a.salesCount.compareTo(b.salesCount));
  }

  return filtered;
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: const Color(0xFF4A4A4A),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1A1A1A),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopActionBar extends StatelessWidget {
  const _TopActionBar();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 900;
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 24 : 48,
            vertical: isCompact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF0A0A0A),
                              const Color(0xFFD4AF37),
                              const Color(0xFF0A0A0A),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: Text(
                            'tuning.',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_basket_outlined, size: 20),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => OrdersPage()),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.favorite_border, size: 20),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => FavoritesPage()),
                                );
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Color(0xFFD4AF37),
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: const Color(0xFF4A4A4A),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Teslimat Adresi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: const Color(0xFF6A6A6A),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    // Logo
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          const Color(0xFF0A0A0A),
                          const Color(0xFFD4AF37),
                          const Color(0xFF0A0A0A),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Text(
                        'tuning.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Teslimat Adresi
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 17,
                            color: const Color(0xFF4A4A4A),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Teslimat Adresi',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: const Color(0xFF6A6A6A),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Sağ taraftaki butonlar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeaderButton(
                          icon: Icons.shopping_basket_outlined,
                          label: 'Siparişlerim',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => OrdersPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _HeaderButton(
                          icon: Icons.favorite_border,
                          label: 'Favoriler',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => FavoritesPage()),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const GirisSayfasi()),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD4AF37).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 17,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Giriş Yap',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.onCategoryChange,
    required this.selectedCategory,
  });

  final ValueChanged<String> onCategoryChange;
  final String selectedCategory;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1000;
        final searchField = Expanded(
          child: Container(
            height: isCompact ? 44 : 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFD4AF37),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.search, color: Colors.grey[600], size: 22),
                ),
                Expanded(
                  child: TextField(
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: const Color(0xFF1A1A1A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ürün, kategori veya marka ara',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.grey[500],
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                Container(
                  width: isCompact ? 80 : 100,
                  height: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD4AF37),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(6),
                      bottomRight: Radius.circular(6),
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {},
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'ARA',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

        final quickCategories = categories.take(4).toList();
        final quickSelection = quickCategories.contains(selectedCategory)
            ? selectedCategory
            : quickCategories.first;
        final categorySelector = SegmentedButton<String>(
          segments: quickCategories
              .map(
                (c) => ButtonSegment(
                  value: c,
                  label: Text(
                    c,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              .toList(),
          selected: {quickSelection},
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            side: WidgetStateProperty.all(
              BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onSelectionChanged: (value) => onCategoryChange(value.first),
        );

        final cartButton = ValueListenableBuilder<List<CartItem>>(
          valueListenable: cartItems,
          builder: (context, items, _) {
            final count = getCartItemCount();
            return IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CartPage()),
                );
              },
              icon: Badge.count(
                count: count,
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            );
          },
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 48,
            vertical: isCompact ? 12 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [searchField]),
                    const SizedBox(height: 10),
                    categorySelector,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerRight, child: cartButton),
                  ],
                )
              : Row(
                  children: [
                    searchField,
                    const SizedBox(width: 24),
                    categorySelector,
                    const SizedBox(width: 24),
                    cartButton,
                  ],
                ),
        );
      },
    );
  }
}

class FiltersPanel extends StatelessWidget {
  const FiltersPanel({super.key, required this.selectedFilters});

  final ValueNotifier<Set<String>> selectedFilters;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedFilters,
      builder: (context, filters, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          children: [
            Text(
              'Filtreler',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0A0A0A),
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 16),
            ...filterGroups.entries.map(
              (entry) => _FilterSection(
                title: entry.key,
                options: entry.value,
                filters: filters,
                onChanged: (option) {
                  final newFilters = Set<String>.from(filters);
                  if (newFilters.contains(option)) {
                    newFilters.remove(option);
                  } else {
                    newFilters.add(option);
                  }
                  selectedFilters.value = newFilters;
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.filters,
    required this.onChanged,
  });

  final String title;
  final List<String> options;
  final Set<String> filters;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          ...options.map(
            (option) => InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
                child: Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: filters.contains(option)
                              ? const Color(0xFFD4AF37)
                              : const Color(0xFFE0E0E0),
                          width: filters.contains(option) ? 4 : 1.5,
                        ),
                        color: filters.contains(option)
                            ? const Color(0xFFD4AF37).withOpacity(0.1)
                            : Colors.transparent,
                      ),
                      child: filters.contains(option)
                          ? const Icon(
                              Icons.check,
                              size: 8,
                              color: Color(0xFFD4AF37),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: filters.contains(option)
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: filters.contains(option)
                              ? const Color(0xFF1A1A1A)
                              : const Color(0xFF6A6A6A),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SortBar extends StatelessWidget {
  const SortBar({
    super.key,
    required this.selectedSort,
    required this.onSortSelected,
  });

  final String selectedSort;
  final ValueChanged<String> onSortSelected;

  @override
  Widget build(BuildContext context) {
    final sortButtons = SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: 'Önerilen', label: Text('Önerilen')),
        ButtonSegment(value: 'Artan Fiyat', label: Text('Artan Fiyat')),
        ButtonSegment(value: 'Azalan Fiyat', label: Text('Azalan Fiyat')),
        ButtonSegment(value: 'Yorum Sayısı', label: Text('Yorum Sayısı')),
      ],
      selected: {selectedSort},
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
        textStyle: WidgetStateProperty.all(
          GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      onSelectionChanged: (value) => onSortSelected(value.first),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE5E5E5).withOpacity(0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Align(
                alignment: Alignment.centerLeft,
                child: sortButtons,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 18,
              color: const Color(0xFF6A6A6A),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBanner extends StatelessWidget {
  const HeroBanner({super.key, this.isCompact = false});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: ResponsiveHelper.responsiveHorizontalPadding(context),
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.responsiveValue<double>(
          context,
          mobile: 28.0,
          tablet: 38.0,
          desktop: 48.0,
        ),
        vertical: ResponsiveHelper.responsiveValue<double>(
          context,
          mobile: 32.0,
          tablet: 40.0,
          desktop: 48.0,
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A0A0A).withOpacity(0.02),
            const Color(0xFFD4AF37).withOpacity(0.04),
            Colors.white,
          ],
        ),
        border: Border.all(
          color: const Color(0xFFE8E8E8).withOpacity(0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.15),
                              const Color(0xFFD4AF37).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: const Color(0xFFD4AF37),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Elite Koleksiyon',
                              style: GoogleFonts.playfairDisplay(
                                color: const Color(0xFF1A1A1A),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Otomobil tutkunuzu yansıtan seçkin çözümler',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Profesyonel performans kitlerinden, zarif günlük kullanım aksesuarlarına kadar özenle seçilmiş koleksiyonlarımız. '
                        'Kurumsal teslimat garantisi ve özel müşteri hizmetleri ile yanınızdayız.',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.75),
                          height: 1.7,
                          letterSpacing: 0.2,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1A1A1A), Color(0xFF2C2C2C), Color(0xFF1A1A1A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CategoryPage(category: 'Performans'),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD4AF37).withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Color(0xFFD4AF37),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Elite Performans',
                                        style: GoogleFonts.playfairDisplay(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: Colors.white,
                              border: Border.all(
                                color: const Color(0xFF1A1A1A).withOpacity(0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => ConsultationPage()),
                                  );
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A1A1A).withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.verified_user_rounded,
                                          color: Color(0xFF1A1A1A),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Özel Danışmanlık',
                                        style: GoogleFonts.playfairDisplay(
                                          color: const Color(0xFF1A1A1A),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 15,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.directions_car_filled, size: 48, color: colorScheme.primary),
                            const SizedBox(height: 12),
                            Text(
                              'Mükemmellik Standardı',
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) => Icon(
                                Icons.star_rounded,
                                color: const Color(0xFFD4AF37),
                                size: 24,
                              )),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sertifikalı uzman ekibimiz ile',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class InsightsRow extends StatelessWidget {
  const InsightsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 1200
              ? 4
              : constraints.maxWidth > 900
                  ? 3
                  : 2;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: insights
                .map(
                  (insight) => SizedBox(
                    width: (constraints.maxWidth - (16 * (columns - 1))) / columns,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(insight.icon, color: colorScheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            insight.title,
                            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            insight.subtitle,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class FeaturedCollections extends StatelessWidget {
  const FeaturedCollections({super.key, required this.isCompact});

  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: ResponsiveHelper.responsiveHorizontalPadding(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seçili Koleksiyonlar',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CollectionsPage()),
                  );
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
        ),
        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
        SizedBox(
          height: isCompact ? null : ResponsiveHelper.responsiveValue<double>(
            context,
            mobile: 200.0,
            tablet: 210.0,
            desktop: 220.0,
          ),
          child: ListView.separated(
            padding: ResponsiveHelper.responsiveHorizontalPadding(context),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final collection = featuredCollections[index];
              return _CollectionCard(collection: collection, isCompact: isCompact);
            },
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemCount: featuredCollections.length,
          ),
        ),
      ],
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({required this.collection, this.isCompact = false});

  final FeaturedCollection collection;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: ResponsiveHelper.responsiveValue<double>(
        context,
        mobile: 260.0,
        tablet: 280.0,
        desktop: 300.0,
      ),
      padding: ResponsiveHelper.responsivePadding(
        context,
        mobile: 20.0,
        tablet: 23.0,
        desktop: 26.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: collection.accent.withOpacity(0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: collection.accent.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Chip(
            label: Text(collection.badge),
            backgroundColor: collection.accent.withOpacity(0.12),
            labelStyle: TextStyle(color: collection.accent, fontWeight: FontWeight.w600),
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          SizedBox(height: isCompact ? 10 : 12),
          Text(
            collection.title,
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 6 : 8),
          Text(
            collection.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 12 : 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  collection.stat,
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_outward, color: collection.accent, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}


class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final cardPadding = ResponsiveHelper.responsivePadding(
      context,
      mobile: 8.0,
      tablet: 10.0,
      desktop: 12.0,
    );
    final borderRadius = ResponsiveHelper.responsiveBorderRadius(
      context,
      mobile: 6.0,
      desktop: 8.0,
    );
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              AppRoutes.navigateToProductDetail(
                context,
                product,
              );
            },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                // Ürün Resmi
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: Colors.grey[50],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: product.imageUrl.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    product.imageUrl,
                                    fit: BoxFit.contain,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.image,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.image,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                        ),
                        // İndirim Badge
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
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                // Ürün Adı
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: ResponsiveHelper.responsiveFontSize(
                      context,
                      mobile: 13.0,
                      tablet: 13.5,
                      desktop: 14.0,
                    ),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1A1A1A),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 6.0, desktop: 8.0)),
                // Değerlendirme
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber[700],
                      size: ResponsiveHelper.responsiveIconSize(
                        context,
                        mobile: 14.0,
                        desktop: 16.0,
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 3.0, desktop: 4.0)),
                    Text(
                      product.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          mobile: 11.0,
                          desktop: 12.0,
                        ),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 3.0, desktop: 4.0)),
                    Text(
                      '(${product.reviewCount})',
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          mobile: 11.0,
                          desktop: 12.0,
                        ),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                // Fiyat
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.discountPercentage > 0)
                      Text(
                        '${product.price.toStringAsFixed(2)} ₺',
                        style: GoogleFonts.inter(
                          fontSize: ResponsiveHelper.responsiveFontSize(
                            context,
                            mobile: 11.0,
                            desktop: 12.0,
                          ),
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[500],
                        ),
                      ),
                    SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 1.0, desktop: 2.0)),
                    Text(
                      '${product.discountedPrice.toStringAsFixed(2)} ₺',
                      style: GoogleFonts.inter(
                        fontSize: ResponsiveHelper.responsiveFontSize(
                          context,
                          mobile: 16.0,
                          tablet: 17.0,
                          desktop: 18.0,
                        ),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                // Sepete Ekle Butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${product.name} sepete eklendi',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                          backgroundColor: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          action: SnackBarAction(
                            label: 'Sepete Git',
                            textColor: const Color(0xFFD4AF37),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CartPage()),
                              );
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4AF37),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Sepete Ekle',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavigationBar extends StatefulWidget {
  const _MobileNavigationBar();

  @override
  State<_MobileNavigationBar> createState() => _MobileNavigationBarState();
}

class _MobileNavigationBarState extends State<_MobileNavigationBar> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() {
          _selectedIndex = index;
        });
        switch (index) {
          case 0:
            // Anasayfa zaten açık
            break;
          case 1:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CategoriesPage()),
            );
            break;
          case 2:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CartPage()),
            );
            break;
          case 3:
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AccountPage()),
            );
            break;
        }
      },
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Anasayfa'),
        const NavigationDestination(icon: Icon(Icons.category_outlined), label: 'Kategoriler'),
        NavigationDestination(
          icon: ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartItems,
            builder: (context, items, _) {
              final count = getCartItemCount();
              return Badge.count(
                count: count,
                child: const Icon(Icons.shopping_cart_outlined),
              );
            },
          ),
          label: 'Sepet',
        ),
        const NavigationDestination(icon: Icon(Icons.person_outline), label: 'Hesabım'),
      ],
    );
  }
}

final categories = <String>[
  'Tüm Kategoriler',
  'Performans',
  'Body Kit',
  'Elektronik',
  'Jant & Lastik',
  'Aksesuar',
  'İç Mekan',
  'Bakım',
];

final filterGroups = <String, List<String>>{
  'Durum': ['İndirimli', 'Yüksek Puan', 'Çok Satan'],
  'Fiyat Aralığı': ['0-5.000 ₺', '5.000-15.000 ₺', '15.000+ ₺'],
};

class InsightInfo {
  const InsightInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
}

const insights = [
  InsightInfo(
    icon: Icons.local_shipping_outlined,
    title: 'Aynı Gün Teslimat',
    subtitle: '34 ilde kurye + montaj desteği',
  ),
  InsightInfo(
    icon: Icons.workspace_premium_outlined,
    title: 'Yetkili Garanti',
    subtitle: 'TSE belgeli atölye ağı',
  ),
  InsightInfo(
    icon: Icons.shield_outlined,
    title: 'Güvenli Ödeme',
    subtitle: '3D Secure & escrow koruması',
  ),
  InsightInfo(
    icon: Icons.support_agent,
    title: '7/24 Concierge',
    subtitle: 'Projeye özel çözüm danışmanlığı',
  ),
];

class FeaturedCollection {
  const FeaturedCollection({
    required this.title,
    required this.description,
    required this.badge,
    required this.stat,
    required this.accent,
  });

  final String title;
  final String description;
  final String badge;
  final String stat;
  final Color accent;
}

final featuredCollections = [
  FeaturedCollection(
    title: 'GT-Line Performance',
    description: 'Stage 1-3 ECU + seramik kaplama paketleri.',
    badge: 'Favori',
    stat: '🔥 120 sipariş/hafta',
    accent: const Color(0xFFFF6A00),
  ),
  FeaturedCollection(
    title: 'Carbon Signature',
    description: 'Limitli üretim karbon fiber body kitleri.',
    badge: 'Limited',
    stat: '🌀 %96 stok doluluk',
    accent: const Color(0xFF5B5F97),
  ),
  FeaturedCollection(
    title: 'Luxe Interior',
    description: 'Alcantara + akıllı ambiyans çözümleri.',
    badge: 'Premium',
    stat: '✨ 4.9/5 ortalama puan',
    accent: const Color(0xFF2FBF71),
  ),
];

// Grid Pattern Painter for decorative background

// Sayfalar
class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Siparişlerim',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : isTablet ? 500 : double.infinity,
              ),
              padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE8E8E8).withOpacity(0.5),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_bag_outlined,
                        size: isDesktop ? 80 : isTablet ? 70 : 60,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Henüz siparişiniz yok',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'İlk siparişinizi vermek için ürünleri keşfedin',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 16 : 15,
                        color: const Color(0xFF6A6A6A),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 40 : 32,
                              vertical: isDesktop ? 18 : 16,
                            ),
                            child: Text(
                              'Alışverişe Başla',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: isDesktop ? 17 : 16,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Favorilerim',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : isTablet ? 500 : double.infinity,
              ),
              padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
              child: Container(
                padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: const Color(0xFFE8E8E8).withOpacity(0.5),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.06),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        size: isDesktop ? 80 : isTablet ? 70 : 60,
                        color: const Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Favori ürününüz yok',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Beğendiğiniz ürünleri favorilerinize ekleyin',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 16 : 15,
                        color: const Color(0xFF6A6A6A),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Giriş Yap',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 500 : isTablet ? 450 : double.infinity,
                ),
                padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 40 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFE8E8E8).withOpacity(0.5),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.06),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Hoş Geldiniz',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isDesktop ? 32 : isTablet ? 30 : 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hesabınıza giriş yapın',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 16 : 15,
                          color: const Color(0xFF6A6A6A),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6A6A6A),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6A6A6A),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Giriş başarılı',
                                    style: GoogleFonts.inter(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 18 : 16,
                              ),
                              child: Center(
                                child: Text(
                                  'Giriş Yap',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isDesktop ? 17 : 16,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Sepetim',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: ValueListenableBuilder<List<CartItem>>(
            valueListenable: cartItems,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: isDesktop ? 600 : isTablet ? 500 : double.infinity,
                    ),
                    padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
                    child: Container(
                      padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withOpacity(0.06),
                            blurRadius: 32,
                            offset: const Offset(0, 12),
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: isDesktop ? 80 : isTablet ? 70 : 60,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Sepetiniz boş',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                              letterSpacing: 0.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sepetinize ürün eklemek için alışverişe başlayın',
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 16 : 15,
                              color: const Color(0xFF6A6A6A),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => Navigator.of(context).pop(),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isDesktop ? 40 : 32,
                                    vertical: isDesktop ? 18 : 16,
                                  ),
                                  child: Text(
                                    'Alışverişe Başla',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isDesktop ? 17 : 16,
                                      letterSpacing: 0.3,
                                    ),
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

              final total = getCartTotal();
              
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 28 : 24),
                      children: [
                        ...items.map((item) => _CartItemCard(
                          item: item,
                          isDesktop: isDesktop,
                          isTablet: isTablet,
                        )),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 28 : 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Toplam',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isDesktop ? 24 : isTablet ? 22 : 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            Text(
                              '${total.toStringAsFixed(2)} ₺',
                              style: GoogleFonts.inter(
                                fontSize: isDesktop ? 24 : isTablet ? 22 : 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD4AF37).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Ödeme sayfası yakında eklenecek',
                                      style: GoogleFonts.inter(),
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xFF1A1A1A),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: isDesktop ? 18 : 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'Ödemeye Geç',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: isDesktop ? 17 : 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _CartItemCard extends StatelessWidget {
  const _CartItemCard({
    required this.item,
    required this.isDesktop,
    required this.isTablet,
  });

  final CartItem item;
  final bool isDesktop;
  final bool isTablet;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isDesktop ? 16 : isTablet ? 14 : 12),
      padding: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE8E8E8).withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 100 : isTablet ? 90 : 80,
            height: isDesktop ? 100 : isTablet ? 90 : 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade100,
            ),
            child: item.product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      item.product.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.image_outlined, size: 40),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 18 : isTablet ? 17 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A1A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.product.price.toStringAsFixed(2)} ₺',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop ? 16 : 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD4AF37),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE8E8E8).withOpacity(0.5),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              if (item.quantity > 1) {
                                updateCartQuantity(item.product, item.quantity - 1);
                              } else {
                                removeFromCart(item.product);
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              '${item.quantity}',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              updateCartQuantity(item.product, item.quantity + 1);
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: Colors.red.shade300,
                      onPressed: () {
                        removeFromCart(item.product);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ConsultationPage extends StatelessWidget {
  const ConsultationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Özel Danışmanlık',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 700 : isTablet ? 600 : double.infinity,
                ),
                padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
                child: Container(
                  padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 40 : 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: const Color(0xFFE8E8E8).withOpacity(0.5),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD4AF37).withOpacity(0.06),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Profesyonel Danışmanlık Hizmeti',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: isDesktop ? 32 : isTablet ? 30 : 28,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Otomobil tuning projeniz için uzman ekibimizle iletişime geçin. Size özel çözümler sunuyoruz.',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 16 : 15,
                          color: const Color(0xFF6A6A6A),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Adınız',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6A6A6A),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'E-posta',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6A6A6A),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Mesajınız',
                          labelStyle: GoogleFonts.inter(
                            color: const Color(0xFF6A6A6A),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: const Color(0xFFE8E8E8).withOpacity(0.5),
                              width: 0.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFD4AF37),
                              width: 1.5,
                            ),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                        ),
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD4AF37).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Mesajınız gönderildi',
                                    style: GoogleFonts.inter(),
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: const Color(0xFF1A1A1A),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isDesktop ? 18 : 16,
                              ),
                              child: Center(
                                child: Text(
                                  'Gönder',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: isDesktop ? 17 : 16,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CollectionsPage extends StatelessWidget {
  const CollectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Tüm Koleksiyonlar',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: ListView(
            padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 28 : 24),
            children: featuredCollections.map((collection) {
              return Container(
                margin: EdgeInsets.only(bottom: isDesktop ? 20 : isTablet ? 18 : 16),
                padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 28 : 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: collection.accent.withOpacity(0.2),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: collection.accent.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Chip(
                      label: Text(
                        collection.badge,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: collection.accent.withOpacity(0.12),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      collection.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: isDesktop ? 26 : isTablet ? 24 : 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      collection.description,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 15 : 14,
                        color: const Color(0xFF6A6A6A),
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      collection.stat,
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 14 : 13,
                        fontWeight: FontWeight.w600,
                        color: collection.accent,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        final crossAxisCount = isDesktop ? 4 : isTablet ? 3 : 2;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Kategoriler',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: GridView.builder(
            padding: EdgeInsets.all(isDesktop ? 32 : isTablet ? 28 : 24),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: isDesktop ? 20 : isTablet ? 18 : 16,
              mainAxisSpacing: isDesktop ? 20 : isTablet ? 18 : 16,
              childAspectRatio: isDesktop ? 1.1 : isTablet ? 1.2 : 1.2,
            ),
            itemCount: categories.length - 1,
            itemBuilder: (context, index) {
              final category = categories[index + 1];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFE8E8E8).withOpacity(0.5),
                    width: 0.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD4AF37).withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              size: isDesktop ? 48 : isTablet ? 44 : 40,
                              color: const Color(0xFFD4AF37),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            category,
                            style: GoogleFonts.inter(
                              fontSize: isDesktop ? 16 : isTablet ? 15 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1200;
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              'Hesabım',
              style: GoogleFonts.playfairDisplay(
                fontSize: isDesktop ? 28 : isTablet ? 26 : 24,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 600 : isTablet ? 550 : double.infinity,
              ),
              padding: EdgeInsets.all(isDesktop ? 48 : isTablet ? 36 : 24),
              child: ListView(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 40 : isTablet ? 36 : 32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8).withOpacity(0.5),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: isDesktop ? 50 : isTablet ? 45 : 40,
                          backgroundColor: const Color(0xFFD4AF37).withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: isDesktop ? 50 : isTablet ? 45 : 40,
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Misafir Kullanıcı',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isDesktop ? 24 : isTablet ? 22 : 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giriş yaparak daha fazla özellik kullanın',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 15 : 14,
                            color: const Color(0xFF6A6A6A),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _AccountMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profil Bilgileri',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Profil bilgileri yakında eklenecek',
                            style: GoogleFonts.inter(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                      );
                    },
                  ),
                  _AccountMenuItem(
                    icon: Icons.location_on_outlined,
                    title: 'Adreslerim',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Adres yönetimi yakında eklenecek',
                            style: GoogleFonts.inter(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                      );
                    },
                  ),
                  _AccountMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Ödeme Yöntemleri',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ödeme yöntemleri yakında eklenecek',
                            style: GoogleFonts.inter(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                      );
                    },
                  ),
                  _AccountMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Ayarlar',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Ayarlar yakında eklenecek',
                            style: GoogleFonts.inter(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFF1A1A1A),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AccountMenuItem extends StatelessWidget {
  const _AccountMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE8E8E8).withOpacity(0.5),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: EdgeInsets.all(isDesktop ? 20 : 18),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFFD4AF37),
                        size: isDesktop ? 24 : 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 16 : 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: Color(0xFF6A6A6A),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = ResponsiveHelper.responsiveProductGridColumns(context);
        
        final titleFontSize = ResponsiveHelper.responsiveFontSize(
          context,
          mobile: 24.0,
          tablet: 26.0,
          desktop: 28.0,
        );
        
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: Text(
              category,
              style: GoogleFonts.playfairDisplay(
                fontSize: titleFontSize,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
          ),
          body: StreamBuilder<List<Product>>(
            stream: ProductService().getAllProductsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8).withOpacity(0.5),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Color(0xFF6A6A6A)),
                        const SizedBox(height: 16),
                        Text(
                          'Hata: ${snapshot.error}',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: const Color(0xFF6A6A6A),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final products = snapshot.data ?? [];
              final filteredProducts = products
                  .where((p) => p.category == category)
                  .toList();
              if (filteredProducts.isEmpty) {
                return Center(
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.responsiveMaxWidth(
                        context,
                        mobile: double.infinity,
                        tablet: 500.0,
                        desktop: 600.0,
                      ),
                    ),
                    padding: ResponsiveHelper.responsivePadding(
                      context,
                      mobile: 24.0,
                      tablet: 36.0,
                      desktop: 48.0,
                    ),
                    margin: ResponsiveHelper.responsivePadding(
                      context,
                      mobile: 24.0,
                      tablet: 36.0,
                      desktop: 48.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: const Color(0xFFE8E8E8).withOpacity(0.5),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.06),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                          spreadRadius: 0,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4AF37).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: ResponsiveHelper.responsiveIconSize(
                              context,
                              mobile: 60.0,
                              tablet: 70.0,
                              desktop: 80.0,
                            ),
                            color: const Color(0xFFD4AF37),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 24.0, desktop: 32.0)),
                        Text(
                          'Bu kategoride ürün bulunamadı',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8.0, desktop: 12.0)),
                        Text(
                          'Farklı kategorileri keşfetmek için ana sayfaya dönebilirsiniz',
                          style: GoogleFonts.inter(
                            fontSize: ResponsiveHelper.responsiveFontSize(
                              context,
                              mobile: 15.0,
                              desktop: 16.0,
                            ),
                            color: const Color(0xFF6A6A6A),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                padding: ResponsiveHelper.responsivePadding(
                  context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                  mainAxisSpacing: ResponsiveHelper.responsiveGridSpacing(context),
                  childAspectRatio: ResponsiveHelper.responsiveProductAspectRatio(context),
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return ProductCard(product: filteredProducts[index]);
                },
              );
            },
          ),
        );
      },
    );
  }
}