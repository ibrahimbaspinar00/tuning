import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class WalletService {
  static const String _balanceKey = 'wallet_balance';
  static const String _transactionsKey = 'wallet_transactions';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static double _currentBalance = 0.0;
  static List<WalletTransaction> _transactions = [];
  
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();
  
  // Getters
  double get currentBalance => _currentBalance;
  List<WalletTransaction> get transactions => List.from(_transactions);
  
  // Firebase'in initialize edilip edilmediğini kontrol et
  bool _isFirebaseInitialized() {
    try {
      Firebase.app();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  // Initialize wallet (Firebase'den yükle, yoksa local'den)
  Future<void> initialize() async {
    final user = _auth.currentUser;

    if (user == null) {
      // Misafir kullanıcılar için cüzdan kullanılmaz
      _currentBalance = 0.0;
      _transactions.clear();
      await _clearLocalCache();
      debugPrint('Wallet disabled for guest users. Balance reset to 0₺');
      return;
    }
    
    if (_isFirebaseInitialized()) {
      try {
        // Önce Firebase'den yükle - offline durumunda cache'den okur
        final walletDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('wallet')
            .doc('balance')
            .get()
            .timeout(const Duration(seconds: 5), onTimeout: () {
              // Timeout durumunda local'den yükle
              throw Exception('Firestore timeout - using local storage');
            });
        
        if (walletDoc.exists && walletDoc.data()?['balance'] != null) {
          _currentBalance = (walletDoc.data()!['balance'] as num).toDouble();
        } else {
          _currentBalance = 0.0;
        }
        
        // Transaction'ları yükle - offline durumunda cache'den okur
        try {
          final transactionsSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wallet')
              .doc('transactions')
              .collection('history')
              .orderBy('timestamp', descending: true)
              .limit(100)
              .get()
              .timeout(const Duration(seconds: 5), onTimeout: () {
                throw Exception('Firestore timeout - using local storage');
              });
          
          _transactions = transactionsSnapshot.docs.map((doc) {
            final data = doc.data();
            return WalletTransaction(
              id: doc.id,
              amount: (data['amount'] as num).toDouble(),
              type: TransactionType.values.firstWhere(
                (e) => e.toString().split('.').last == data['type'],
                orElse: () => TransactionType.deposit,
              ),
              paymentMethod: data['paymentMethod'] ?? '',
              description: data['description'] ?? '',
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              status: TransactionStatus.values.firstWhere(
                (e) => e.toString().split('.').last == data['status'],
                orElse: () => TransactionStatus.completed,
              ),
            );
          }).toList();
        } catch (e) {
          // Transaction yükleme hatası kritik değil
          debugPrint('⚠️ Transaction history yüklenemedi (normal olabilir): $e');
        }
        
        // Local'e de kaydet (offline için)
        await _saveToLocalStorage();
        
        debugPrint('Wallet initialized from Firebase with balance: ${_currentBalance.toStringAsFixed(2)}₺');
        return;
      } catch (e) {
        // Offline veya network hatası - local'den yükle
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('offline') || 
            errorString.contains('unavailable') ||
            errorString.contains('network') ||
            errorString.contains('timeout')) {
          debugPrint('⚠️ Firestore offline/unavailable - loading from local storage');
        } else {
          debugPrint('Error loading wallet from Firebase: $e');
        }
      }
    }
    
    // Firebase'de yoksa veya hata varsa local'den yükle
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentBalance = prefs.getDouble(_balanceKey) ?? 0.0;
      
      final transactionsJson = prefs.getStringList(_transactionsKey) ?? [];
      _transactions = transactionsJson.map((json) => 
        WalletTransaction.fromJson(json)
      ).toList();
      
      // Local'de varsa Firebase'e senkronize et
      if (_currentBalance > 0) {
        await _saveToFirebase();
      }
      
      debugPrint('Wallet initialized from local storage with balance: ${_currentBalance.toStringAsFixed(2)}₺');
    } catch (e) {
      debugPrint('Error initializing wallet: $e');
    }
  }
  
  // Add money to wallet
  Future<bool> addMoney(double amount, String paymentMethod, String description) async {
    try {
      if (amount <= 0) return false;
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Guest users cannot add money to wallet.');
        await _clearLocalCache();
        return false;
      }
      
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = WalletTransaction(
        id: transactionId,
        amount: amount,
        type: TransactionType.deposit,
        paymentMethod: paymentMethod,
        description: description,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
      );
      
      _currentBalance += amount;
      _transactions.insert(0, transaction); // Add to beginning
      
      // Save to Firebase and local
      await _saveToFirebase();
      await _saveToLocalStorage();
      
      debugPrint('Added ${amount.toStringAsFixed(2)}₺ to wallet. New balance: ${_currentBalance.toStringAsFixed(2)}₺');
      return true;
    } catch (e) {
      debugPrint('Error adding money to wallet: $e');
      return false;
    }
  }
  
  // Spend money from wallet
  Future<bool> spendMoney(double amount, String description) async {
    try {
      if (amount <= 0 || amount > _currentBalance) return false;
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('Guest users cannot spend money from wallet.');
        await _clearLocalCache();
        return false;
      }
      
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      final transaction = WalletTransaction(
        id: transactionId,
        amount: amount,
        type: TransactionType.withdrawal,
        paymentMethod: 'Cüzdan',
        description: description,
        timestamp: DateTime.now(),
        status: TransactionStatus.completed,
      );
      
      _currentBalance -= amount;
      _transactions.insert(0, transaction);
      
      // Save to Firebase and local
      await _saveToFirebase();
      await _saveToLocalStorage();
      
      debugPrint('Spent ${amount.toStringAsFixed(2)}₺ from wallet. New balance: ${_currentBalance.toStringAsFixed(2)}₺');
      return true;
    } catch (e) {
      debugPrint('Error spending money from wallet: $e');
      return false;
    }
  }
  
  // Get transaction history
  List<WalletTransaction> getTransactionHistory({int? limit}) {
    if (limit != null) {
      return _transactions.take(limit).toList();
    }
    return List.from(_transactions);
  }
  
  // Get recent transactions
  List<WalletTransaction> getRecentTransactions(int count) {
    return _transactions.take(count).toList();
  }
  
  // Check if wallet has sufficient balance
  bool hasSufficientBalance(double amount) {
    return _currentBalance >= amount;
  }
  
  // Save to Firebase
  Future<void> _saveToFirebase() async {
    final user = _auth.currentUser;
    if (user == null || !_isFirebaseInitialized()) return;
    
    try {
      // Balance'ı kaydet
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('wallet')
          .doc('balance')
          .set({
        'balance': _currentBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Transaction'ları kaydet (sadece yeni olanları - quota tasarrufu için)
      // Son 50 transaction'ı kaydet (100 yerine 50 - quota tasarrufu)
      if (_transactions.isNotEmpty) {
        try {
          final batch = _firestore.batch();
          final transactionsRef = _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wallet')
              .doc('transactions')
              .collection('history');
          
          // Sadece son 50 transaction'ı kaydet
          for (final transaction in _transactions.take(50)) {
            final docRef = transactionsRef.doc(transaction.id);
            batch.set(docRef, {
              'amount': transaction.amount,
              'type': transaction.type.toString().split('.').last,
              'paymentMethod': transaction.paymentMethod,
              'description': transaction.description,
              'timestamp': Timestamp.fromDate(transaction.timestamp),
              'status': transaction.status.toString().split('.').last,
            }, SetOptions(merge: true)); // merge kullanarak mevcut transaction'ları silmeden güncelle
          }
          
          await batch.commit();
        } catch (e) {
          // Transaction kaydetme hatası kritik değil, sadece logla
          debugPrint('Error saving transactions to Firebase (non-critical): $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving wallet to Firebase: $e');
      // Quota hatası durumunda local storage'a kaydet
      if (e.toString().contains('RESOURCE_EXHAUSTED') || 
          e.toString().contains('Quota exceeded')) {
        debugPrint('Firestore quota exceeded, saving to local storage only');
        await _saveToLocalStorage();
      }
      rethrow; // Hata durumunda rethrow et ki çağıran kod bilgilendirilsin
    }
  }
  
  // Save to local storage (fallback)
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_balanceKey, _currentBalance);
      
      final transactionsJson = _transactions.map((t) => t.toJson()).toList();
      await prefs.setStringList(_transactionsKey, transactionsJson);
    } catch (e) {
      debugPrint('Error saving wallet data to local storage: $e');
    }
  }

  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_balanceKey);
      await prefs.remove(_transactionsKey);
    } catch (e) {
      debugPrint('Error clearing wallet local cache: $e');
    }
  }
  
  // Clear all data (for testing)
  Future<void> clearAllData() async {
    try {
      final user = _auth.currentUser;
      
      // Firebase'den temizle
      if (user != null) {
        try {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wallet')
              .doc('balance')
              .delete();
          
          final transactionsSnapshot = await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('wallet')
              .doc('transactions')
              .collection('history')
              .get();
          
          final batch = _firestore.batch();
          for (final doc in transactionsSnapshot.docs) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        } catch (e) {
          debugPrint('Error clearing wallet from Firebase: $e');
        }
      }
      
      // Local'den temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_balanceKey);
      await prefs.remove(_transactionsKey);
      
      _currentBalance = 0.0;
      _transactions.clear();
      
      debugPrint('Wallet data cleared');
    } catch (e) {
      debugPrint('Error clearing wallet data: $e');
    }
  }
}

