import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cached_network_image/cached_network_image.dart';

class OptimizedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool enableCaching;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.enableCaching = true,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> with AutomaticKeepAliveClientMixin {
  bool _isLoading = true;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Preload image for better performance
    final trimmedUrl = widget.imageUrl.trim();
    if (widget.enableCaching && 
        trimmedUrl.isNotEmpty && 
        (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'))) {
      _preloadImage();
    }
  }

  Future<void> _preloadImage() async {
    try {
      await precacheImage(
        CachedNetworkImageProvider(widget.imageUrl.trim()),
        context,
      );
    } catch (e) {
      debugPrint('Preload error: $e');
      // Ignore preload errors
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    
    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: _buildImage(),
    );
  }
  
  Widget _buildImage() {
    // Boş veya geçersiz URL kontrolü
    final trimmedUrl = widget.imageUrl.trim();
    if (trimmedUrl.isEmpty) {
      debugPrint('⚠️ OptimizedImage: Empty image URL');
      return _buildErrorWidget();
    }
    
    if (trimmedUrl.startsWith('assets/')) {
      return Image.asset(
        trimmedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) {
            _isLoading = false;
            return child;
          }
          return AnimatedOpacity(
            opacity: _isLoading ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: child,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Asset image error: $error');
          return _buildErrorWidget();
        },
        cacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
        cacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
      );
    } else if (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://')) {
      // Firebase Storage URL'lerini özel olarak handle et
      final isFirebaseStorage = trimmedUrl.contains('firebasestorage.googleapis.com');
      
      debugPrint('🖼️ Loading image from: ${isFirebaseStorage ? "Firebase Storage" : "Network"}');
      debugPrint('URL: $trimmedUrl');
      
      // Önce CachedNetworkImage ile dene
      return CachedNetworkImage(
        imageUrl: trimmedUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        placeholder: (context, url) {
          _isLoading = true;
          return _buildPlaceholder();
        },
        errorWidget: (context, url, error) {
          debugPrint('❌ CachedNetworkImage error for URL: $url');
          debugPrint('Error type: ${error.runtimeType}');
          debugPrint('Error details: $error');
          
          // CachedNetworkImage başarısız olursa, Image.network ile dene (fallback)
          if (mounted) {
            return _buildFallbackImage(trimmedUrl);
          }
          return _buildErrorWidget();
        },
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
        memCacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
        memCacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
        maxWidthDiskCache: 800,
        maxHeightDiskCache: 800,
        useOldImageOnUrlChange: true,
        // Firebase Storage için özel ayarlar
        httpHeaders: isFirebaseStorage ? {
          'Accept': 'image/*',
        } : null,
      );
    } else {
      // Geçersiz URL formatı
      debugPrint('❌ Invalid image URL format: $trimmedUrl');
      return _buildErrorWidget();
    }
  }
  
  // Fallback: CachedNetworkImage başarısız olursa Image.network kullan
  Widget _buildFallbackImage(String url) {
    debugPrint('🔄 Trying fallback Image.network for: $url');
    
    return Image.network(
      url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          _isLoading = false;
          return child;
        }
        return _buildPlaceholder();
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('❌ Image.network also failed: $error');
        return _buildErrorWidget();
      },
      headers: {
        'Accept': 'image/*',
      },
      // Cache ayarları
      cacheWidth: widget.width != null && widget.width!.isFinite ? widget.width!.toInt() : null,
      cacheHeight: widget.height != null && widget.height!.isFinite ? widget.height!.toInt() : null,
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: widget.placeholder ?? const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: widget.errorWidget ?? const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
        size: 32,
      ),
    );
  }
}