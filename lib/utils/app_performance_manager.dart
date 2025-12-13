import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Profesyonel performans yönetimi ve optimizasyon sınıfı
class AppPerformanceManager {
  static final AppPerformanceManager _instance = AppPerformanceManager._internal();
  factory AppPerformanceManager() => _instance;
  AppPerformanceManager._internal();

  Timer? _memoryCleanupTimer;
  Timer? _fpsMonitorTimer;
  int _frameCount = 0;
  double _currentFPS = 60.0;
  bool _isMonitoring = false;
  
  // Performance metrics
  final List<double> _fpsHistory = [];
  static const int _maxFpsHistory = 60; // Son 60 saniye

  /// Performans izlemeyi başlat
  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    
    // FPS monitoring
    _fpsMonitorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateFPS();
    });
    
    // Memory cleanup (her 2 dakikada bir)
    _memoryCleanupTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      _performMemoryCleanup();
    });
    
    if (kDebugMode) {
      debugPrint('✅ AppPerformanceManager: Monitoring started');
    }
  }

  /// Performans izlemeyi durdur
  void stopMonitoring() {
    _isMonitoring = false;
    _fpsMonitorTimer?.cancel();
    _memoryCleanupTimer?.cancel();
    _fpsMonitorTimer = null;
    _memoryCleanupTimer = null;
    
    if (kDebugMode) {
      debugPrint('⏹️ AppPerformanceManager: Monitoring stopped');
    }
  }

  /// FPS güncelle
  void _updateFPS() {
    _fpsHistory.add(_currentFPS);
    if (_fpsHistory.length > _maxFpsHistory) {
      _fpsHistory.removeAt(0);
    }
    
    // Ortalama FPS hesapla
    final avgFPS = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    
    // FPS düşükse optimizasyon yap
    if (avgFPS < 45 && _fpsHistory.length >= 10) {
      _optimizePerformance();
    }
    
    _frameCount = 0;
  }

  /// Frame sayacını artır (WidgetsBinding'den çağrılır)
  void incrementFrameCount() {
    _frameCount++;
    _currentFPS = _frameCount.toDouble();
  }

  /// Performans optimizasyonu
  void _optimizePerformance() {
    if (kDebugMode) {
      debugPrint('⚡ AppPerformanceManager: Optimizing performance (FPS: ${_currentFPS.toStringAsFixed(1)})');
    }
    
    // Image cache temizle
    _clearImageCache();
    
    // Garbage collection için hafif bir bekleme
    Future.delayed(const Duration(milliseconds: 100), () {
      // Flutter'da GC otomatik, ama cache temizleme yardımcı olur
    });
  }

  /// Memory cleanup
  void _performMemoryCleanup() {
    if (kDebugMode) {
      debugPrint('🧹 AppPerformanceManager: Performing memory cleanup');
    }
    
    // Image cache'i temizle (eski görüntüler)
    final imageCache = PaintingBinding.instance.imageCache;
    if (imageCache.currentSizeBytes > 20 << 20) { // 20MB'dan fazlaysa
      imageCache.clear();
      if (kDebugMode) {
        debugPrint('🗑️ AppPerformanceManager: Image cache cleared');
      }
    }
  }

  /// Image cache'i temizle
  void _clearImageCache() {
    final imageCache = PaintingBinding.instance.imageCache;
    final currentSize = imageCache.currentSizeBytes;
    
    // Eğer cache çok büyükse temizle
    if (currentSize > 15 << 20) { // 15MB
      imageCache.clear();
      if (kDebugMode) {
        debugPrint('🗑️ AppPerformanceManager: Image cache cleared (was ${(currentSize / (1 << 20)).toStringAsFixed(1)}MB)');
      }
    }
  }

  /// Performans metriklerini al
  Map<String, dynamic> getPerformanceMetrics() {
    final avgFPS = _fpsHistory.isEmpty 
        ? 60.0 
        : _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
    
    final imageCache = PaintingBinding.instance.imageCache;
    
    return {
      'currentFPS': _currentFPS,
      'averageFPS': avgFPS,
      'imageCacheSize': imageCache.currentSizeBytes,
      'imageCacheCount': imageCache.currentSize,
      'isMonitoring': _isMonitoring,
    };
  }

  /// Debounce helper - aynı işlemi tekrar tekrar yapmayı önler
  static final Map<String, Timer> _debounceTimers = {};
  
  static void debounce(
    String key,
    Duration delay,
    VoidCallback action,
  ) {
    _debounceTimers[key]?.cancel();
    _debounceTimers[key] = Timer(delay, () {
      action();
      _debounceTimers.remove(key);
    });
  }

  /// Throttle helper - belirli süre içinde sadece bir kez çalışır
  static final Map<String, DateTime> _throttleTimestamps = {};
  
  static bool throttle(String key, Duration duration) {
    final now = DateTime.now();
    final lastCall = _throttleTimestamps[key];
    
    if (lastCall == null || now.difference(lastCall) >= duration) {
      _throttleTimestamps[key] = now;
      return true;
    }
    
    return false;
  }

  /// Cleanup - tüm timer'ları temizle
  void dispose() {
    stopMonitoring();
    _debounceTimers.values.forEach((timer) => timer.cancel());
    _debounceTimers.clear();
    _throttleTimestamps.clear();
  }
}

/// Widget rebuild optimizasyonu için mixin
mixin PerformanceOptimizedWidget<T extends StatefulWidget> on State<T> {
  bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
  
  /// Güvenli setState - dispose kontrolü ile
  void safeSetState(VoidCallback fn) {
    if (!_isDisposed && mounted) {
      setState(fn);
    }
  }
  
  /// Güvenli async setState
  Future<void> safeAsyncSetState(Future<void> Function() fn) async {
    if (_isDisposed || !mounted) return;
    
    await fn();
    
    if (!_isDisposed && mounted) {
      // setState gerekirse burada çağrılabilir
    }
  }
}

/// RepaintBoundary wrapper - gereksiz repaint'leri önler
class OptimizedRepaintBoundary extends StatelessWidget {
  final Widget child;
  final String? debugLabel;
  
  const OptimizedRepaintBoundary({
    super.key,
    required this.child,
    this.debugLabel,
  });
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: child,
    );
  }
}

/// Const constructor helper - rebuild'leri önler
class ConstWidget extends StatelessWidget {
  final Widget child;
  
  const ConstWidget({
    super.key,
    required this.child,
  });
  
  @override
  Widget build(BuildContext context) => child;
}