class WalletTransaction {
  final String id;
  final double amount;
  final TransactionType type;
  final String paymentMethod;
  final String description;
  final DateTime timestamp;
  final TransactionStatus status;
  
  WalletTransaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.paymentMethod,
    required this.description,
    required this.timestamp,
    required this.status,
  });
  
  String get formattedAmount {
    final sign = type == TransactionType.deposit ? '+' : '-';
    return '$sign${amount.toStringAsFixed(2)}₺';
  }
  
  String get formattedDate {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
  
  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.toString().split('.').last,
      'paymentMethod': paymentMethod,
      'description': description,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.toString().split('.').last,
    };
  }
  
  factory WalletTransaction.fromJson(String jsonString) {
    final Map<String, dynamic> json = {
      'id': '',
      'amount': 0.0,
      'type': 'deposit',
      'paymentMethod': '',
      'description': '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'status': 'completed',
    };
    
    // Simple JSON parsing (in real app, use proper JSON library)
    final parts = jsonString.split('|');
    if (parts.length >= 7) {
      json['id'] = parts[0];
      json['amount'] = double.tryParse(parts[1]) ?? 0.0;
      json['type'] = parts[2];
      json['paymentMethod'] = parts[3];
      json['description'] = parts[4];
      json['timestamp'] = int.tryParse(parts[5]) ?? DateTime.now().millisecondsSinceEpoch;
      json['status'] = parts[6];
    }
    
    return WalletTransaction(
      id: json['id'],
      amount: json['amount'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TransactionType.deposit,
      ),
      paymentMethod: json['paymentMethod'],
      description: json['description'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.completed,
      ),
    );
  }
  
  String toJson() {
    return '${id}|${amount}|${type.toString().split('.').last}|${paymentMethod}|${description}|${timestamp.millisecondsSinceEpoch}|${status.toString().split('.').last}';
  }
}

enum TransactionType {
  deposit,
  withdrawal,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}
