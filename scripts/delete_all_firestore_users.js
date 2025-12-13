// Firestore'dan tüm kullanıcı verilerini silmek için script
// Kullanım: node scripts/delete_all_firestore_users.js

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json'); // Firebase Console'dan indirilen service account key

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllFirestoreUsers() {
  try {
    console.log('🔍 Firestore\'da tüm kullanıcılar listeleniyor...');
    
    const usersRef = db.collection('users');
    const snapshot = await usersRef.get();
    
    if (snapshot.empty) {
      console.log('✅ Firestore\'da kullanıcı bulunamadı.');
      return;
    }
    
    console.log(`📊 ${snapshot.size} kullanıcı bulundu`);
    
    let totalDeleted = 0;
    const batch = db.batch();
    const batchSize = 500; // Firestore batch limit
    let batchCount = 0;
    
    // Alt koleksiyonlar
    const subCollections = [
      'addresses',
      'paymentMethods',
      'favorites',
      'cart',
      'orders',
      'wallet',
      'notifications'
    ];
    
    for (const userDoc of snapshot.docs) {
      const userId = userDoc.id;
      console.log(`\n🗑️  Kullanıcı siliniyor: ${userId}`);
      
      try {
        // Alt koleksiyonları sil
        for (const subCollection of subCollections) {
          try {
            const subSnapshot = await userDoc.ref.collection(subCollection).get();
            if (!subSnapshot.empty) {
              console.log(`  📁 ${subCollection}: ${subSnapshot.size} doküman bulundu`);
              
              for (const subDoc of subSnapshot.docs) {
                batch.delete(subDoc.ref);
                batchCount++;
                
                // Batch limit'e ulaşıldıysa commit et
                if (batchCount >= batchSize) {
                  await batch.commit();
                  console.log(`  ✅ Batch commit edildi (${batchCount} işlem)`);
                  batchCount = 0;
                }
              }
            }
          } catch (error) {
            console.log(`  ⚠️  ${subCollection} silinirken hata: ${error.message}`);
          }
        }
        
        // Ana kullanıcı dokümanını sil
        batch.delete(userDoc.ref);
        batchCount++;
        totalDeleted++;
        
        console.log(`  ✅ Kullanıcı işaretlendi: ${userId} (${totalDeleted}/${snapshot.size})`);
        
        // Batch limit'e ulaşıldıysa commit et
        if (batchCount >= batchSize) {
          await batch.commit();
          console.log(`  ✅ Batch commit edildi (${batchCount} işlem)`);
          batchCount = 0;
        }
        
      } catch (error) {
        console.error(`  ❌ Kullanıcı silinemedi: ${userId} - ${error.message}`);
      }
    }
    
    // Kalan işlemleri commit et
    if (batchCount > 0) {
      await batch.commit();
      console.log(`\n✅ Son batch commit edildi (${batchCount} işlem)`);
    }
    
    console.log(`\n✅ Toplam ${totalDeleted} kullanıcı Firestore'dan silindi!`);
    
    // deleted_users koleksiyonunu da temizle (varsa)
    try {
      const deletedUsersSnapshot = await db.collection('deleted_users').get();
      if (!deletedUsersSnapshot.empty) {
        console.log(`\n🗑️  deleted_users koleksiyonu temizleniyor (${deletedUsersSnapshot.size} doküman)...`);
        const deleteBatch = db.batch();
        deletedUsersSnapshot.docs.forEach(doc => {
          deleteBatch.delete(doc.ref);
        });
        await deleteBatch.commit();
        console.log(`✅ deleted_users koleksiyonu temizlendi`);
      }
    } catch (error) {
      console.log(`⚠️  deleted_users temizlenirken hata: ${error.message}`);
    }
    
  } catch (error) {
    console.error('❌ Hata:', error);
  } finally {
    process.exit(0);
  }
}

deleteAllFirestoreUsers();

