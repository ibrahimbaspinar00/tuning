import 'package:flutter/foundation.dart';
import '../model/product.dart';
import '../model/order.dart';
import '../services/firebase_data_service.dart';

/// Ana uygulama state yönetimi için Provider
class AppStateProvider extends ChangeNotifier {
  // Ürün listeleri
  final List<Product> _favoriteProducts = [];
  final List<Product> _cartProducts = [];
  final List<Order> _orders = [];
  
  // UI durumları
  bool _isLoading = false;
  String _currentUser = '';
  int _selectedTabIndex = 0;
  
  // Getters
  List<Product> get favoriteProducts => List.unmodifiable(_favoriteProducts);
  List<Product> get cartProducts => List.unmodifiable(_cartProducts);
  List<Order> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  String get currentUser => _currentUser;
  int get selectedTabIndex => _selectedTabIndex;
  
  // Cart operations
  void addToCart(Product product) {
    final existingIndex = _cartProducts.indexWhere((p) => p.id == product.id);
    
    if (existingIndex >= 0) {
      _cartProducts[existingIndex] = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        category: product.category,
        stock: product.stock,
        quantity: _cartProducts[existingIndex].quantity + 1,
      );
    } else {
      _cartProducts.add(Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        category: product.category,
        stock: product.stock,
        quantity: 1,
      ));
    }
    
    notifyListeners();
  }
  
  void removeFromCart(Product product) {
    _cartProducts.removeWhere((p) => p.id == product.id);
    notifyListeners();
  }
  
  void updateCartQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      removeFromCart(product);
      return;
    }
    
    final index = _cartProducts.indexWhere((p) => p.id == product.id);
    if (index >= 0) {
      _cartProducts[index] = Product(
        id: product.id,
        name: product.name,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        category: product.category,
        stock: product.stock,
        quantity: quantity,
      );
      notifyListeners();
    }
  }
  
  void clearCart() {
    _cartProducts.clear();
    notifyListeners();
  }
  
  // Favorite operations
  void toggleFavorite(Product product) {
    final FirebaseDataService dataService = FirebaseDataService();
    final index = _favoriteProducts.indexWhere((p) => p.id == product.id);
    
    if (index >= 0) {
      _favoriteProducts.removeAt(index);
      // Firestore'dan da kaldır
      try { dataService.removeFromFavorites(product.id); } catch (_) {}
    } else {
      _favoriteProducts.add(product);
      // Firestore'a ekle
      try { dataService.addToFavorites(product.id); } catch (_) {}
    }
    
    notifyListeners();
  }
  
  bool isFavorite(Product product) {
    return _favoriteProducts.any((p) => p.id == product.id);
  }
  
  // Order operations
  void addOrder(Order order) {
    _orders.add(order);
    notifyListeners();
  }
  
  // UI state operations
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void setCurrentUser(String user) {
    _currentUser = user;
    notifyListeners();
  }
  
  void setSelectedTabIndex(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }
  
  // Utility methods
  double get cartTotal {
    return _cartProducts.fold(0.0, (sum, product) => sum + (product.price * product.quantity));
  }
  
  int get cartItemCount {
    return _cartProducts.fold(0, (sum, product) => sum + product.quantity);
  }
  
  // Reset all data
  void reset() {
    _favoriteProducts.clear();
    _cartProducts.clear();
    _orders.clear();
    _isLoading = false;
    _currentUser = '';
    _selectedTabIndex = 0;
    notifyListeners();
  }
}
