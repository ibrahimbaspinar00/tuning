import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_chat_config.dart';

/// AI Chat Bot servisi
/// Groq API veya Google Gemini API kullanır
class AIChatService {
  /// Mesaj gönder ve yanıt al
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? context, // Ürün bilgileri, sipariş durumu vs.
  }) async {
    try {
      if (AIChatConfig.useGroq) {
        return await _sendMessageGroq(
          message: message,
          conversationHistory: conversationHistory,
          context: context,
        );
      } else {
        return await _sendMessageGemini(
          message: message,
          conversationHistory: conversationHistory,
          context: context,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ AI Chat hatası: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Daha spesifik hata mesajları
      if (e.toString().contains('TimeoutException') || e.toString().contains('timeout')) {
        return '⏳ İstek zaman aşımına uğradı. Lütfen tekrar deneyin. 😊';
      } else if (e.toString().contains('SocketException') || e.toString().contains('network')) {
        return '🌐 İnternet bağlantınızı kontrol edin ve tekrar deneyin. 😊';
      }
      
      return 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. 😊';
    }
  }

  /// Groq API ile mesaj gönder
  Future<String> _sendMessageGroq({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? context,
  }) async {
    final apiKey = AIChatConfig.groqApiKey;
    if (apiKey == 'YOUR_GROQ_API_KEY' || apiKey.isEmpty) {
      return '⚠️ Lütfen Groq API anahtarınızı `lib/config/ai_chat_config.dart` dosyasına ekleyin.\n\n1. https://console.groq.com/ adresine gidin\n2. Ücretsiz hesap oluşturun\n3. API Key oluşturun\n4. `groqApiKey` değişkenine ekleyin';
    }
    
    // API key format kontrolü
    if (!apiKey.startsWith('gsk_')) {
      debugPrint('⚠️ API key formatı geçersiz görünüyor');
    }

    // Mesaj geçmişini hazırla
    final messages = <Map<String, dynamic>>[];
    
    // System prompt
    String systemMessage = AIChatConfig.systemPrompt;
    if (context != null && context.isNotEmpty) {
      systemMessage += '\n\nMüşteri bilgileri:\n$context';
    }
    messages.add({
      'role': 'system',
      'content': systemMessage,
    });

    // Konuşma geçmişi
    if (conversationHistory != null) {
      for (var msg in conversationHistory) {
        messages.add({
          'role': msg['role'] ?? 'user',
          'content': msg['content'] ?? '',
        });
      }
    }

    // Yeni mesaj
    messages.add({
      'role': 'user',
      'content': message,
    });

    // API isteği
    debugPrint('📤 Groq API isteği gönderiliyor...');
    debugPrint('Model: ${AIChatConfig.groqModel}');
    debugPrint('Mesaj sayısı: ${messages.length}');
    
    final response = await http.post(
      Uri.parse(AIChatConfig.groqApiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': AIChatConfig.groqModel,
        'messages': messages,
        'temperature': 0.7,
        'max_tokens': 1000, // Artırıldı
      }),
    ).timeout(const Duration(seconds: 30));
    
    debugPrint('📥 Groq API yanıtı: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['choices']?[0]?['message']?['content'] ?? '';
      
      if (content.isEmpty) {
        debugPrint('⚠️ Groq API boş yanıt döndü: ${response.body}');
        return 'Üzgünüm, yanıt alınamadı. Lütfen tekrar deneyin. 😊';
      }
      
      return content.trim();
    } else {
      debugPrint('❌ Groq API hatası: ${response.statusCode}');
      debugPrint('Yanıt: ${response.body}');
      
      // Daha detaylı hata mesajları
      if (response.statusCode == 401) {
        debugPrint('❌ API key geçersiz - 401 hatası');
        debugPrint('API Key (ilk 10 karakter): ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...');
        return '⚠️ API anahtarı geçersiz veya süresi dolmuş.\n\nLütfen:\n1. https://console.groq.com/ adresine gidin\n2. Yeni bir API Key oluşturun\n3. `lib/config/ai_chat_config.dart` dosyasındaki `groqApiKey` değerini güncelleyin\n\nGeçici olarak Gemini API kullanmak için `useGroq = false` yapabilirsiniz.';
      } else if (response.statusCode == 429) {
        return '⏳ Çok fazla istek gönderildi. Lütfen birkaç saniye bekleyip tekrar deneyin. 😊';
      } else if (response.statusCode >= 500) {
        return '🔧 Sunucu hatası oluştu. Lütfen birkaç dakika sonra tekrar deneyin. 😊';
      }
      
      return 'Üzgünüm, bir hata oluştu (${response.statusCode}). Lütfen tekrar deneyin. 😊';
    }
  }

  /// Google Gemini API ile mesaj gönder
  Future<String> _sendMessageGemini({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? context,
  }) async {
    if (AIChatConfig.geminiApiKey == 'YOUR_GEMINI_API_KEY') {
      return '⚠️ Lütfen Gemini API anahtarınızı `lib/config/ai_chat_config.dart` dosyasına ekleyin.\n\n1. https://makersuite.google.com/app/apikey adresine gidin\n2. Ücretsiz API key oluşturun\n3. `geminiApiKey` değişkenine ekleyin';
    }

    // Context hazırla
    String fullPrompt = AIChatConfig.systemPrompt;
    if (context != null && context.isNotEmpty) {
      fullPrompt += '\n\nMüşteri bilgileri:\n$context';
    }

    // Konuşma geçmişi
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      fullPrompt += '\n\nKonuşma geçmişi:';
      for (var msg in conversationHistory) {
        final role = msg['role'] == 'assistant' ? 'Asistan' : 'Müşteri';
        fullPrompt += '\n$role: ${msg['content']}';
      }
    }

    fullPrompt += '\n\nMüşteri: $message\nAsistan:';

    // API isteği
    final response = await http.post(
      Uri.parse('${AIChatConfig.geminiApiUrl}?key=${AIChatConfig.geminiApiKey}'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': fullPrompt}
            ]
          }
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final content = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
      return content.trim();
    } else {
      debugPrint('Gemini API hatası: ${response.statusCode} - ${response.body}');
      return 'Üzgünüm, bir hata oluştu. Lütfen tekrar deneyin. 😊';
    }
  }
}


