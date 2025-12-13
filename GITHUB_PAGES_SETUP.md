# GitHub Pages 404 Hatası Çözümü

## 🔍 Sorun
GitHub Pages'te 404 hatası alıyorsunuz. Bu genellikle şu nedenlerden olur:
1. GitHub Actions workflow henüz çalışmamış
2. GitHub Pages ayarları yapılmamış
3. Workflow başarısız olmuş

## ✅ Çözüm Adımları

### 1. GitHub Pages Ayarlarını Kontrol Edin

1. GitHub repository'nize gidin: `https://github.com/ibrahimbaspinar00/tuning`
2. **Settings** sekmesine tıklayın
3. Sol menüden **Pages**'e tıklayın
4. **Source** kısmında **"GitHub Actions"** seçildiğinden emin olun
5. Eğer seçili değilse, seçin ve **Save** butonuna tıklayın

### 2. GitHub Actions Workflow'unu Kontrol Edin

1. Repository'de **Actions** sekmesine tıklayın
2. Sol tarafta **"Deploy to GitHub Pages"** workflow'unu görmelisiniz
3. Eğer hiç workflow çalışmamışsa:
   - **Actions** sekmesinde **"Deploy to GitHub Pages"** workflow'unu bulun
   - Sağ üstte **"Run workflow"** butonuna tıklayın
   - Branch olarak **main** seçin
   - **"Run workflow"** butonuna tıklayın

### 3. Workflow Durumunu Takip Edin

1. **Actions** sekmesinde en son çalışan workflow'a tıklayın
2. **build** ve **deploy** job'larının başarılı olduğunu kontrol edin
3. Eğer hata varsa, hata mesajını okuyun

### 4. Manuel Tetikleme (Gerekirse)

Eğer workflow otomatik çalışmamışsa:

1. **Actions** sekmesine gidin
2. Sol menüden **"Deploy to GitHub Pages"** workflow'unu seçin
3. Sağ üstte **"Run workflow"** butonuna tıklayın
4. Branch: **main** seçin
5. **"Run workflow"** butonuna tıklayın

### 5. Deploy Tamamlandıktan Sonra

1. Workflow başarılı olduktan sonra 1-2 dakika bekleyin
2. **Settings > Pages**'e gidin
3. URL'i kontrol edin: `https://ibrahimbaspinar00.github.io/tuning/`
4. Tarayıcıda açın

## 🐛 Yaygın Hatalar ve Çözümleri

### Hata: "Workflow not found"
- `.github/workflows/deploy.yml` dosyasının repository'de olduğundan emin olun
- Dosyayı tekrar push edin

### Hata: "Permission denied"
- Repository Settings > Actions > General
- "Workflow permissions" kısmında "Read and write permissions" seçin
- "Allow GitHub Actions to create and approve pull requests" seçeneğini işaretleyin

### Hata: "Flutter version not found"
- `.github/workflows/deploy.yml` içindeki `flutter-version` değerini kontrol edin
- Geçerli bir Flutter versiyonu kullanın (örn: '3.24.0')

### Hata: "Build failed"
- Actions sekmesinde hata detaylarını kontrol edin
- Genellikle bağımlılık veya yapılandırma hatasıdır

## 📝 Hızlı Kontrol Listesi

- [ ] GitHub Pages Settings'te "GitHub Actions" seçili mi?
- [ ] Actions sekmesinde workflow çalıştı mı?
- [ ] Workflow başarılı oldu mu?
- [ ] Deploy job'ı tamamlandı mı?
- [ ] 1-2 dakika beklediniz mi?

## 🔄 Workflow'u Yeniden Tetikleme

Eğer hala çalışmıyorsa, boş bir commit yaparak workflow'u tetikleyebilirsiniz:

```bash
git commit --allow-empty -m "Trigger GitHub Pages deployment"
git push origin main
```

Bu, workflow'u otomatik olarak tetikleyecektir.

