# GitHub Pages Deployment Rehberi

Bu rehber, Flutter web uygulamanızı GitHub Pages'e yayınlamak için adım adım talimatlar içerir.

## 🚀 Hızlı Başlangıç

### 1. GitHub Repository Oluşturma

1. GitHub'da yeni bir repository oluşturun
2. Repository'yi local'e klonlayın:
```bash
git clone https://github.com/KULLANICI_ADI/REPOSITORY_ADI.git
cd REPOSITORY_ADI
```

### 2. Projeyi GitHub'a Push Etme

```bash
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/KULLANICI_ADI/REPOSITORY_ADI.git
git push -u origin main
```

### 3. GitHub Pages Ayarları

1. GitHub repository'nize gidin
2. **Settings** > **Pages** sekmesine gidin
3. **Source** kısmında **"GitHub Actions"** seçin
4. Ayarları kaydedin

### 4. İlk Deploy

1. `.github/workflows/deploy.yml` dosyası otomatik olarak oluşturulmuştur
2. Repository adı otomatik olarak algılanır
3. `main` branch'ine push yaptığınızda otomatik deploy başlar
4. **Actions** sekmesinden deploy durumunu takip edebilirsiniz

## 📝 Manuel Deploy (Opsiyonel)

Eğer GitHub Actions kullanmak istemiyorsanız:

### Adım 1: Web Build Oluşturma

```bash
# Repository adınızı öğrenin (örnek: tuning_web)
flutter build web --release --base-href "/REPOSITORY_ADI/"
```

### Adım 2: Build Klasörünü Deploy Etme

**Seçenek 1: gh-pages Branch Kullanma**

```bash
# gh-pages branch oluştur
git checkout --orphan gh-pages
git rm -rf .

# build/web içeriğini kopyala
cp -r build/web/* .

# Commit ve push
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

**Seçenek 2: GitHub Pages Settings**

1. Settings > Pages
2. Source: "Deploy from a branch" seçin
3. Branch: `gh-pages` / `root` seçin
4. Save

## 🔧 Base Href Ayarları

Base href, uygulamanızın hangi path'te çalışacağını belirler:

### Root'ta Yayınlama (örn: username.github.io)

```bash
flutter build web --release --base-href "/"
```

### Subdirectory'de Yayınlama (örn: username.github.io/repo-name)

```bash
flutter build web --release --base-href "/REPOSITORY_ADI/"
```

## ✅ Deploy Sonrası Kontrol

1. **Actions** sekmesinde deploy'un başarılı olduğunu kontrol edin
2. Repository'nin **Settings > Pages** kısmında URL'i görün
3. URL'yi tarayıcıda açın ve uygulamanın çalıştığını kontrol edin

## 🐛 Sorun Giderme

### Build Hatası

- Flutter versiyonunu kontrol edin: `flutter --version`
- `.github/workflows/deploy.yml` içindeki `flutter-version` değerini güncelleyin

### 404 Hatası

- Base href ayarını kontrol edin
- Repository adının doğru olduğundan emin olun

### Assets Yüklenmiyor

- `web/index.html` içindeki base href'i kontrol edin
- Build sonrası `build/web` klasöründe asset'lerin olduğunu kontrol edin

### Firebase Hatası

- `firebase_options.dart` dosyasının doğru yapılandırıldığından emin olun
- Firebase Console'da web app'in doğru domain'e kayıtlı olduğunu kontrol edin

## 📚 Ek Kaynaklar

- [Flutter Web Deployment](https://docs.flutter.dev/deployment/web)
- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

