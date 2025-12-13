import 'package:flutter/material.dart';
import '../model/product.dart';
import '../widgets/optimized_image.dart';

class RecommendedProducts extends StatelessWidget {
  final List<Product> products;
  final Future<void> Function(Product) onAddToCart;
  final Function(Product) onToggleFavorite;
  final List<Product>? favoriteProducts;

  const RecommendedProducts({
    super.key,
    required this.products,
    required this.onAddToCart,
    required this.onToggleFavorite,
    this.favoriteProducts,
  });

  bool _isFavorite(Product product) {
    if (favoriteProducts == null) return false;
    String normalize(String s) => s.trim().toLowerCase();
    final target = normalize(product.name);
    return favoriteProducts!.any((p) => normalize(p.name) == target);
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Container(
        height: 180,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.recommend,
                size: 40,
                color: Colors.grey,
              ),
              SizedBox(height: 6),
              Text(
                'Önerilen Ürünler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Yakında burada görünecek',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 180,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Sizin İçin Önerilenler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  width: 140,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün Resmi
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: OptimizedImage(
                          imageUrl: product.imageUrl,
                          height: 80,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Ürün Bilgileri
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Ürün Adı
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 1),
                              // Fiyat
                              Text(
                                '${product.price.toStringAsFixed(2)} TL',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Butonlar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Favori butonu
                                  GestureDetector(
                                    onTap: () => onToggleFavorite(product),
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: _isFavorite(product) ? Colors.red[50] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _isFavorite(product) ? Icons.favorite : Icons.favorite_border,
                                        size: 14,
                                        color: _isFavorite(product) ? Colors.red[600] : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  // Sepete ekle butonu
                                  GestureDetector(
                                    onTap: () async {
                                      await onAddToCart(product);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Ekle',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
