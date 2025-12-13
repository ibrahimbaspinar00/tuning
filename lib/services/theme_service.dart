import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static ThemeMode _themeMode = ThemeMode.system;
  
  static ThemeMode get themeMode => _themeMode;
  
  static bool get isDarkMode => _themeMode == ThemeMode.dark;
  static bool get isLightMode => _themeMode == ThemeMode.light;
  static bool get isSystemMode => _themeMode == ThemeMode.system;
  
  // Tema değiştirme (Firebase + Local)
  static Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    
    // Local'e kaydet (fallback için)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode.toString());
    
    // Firebase initialize edilmişse ve kullanıcı giriş yapmışsa Firebase'e kaydet
    if (!_isFirebaseInitialized()) {
      debugPrint('Firebase not initialized, theme saved to local storage only');
      return;
    }
    
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'themeMode': mode.toString(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Error saving theme to Firebase: $e');
      }
    }
  }
  
  // Firebase'in initialize edilip edilmediğini kontrol et
  static bool _isFirebaseInitialized() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Tema yükleme (Firebase'den, yoksa local'den)
  static Future<void> loadTheme() async {
    // Önce local'den yükle (Firebase'e bağımlı değil)
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey);
    if (themeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeString,
        orElse: () => ThemeMode.system,
      );
      debugPrint('Theme loaded from local storage: $_themeMode');
    }
    
    // Firebase initialize edilmişse ve kullanıcı giriş yapmışsa Firebase'den yükle
    if (!_isFirebaseInitialized()) {
      debugPrint('Firebase not initialized, using local theme');
      return;
    }
    
    final user = _auth.currentUser;
    if (user != null) {
      try {
        // Firebase'den yükle
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && doc.data()?['themeMode'] != null) {
          final themeString = doc.data()!['themeMode'] as String;
          _themeMode = ThemeMode.values.firstWhere(
            (mode) => mode.toString() == themeString,
            orElse: () => ThemeMode.system,
          );
          
          // Local'e de kaydet (senkronizasyon için)
          await prefs.setString(_themeKey, themeString);
          
          debugPrint('Theme loaded from Firebase: $_themeMode');
          return;
        }
      } catch (e) {
        debugPrint('Error loading theme from Firebase: $e');
      }
      
      // Local'de varsa Firebase'e de kaydet (senkronizasyon için)
      if (themeString != null) {
        try {
          await _firestore.collection('users').doc(user.uid).set({
            'themeMode': themeString,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error syncing theme to Firebase: $e');
        }
      }
    }
  }
  
  // Tema toggle
  static Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.system);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }
}

// Tema renkleri
class AppColors {
  // Açık tema renkleri (beyaz arka plan)
  static const Color lightPrimary = Color(0xFF6B46C1);
  static const Color lightSecondary = Color(0xFF3B82F6);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightError = Color(0xFFEF4444);
  static const Color lightSuccess = Color(0xFF10B981);
  static const Color lightWarning = Color(0xFFF59E0B);
  
  // Koyu tema renkleri (siyah arka plan)
  static const Color darkPrimary = Color(0xFF8B5CF6);
  static const Color darkSecondary = Color(0xFF60A5FA);
  static const Color darkBackground = Color(0xFF000000);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkSuccess = Color(0xFF34D399);
  static const Color darkWarning = Color(0xFFFBBF24);
}

// Tema oluşturucu
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.lightPrimary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.lightPrimary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.lightSurface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: AppColors.lightSurface,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.darkPrimary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.darkPrimary,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: AppColors.darkSurface,
        shadowColor: Colors.black.withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[600]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.darkPrimary, width: 2),
        ),
        filled: true,
        fillColor: AppColors.darkSurface,
        labelStyle: TextStyle(color: Colors.grey[300]),
        hintStyle: TextStyle(color: Colors.grey[400]),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        bodySmall: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
        titleSmall: TextStyle(color: Colors.white70),
      ),
    );
  }
}
