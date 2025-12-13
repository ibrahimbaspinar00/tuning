import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Memory management utility for performance optimization
class MemoryManager {
  static final List<VoidCallback> _cleanupCallbacks = [];
  static const int _maxImageCacheSize = 100; // MB
  
  /// Register cleanup callback
  static void registerCleanup(VoidCallback callback) {
    _cleanupCallbacks.add(callback);
  }
  
  /// Clear all registered cleanups
  static void clearAllCleanups() {
    for (final callback in _cleanupCallbacks) {
      callback();
    }
    _cleanupCallbacks.clear();
  }
  
  /// Clear image cache if it gets too large
  static void clearImageCacheIfNeeded() {
    final currentSize = imageCache.currentSizeBytes;
    final maxSize = _maxImageCacheSize * 1024 * 1024; // Convert MB to bytes
    
    if (currentSize > maxSize) {
      imageCache.clear();
      if (kDebugMode) {
        debugPrint('🧹 Image cache cleared (was ${(currentSize / 1024 / 1024).toStringAsFixed(1)}MB)');
      }
    }
  }
  
  /// Clear all caches
  static void clearAllCaches() {
    imageCache.clear();
    if (kDebugMode) {
      debugPrint('🧹 All caches cleared');
    }
  }
  
  /// Optimize memory usage
  static void optimizeMemory() {
    clearImageCacheIfNeeded();
    
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // This is a hint to the garbage collector
      debugPrint('🔄 Memory optimization triggered');
    }
  }
  
  /// Get memory usage info
  static Map<String, dynamic> getMemoryInfo() {
    return {
      'imageCacheSize': imageCache.currentSizeBytes,
      'imageCacheCount': imageCache.currentSize,
      'maxImageCacheSize': imageCache.maximumSizeBytes,
      'maxImageCacheCount': imageCache.maximumSize,
    };
  }
  
  /// Print memory usage
  static void printMemoryUsage(String context) {
    if (kDebugMode) {
      final info = getMemoryInfo();
      debugPrint('📊 Memory usage at $context:');
      debugPrint('  Image cache: ${(info['imageCacheSize'] as int) / 1024 / 1024}MB');
      debugPrint('  Image count: ${info['imageCacheCount']}');
    }
  }
}

/// Memory-aware widget that automatically cleans up resources
class MemoryAwareWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDispose;
  
  const MemoryAwareWidget({
    super.key,
    required this.child,
    this.onDispose,
  });
  
  @override
  State<MemoryAwareWidget> createState() => _MemoryAwareWidgetState();
}

class _MemoryAwareWidgetState extends State<MemoryAwareWidget> {
  @override
  void initState() {
    super.initState();
    MemoryManager.registerCleanup(_cleanup);
  }
  
  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }
  
  void _cleanup() {
    widget.onDispose?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Optimized image widget with memory management
class MemoryOptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  
  const MemoryOptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });
  
  @override
  State<MemoryOptimizedImage> createState() => _MemoryOptimizedImageState();
}

class _MemoryOptimizedImageState extends State<MemoryOptimizedImage> {
  @override
  void initState() {
    super.initState();
    // Clear cache if needed when new image is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MemoryManager.clearImageCacheIfNeeded();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: Image.asset(
        widget.imageUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
              size: 32,
            ),
          );
        },
      ),
    );
  }
}
