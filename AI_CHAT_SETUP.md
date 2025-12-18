# AI Chat Bot Kurulum Rehberi

Trendyol tarzı AI müşteri temsilcisi botu kurulumu için adım adım rehber.

## 🎯 Özellikler

- ✅ Trendyol tarzı chat widget (sağ alt köşe)
- ✅ Ücretsiz API seçenekleri (Groq veya Gemini)
- ✅ Türkçe dil desteği
- ✅ Ürün bilgisi, sipariş durumu, kargo takibi
- ✅ Profesyonel ve samimi ton

## 🚀 Hızlı Başlangıç

### Seçenek 1: Groq API (Önerilen - Çok Hızlı)

1. **Groq hesabı oluşturun:**
   - https://console.groq.com/ adresine gidin
   - "Sign Up" ile ücretsiz hesap oluşturun
   - Email doğrulaması yapın

2. **API Key oluşturun:**
   - Dashboard'a giriş yapın
   - "API Keys" sekmesine gidin
   - "Create API Key" butonuna tıklayın
   - API key'inizi kopyalayın

3. **API Key'i projeye ekleyin:**
   - `lib/config/ai_chat_config.dart` dosyasını açın
   - `groqApiKey` değişkenine API key'inizi yapıştırın:
   ```dart
   static const String groqApiKey = 'gsk_your_api_key_here';
   ```

4. **Kullanım:**
   - `useGroq = true` olduğundan emin olun
   - Uygulamayı çalıştırın
   - Sağ alt köşedeki chat butonuna tıklayın

### Seçenek 2: Google Gemini API

1. **Gemini API Key alın:**
   - https://makersuite.google.com/app/apikey adresine gidin
   - Google hesabınızla giriş yapın
   - "Create API Key" butonuna tıklayın
   - API key'inizi kopyalayın

2. **API Key'i projeye ekleyin:**
   - `lib/config/ai_chat_config.dart` dosyasını açın
   - `geminiApiKey` değişkenine API key'inizi yapıştırın:
   ```dart
   static const String geminiApiKey = 'your_api_key_here';
   ```

3. **Groq yerine Gemini kullanın:**
   - `useGroq = false` yapın
   - Uygulamayı çalıştırın

## 📝 Yapılandırma

`lib/config/ai_chat_config.dart` dosyasında şu ayarları yapabilirsiniz:

```dart
// Bot adı
static const String botName = 'Başpınar Asistanı';

// System prompt (bot'un nasıl davranacağı)
static const String systemPrompt = '''...''';

// Hangi API kullanılacak?
static const bool useGroq = true; // true = Groq, false = Gemini
```

## 🎨 Özelleştirme

### Bot İsmini Değiştirme

`lib/config/ai_chat_config.dart` dosyasında:
```dart
static const String botName = 'İstediğiniz İsim';
```

### Bot Davranışını Değiştirme

`systemPrompt` değişkenini düzenleyerek bot'un nasıl davranacağını ayarlayabilirsiniz:

```dart
static const String systemPrompt = '''Sen Başpınar Auto Garage'ın müşteri temsilcisi asistanısın. 
... (istediğiniz gibi özelleştirin)
''';
```

### Chat Widget Görünümünü Değiştirme

`lib/widgets/ai_chat_widget.dart` dosyasında:
- Renkler: `Color(0xFFFF6000)` (Trendyol turuncu)
- Boyutlar: `width: 400, height: 600`
- Konum: `bottom: 20, right: 20`

## 💡 Kullanım Örnekleri

Bot şu konularda yardımcı olabilir:
- ✅ Ürün bilgisi sorgulama
- ✅ Sipariş durumu kontrolü
- ✅ Kargo takibi
- ✅ Genel sorular
- ✅ Otomobil parçaları ve tuning konuları

## 🔧 Sorun Giderme

### API Key hatası alıyorum

1. API key'in doğru kopyalandığından emin olun
2. API key'in aktif olduğundan emin olun
3. Groq/Gemini dashboard'da kullanım limitlerinizi kontrol edin

### Mesaj gönderemiyorum

1. İnternet bağlantınızı kontrol edin
2. API key'in geçerli olduğundan emin olun
3. Console'da hata mesajlarını kontrol edin

### Bot yanıt vermiyor

1. API limitlerinizi kontrol edin (ücretsiz tier'da limitler var)
2. System prompt'un doğru olduğundan emin olun
3. Console loglarını kontrol edin

## 📊 API Limitleri

### Groq API (Ücretsiz Tier)
- ✅ Çok hızlı yanıt süresi
- ✅ Günde ~14,400 istek
- ✅ Model: llama-3.1-8b-instant

### Google Gemini API (Ücretsiz Tier)
- ✅ İyi kalite
- ✅ Günde ~1,500 istek
- ✅ Model: gemini-pro

## 🎯 İleri Seviye

### Context Ekleme (Ürün Bilgileri, Sipariş Durumu)

`lib/services/ai_chat_service.dart` dosyasında `sendMessage` metoduna context ekleyebilirsiniz:

```dart
final response = await _chatService.sendMessage(
  message: message,
  context: 'Müşteri: Ahmet Yılmaz\nAktif Siparişler: 2\nSepet: 3 ürün',
);
```

### Mesaj Geçmişi Yönetimi

Chat widget otomatik olarak mesaj geçmişini yönetir. İsterseniz `_messages` listesini özelleştirebilirsiniz.

## 📚 Kaynaklar

- [Groq API Dokümantasyonu](https://console.groq.com/docs)
- [Google Gemini API Dokümantasyonu](https://ai.google.dev/docs)
- [Flutter Chat UI Örnekleri](https://pub.dev/packages/flutter_chat_ui)

## ✅ Tamamlandı!

Artık Trendyol tarzı AI chat bot'unuz hazır! 🎉

Sorularınız için: [GitHub Issues](https://github.com/your-repo/issues)


