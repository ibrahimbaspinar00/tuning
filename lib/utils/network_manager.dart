import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Gelişmiş network ve bağlantı yönetimi
class NetworkManager {
  static NetworkManager? _instance;
  static NetworkManager get instance => _instance ??= NetworkManager._();
  
  NetworkManager._();
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  bool _isOnline = true;
  ConnectivityResult _currentConnection = ConnectivityResult.none;
  final List<NetworkCallback> _callbacks = [];
  
  // Getters
  bool get isOnline => _isOnline;
  ConnectivityResult get currentConnection => _currentConnection;
  
  /// Network manager'ı başlat
  Future<void> initialize() async {
    try {
      // Mevcut bağlantı durumunu kontrol et
      final connectivityResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(connectivityResults);
      
      // Bağlantı değişikliklerini dinle
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _updateConnectionStatus,
        onError: (error) {
          debugPrint('Connectivity error: $error');
        },
      );
      
      debugPrint('NetworkManager initialized - Online: $_isOnline');
    } catch (e) {
      debugPrint('NetworkManager initialization error: $e');
    }
  }
  
  /// Bağlantı durumunu güncelle
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final previousStatus = _isOnline;
    final previousConnection = _currentConnection;
    
    _currentConnection = results.isNotEmpty ? results.first : ConnectivityResult.none;
    _isOnline = _currentConnection != ConnectivityResult.none;
    
    // Durum değiştiyse callback'leri çağır
    if (previousStatus != _isOnline || previousConnection != _currentConnection) {
      _notifyCallbacks();
    }
    
    debugPrint('Network status changed: ${_isOnline ? 'Online' : 'Offline'} ($_currentConnection)');
  }
  
  /// Internet bağlantısını test et
  Future<bool> testInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Internet test failed: $e');
      return false;
    }
  }
  
  /// Callback ekle
  void addCallback(NetworkCallback callback) {
    _callbacks.add(callback);
  }
  
  /// Callback kaldır
  void removeCallback(NetworkCallback callback) {
    _callbacks.remove(callback);
  }
  
  /// Callback'leri bildir
  void _notifyCallbacks() {
    for (final callback in _callbacks) {
      try {
        callback(_isOnline, _currentConnection);
      } catch (e) {
        debugPrint('Network callback error: $e');
      }
    }
  }
  
  /// Network isteği yap (retry ile)
  Future<T?> makeRequest<T>(
    Future<T> Function() request, {
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool retryOnConnectionError = true,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        // Bağlantı kontrolü
        if (!_isOnline) {
          throw NetworkException('No internet connection');
        }
        
        final result = await request();
        return result;
      } catch (e) {
        attempts++;
        
        // Son deneme ise hatayı fırlat
        if (attempts >= maxRetries) {
          rethrow;
        }
        
        // Bağlantı hatası ise retry yap
        if (retryOnConnectionError && _isConnectionError(e)) {
          debugPrint('Network request failed (attempt $attempts), retrying in ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay);
          continue;
        }
        
        // Diğer hatalar için retry yapma
        rethrow;
      }
    }
    
    return null;
  }
  
  /// Bağlantı hatası kontrolü
  bool _isConnectionError(dynamic error) {
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    if (error is NetworkException) return true;
    if (error.toString().contains('Connection') || 
        error.toString().contains('Network') ||
        error.toString().contains('Timeout')) {
      return true;
    }
    return false;
  }
  
  /// Offline mod kontrolü
  bool get isOfflineMode => !_isOnline;
  
  /// WiFi bağlantısı kontrolü
  bool get isWiFiConnected => _currentConnection == ConnectivityResult.wifi;
  
  /// Mobil bağlantı kontrolü
  bool get isMobileConnected => _currentConnection == ConnectivityResult.mobile;
  
  /// Ethernet bağlantısı kontrolü
  bool get isEthernetConnected => _currentConnection == ConnectivityResult.ethernet;
  
  /// Temizle
  void dispose() {
    _connectivitySubscription?.cancel();
    _callbacks.clear();
  }
}

/// Network callback typedef
typedef NetworkCallback = void Function(bool isOnline, ConnectivityResult connection);

/// Network exception
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Network-aware widget mixin
mixin NetworkAwareMixin {
  bool _isOnline = true;
  ConnectivityResult _currentConnection = ConnectivityResult.none;
  
  void initializeNetwork() {
    // Mevcut durumu al
    _isOnline = NetworkManager.instance.isOnline;
    _currentConnection = NetworkManager.instance.currentConnection;
    
    // Callback ekle
    NetworkManager.instance.addCallback(_onNetworkChanged);
  }
  
  void _onNetworkChanged(bool isOnline, ConnectivityResult connection) {
    _isOnline = isOnline;
    _currentConnection = connection;
    
    onNetworkChanged(isOnline, connection);
  }
  
  /// Network durumu değiştiğinde çağrılır
  void onNetworkChanged(bool isOnline, ConnectivityResult connection) {
    // Override edilebilir
  }
  
  void disposeNetwork() {
    NetworkManager.instance.removeCallback(_onNetworkChanged);
  }
  
  // Getters
  bool get isOnline => _isOnline;
  ConnectivityResult get currentConnection => _currentConnection;
  bool get isOffline => !_isOnline;
}
