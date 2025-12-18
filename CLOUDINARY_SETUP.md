# Cloudinary Kurulum Rehberi

Bu rehber, profil fotoğrafı ve diğer görselleri yüklemek için Cloudinary'yi nasıl yapılandıracağınızı açıklar.

## 📋 Adım 1: Cloudinary Hesabı Oluşturma

1. **Cloudinary'e gidin:**
   - https://console.cloudinary.com/ adresine gidin
   - "Sign Up For Free" butonuna tıklayın

2. **Hesap oluşturun:**
   - Email adresinizi girin
   - Şifrenizi oluşturun
   - Email doğrulaması yapın

3. **Dashboard'a giriş yapın:**
   - Giriş yaptıktan sonra dashboard'a yönlendirileceksiniz

## 🔑 Adım 2: Cloud Name'i Bulma

1. **Dashboard'da Cloud Name'i bulun:**
   - Dashboard'un üst kısmında **"Cloud Name"** yazısını göreceksiniz
   - Örnek: `dxy8k7x9z` veya `my-cloud-name`
   - Bu değeri kopyalayın (ileride kullanacağız)

## ⚙️ Adım 3: Upload Preset Oluşturma

1. **Settings'e gidin:**
   - Sol menüden **"Settings"** (⚙️) seçeneğine tıklayın

2. **Upload presets bölümüne gidin:**
   - Sol menüden **"Upload"** sekmesine tıklayın
   - **"Upload presets"** bölümüne gidin

3. **Yeni preset oluşturun:**
   - **"Add upload preset"** butonuna tıklayın
   - **Preset name:** `tuning_app_upload` (veya istediğiniz bir isim)
   - **Signing mode:** **"Unsigned"** seçin (ÖNEMLİ!)
   - **Folder:** `tuning_app` (opsiyonel, otomatik klasörleme için)

4. **Preset ayarlarını yapın:**
   - **Allowed formats:** `jpg, png, webp` (veya istediğiniz formatlar)
   - **Max file size:** `10 MB` (veya istediğiniz boyut)
   - **Moderation:** İsterseniz açabilirsiniz (görsel moderasyon için)

5. **Preset'i kaydedin:**
   - **"Save"** butonuna tıklayın
   - Preset adını not edin (ileride kullanacağız)

## 💻 Adım 4: Projeye Ayarları Ekleme

1. **Config dosyasını açın:**
   - `lib/config/external_image_storage_config.dart` dosyasını açın

2. **Ayarları güncelleyin:**
   ```dart
   class ExternalImageStorageConfig {
     /// Master flag for external image uploads.
     static const bool enabled = true; // ✅ true yapın
     
     /// Cloudinary "cloud name" from the dashboard.
     static const String cloudinaryCloudName = 'dxy8k7x9z'; // ✅ Cloud Name'inizi buraya yazın
     
     /// Cloudinary unsigned upload preset name.
     static const String cloudinaryUnsignedUploadPreset = 'tuning_app_upload'; // ✅ Preset adınızı buraya yazın
     
     // Diğer ayarlar değiştirilmesine gerek yok
     static const String cloudinaryProductFolder = 'tuning_app/products';
     static const String cloudinaryProfileFolder = 'tuning_app/profiles';
     static const String cloudinaryReviewFolder = 'tuning_app/reviews';
   }
   ```

3. **Örnek doldurulmuş config:**
   ```dart
   class ExternalImageStorageConfig {
     static const bool enabled = true;
     static const String cloudinaryCloudName = 'my-cloud-name';
     static const String cloudinaryUnsignedUploadPreset = 'tuning_app_upload';
     // ... diğer ayarlar
   }
   ```

## ✅ Adım 5: Test Etme

1. **Projeyi çalıştırın:**
   ```bash
   flutter run -d chrome
   ```

2. **Profil sayfasına gidin:**
   - Uygulamada profil sayfasına gidin
   - Profil fotoğrafı yükleme butonuna tıklayın

3. **Fotoğraf yükleyin:**
   - Bir fotoğraf seçin
   - Yükleme başarılı olmalı

## 🔒 Güvenlik Notları

- **Unsigned Preset:** Unsigned preset'ler public'tir, ancak güvenli kullanım için:
  - Max file size limiti koyun
  - Allowed formats belirleyin
  - Moderation açabilirsiniz (opsiyonel)

- **Cloud Name:** Cloud name public'tir, gizli değildir
- **Preset Name:** Preset name de public'tir, gizli değildir

## ❓ Sorun Giderme

### Hata: "Cloudinary cloud name ayarlı değil"
- `cloudinaryCloudName` değerini kontrol edin
- Cloud Name'in doğru olduğundan emin olun

### Hata: "Cloudinary upload preset ayarlı değil"
- `cloudinaryUnsignedUploadPreset` değerini kontrol edin
- Preset adının doğru olduğundan emin olun
- Preset'in **"Unsigned"** modda olduğundan emin olun

### Hata: "HTTP 400" veya "HTTP 401"
- Cloud Name'in doğru olduğundan emin olun
- Preset adının doğru olduğundan emin olun
- Preset'in aktif olduğundan emin olun

### Fotoğraf yüklenmiyor
- Dosya boyutunun 10MB'dan küçük olduğundan emin olun
- Dosya formatının izin verilen formatlardan biri olduğundan emin olun
- İnternet bağlantınızı kontrol edin

## 📚 Ek Kaynaklar

- Cloudinary Dokümantasyonu: https://cloudinary.com/documentation
- Unsigned Upload: https://cloudinary.com/documentation/upload_images#unsigned_upload
- Upload Presets: https://cloudinary.com/documentation/upload_presets

## 💡 İpuçları

- Ücretsiz plan 25GB storage ve 25GB bandwidth sunar
- Daha fazla storage için ücretli planlara geçebilirsiniz
- Preset'lerde klasör yapısını organize edebilirsiniz
- Moderation özelliği ile uygunsuz içerikleri filtreleyebilirsiniz

