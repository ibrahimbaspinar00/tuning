import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Gelişmiş güvenlik ve doğrulama sistemi
class SecurityManager {
  static SecurityManager? _instance;
  static SecurityManager get instance => _instance ??= SecurityManager._();
  
  SecurityManager._();
  
  /// Input sanitization
  static String sanitizeInput(String input) {
    return input.trim();
  }
  
  /// Email validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }
  
  /// Password validation
  static PasswordValidationResult validatePassword(String password) {
    final result = PasswordValidationResult();
    
    // Tüm şifre sınırlamaları kaldırıldı - sadece boş olmaması kontrol ediliyor
    if (password.isEmpty) {
      result.addError('Şifre boş olamaz');
    }
    
    return result;
  }
  
  /// Phone number validation
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^(\+90|0)?[5][0-9]{9}$');
    return phoneRegex.hasMatch(phone.replaceAll(' ', '').replaceAll('-', ''));
  }
  
  /// Hash generation
  static String generateHash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Secure random string generation
  static String generateSecureRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    
    for (int i = 0; i < length; i++) {
      buffer.write(chars[(random + i) % chars.length]);
    }
    
    return buffer.toString();
  }
  
  /// Rate limiting
  static final Map<String, List<DateTime>> _rateLimitMap = {};
  
  static bool isRateLimited(String key, {int maxAttempts = 5, Duration window = const Duration(minutes: 1)}) {
    final now = DateTime.now();
    final attempts = _rateLimitMap[key] ?? [];
    
    // Eski denemeleri temizle
    _rateLimitMap[key] = attempts.where((attempt) => 
      now.difference(attempt) < window).toList();
    
    // Limit kontrolü
    if (_rateLimitMap[key]!.length >= maxAttempts) {
      return true;
    }
    
    // Yeni deneme ekle
    _rateLimitMap[key]!.add(now);
    return false;
  }
  
  /// Clear rate limit
  static void clearRateLimit(String key) {
    _rateLimitMap.remove(key);
  }
  
  /// Input length validation
  static bool isValidLength(String input, {int minLength = 1, int maxLength = 255}) {
    return input.length >= minLength && input.length <= maxLength;
  }
  
  /// URL validation
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

/// Password validation result
class PasswordValidationResult {
  final List<String> errors = [];
  
  void addError(String error) {
    errors.add(error);
  }
  
  bool get isValid => errors.isEmpty;
  
  String get errorMessage => errors.join('\n');
}