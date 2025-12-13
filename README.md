# Tuning Web

Modern ve responsive Flutter web uygulaması - Otomobil tuning ürünleri e-ticaret platformu.

## 🚀 Özellikler

- ✅ Responsive tasarım (Mobil, Tablet, Desktop)
- ✅ Firebase Authentication & Firestore
- ✅ Ürün kataloğu ve detay sayfaları
- ✅ Sepet ve sipariş yönetimi
- ✅ Kullanıcı profili ve favoriler
- ✅ Değerlendirme sistemi
- ✅ Modern UI/UX tasarımı

## 📱 Teknolojiler

- **Flutter Web** - Modern web framework
- **Firebase** - Backend servisleri
- **Material Design 3** - UI framework
- **Google Fonts** - Tipografi

## 🛠️ Kurulum

### Gereksinimler

- Flutter SDK (3.9.2+)
- Dart SDK
- Firebase projesi

### Adımlar

1. Repository'yi klonlayın:
```bash
git clone https://github.com/KULLANICI_ADI/tuning_web.git
cd tuning_web
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Firebase yapılandırmasını ekleyin:
   - `lib/firebase_options.dart` dosyasını Firebase Console'dan oluşturun
   - Firebase projenizi yapılandırın

4. Uygulamayı çalıştırın:
```bash
flutter run -d chrome
```

## 🌐 GitHub Pages ile Yayınlama

### Otomatik Deploy (GitHub Actions)

Proje, GitHub Actions ile otomatik olarak GitHub Pages'e deploy edilir.

#### Kurulum Adımları:

1. **GitHub Repository Ayarları:**
   - Repository'nizi GitHub'a push edin
   - Settings > Pages > Source: "GitHub Actions" seçin

2. **Workflow Dosyasını Düzenleyin:**
   - `.github/workflows/deploy.yml` dosyasını açın
   - `--base-href "/tuning_web/"` kısmını repository adınıza göre değiştirin
     - Eğer repository root'ta yayınlayacaksanız: `--base-href "/"`
     - Eğer subdirectory'de yayınlayacaksanız: `--base-href "/REPOSITORY_ADI/"`

3. **Flutter Versiyonunu Güncelleyin:**
   - `.github/workflows/deploy.yml` içinde `flutter-version` değerini kontrol edin

4. **Deploy:**
   - `main` branch'ine push yaptığınızda otomatik deploy başlar
   - Actions sekmesinden deploy durumunu takip edebilirsiniz

### Manuel Deploy

Eğer manuel deploy yapmak isterseniz:

```bash
# Web build oluştur
flutter build web --release --base-href "/tuning_web/"

# build/web klasörünü GitHub Pages'e push edin
# veya gh-pages branch'ine commit edin
```

### Repository Adına Göre Base Href Ayarları

- **Root'ta yayınlama:** `--base-href "/"`
- **Subdirectory'de yayınlama:** `--base-href "/REPOSITORY_ADI/"`

Örnek: Eğer repository adınız `my-tuning-app` ise:
```bash
flutter build web --release --base-href "/my-tuning-app/"
```

## 📁 Proje Yapısı

```
lib/
├── config/          # Route yapılandırmaları
├── model/           # Veri modelleri
├── sayfalar/        # Sayfa widget'ları
├── services/        # Firebase ve API servisleri
├── theme/           # Tema ve tasarım sistemi
├── utils/           # Yardımcı fonksiyonlar
└── widgets/         # Yeniden kullanılabilir widget'lar
```

## 🔧 Geliştirme

### Responsive Tasarım

Proje, `lib/utils/responsive_helper.dart` ile responsive tasarım desteği sunar:

- Mobil: < 576px
- Tablet: 768px - 1024px
- Desktop: ≥ 1200px

### Firebase Yapılandırması

Firebase servisleri:
- Authentication (Kullanıcı girişi)
- Firestore (Veritabanı)
- Storage (Görsel depolama)

## 📄 Lisans

Bu proje özel bir projedir.

## 👨‍💻 Geliştirici

Tuning Web - Modern e-ticaret platformu
