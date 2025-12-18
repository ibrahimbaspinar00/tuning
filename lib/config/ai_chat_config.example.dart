/// AI Chat Bot yapılandırması - ÖRNEK DOSYA
/// 
/// Bu dosyayı kopyalayıp `ai_chat_config.dart` olarak kaydedin
/// ve kendi API key'lerinizi ekleyin.
/// 
/// Ücretsiz API seçenekleri:
/// 1. Groq API (Önerilen): https://console.groq.com/ - Ücretsiz tier var, çok hızlı
/// 2. Google Gemini API: https://makersuite.google.com/app/apikey - Ücretsiz tier var
/// 3. Ollama: Tamamen ücretsiz, local çalışır
class AIChatConfig {
  // Groq API (Önerilen - Ücretsiz tier var)
  static const String groqApiKey = 'YOUR_GROQ_API_KEY'; // https://console.groq.com/ adresinden alın
  static const String groqApiUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String groqModel = 'llama-3.1-8b-instant'; // Ücretsiz tier için hızlı model
  
  // Alternatif: Google Gemini API
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY'; // https://makersuite.google.com/app/apikey
  static const String geminiApiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  // Hangi API kullanılacak?
  static const bool useGroq = true; // true = Groq, false = Gemini
  
  // Bot ayarları
  static const String botName = 'Servis Asistanı';
  static const String systemPrompt = '''Sen Başpınar Auto Garage'ın müşteri temsilcisi asistanısın. 
Trendyol tarzı profesyonel, samimi ve yardımcı bir ton kullan. 

Görevlerin:
- Müşterilere ürünler hakkında bilgi vermek
- Sipariş durumlarını kontrol etmek
- Kargo takibi yapmak
- Genel soruları yanıtlamak
- Otomobil parçaları ve tuning konularında yardımcı olmak

Kurallar:
- Her zaman Türkçe konuş
- Kısa ve öz cevaplar ver
- Emoji kullan (😊, ✅, 🚗, 🔧 gibi)
- Müşteriye saygılı ve profesyonel ol
- Bilmediğin bir şey için "Üzgünüm, bu konuda size yardımcı olamam" de
''';
}

