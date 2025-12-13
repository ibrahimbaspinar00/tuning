# Firebase Cloud Functions

Bu klasör, admin panelinden silinen kullanıcıları Firebase Auth'tan otomatik olarak silmek için Cloud Functions içerir.

## Kurulum

1. Firebase CLI'yi yükleyin:
```bash
npm install -g firebase-tools
```

2. Firebase'e giriş yapın:
```bash
firebase login
```

3. Projeyi başlatın:
```bash
cd functions
npm install
```

4. Cloud Functions'ı deploy edin:
```bash
firebase deploy --only functions
```

## Nasıl Çalışır?

1. Admin panelinden bir kullanıcı silindiğinde, `deleteUserByEmail` metodu:
   - Firestore'dan kullanıcı verilerini siler
   - `deleted_users` koleksiyonuna bir kayıt ekler

2. Cloud Function (`deleteUserFromAuth`) otomatik olarak:
   - `deleted_users` koleksiyonundaki yeni kayıtları dinler
   - Firebase Auth'tan kullanıcıyı siler
   - Kaydı günceller (başarılı/başarısız)

## Notlar

- Cloud Function deploy edilmeden önce, admin panelinden silinen kullanıcılar sadece Firestore'dan silinir
- Cloud Function deploy edildikten sonra, silme işlemi otomatik olarak Firebase Auth'tan da yapılır
- E-posta kontrolü Firestore'a göre yapıldığı için, Firestore'da kullanıcı yoksa e-posta tekrar kullanılabilir

