// Firebase'den tüm kullanıcıları silmek için script
// Kullanım: node scripts/delete_all_users.js

const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json'); // Firebase Console'dan indirilen service account key

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

async function deleteAllUsers() {
  try {
    console.log('🔍 Tüm kullanıcılar listeleniyor...');
    
    let nextPageToken;
    let totalDeleted = 0;
    
    do {
      const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
      
      console.log(`📊 ${listUsersResult.users.length} kullanıcı bulundu`);
      
      // Kullanıcıları sil
      for (const user of listUsersResult.users) {
        try {
          await admin.auth().deleteUser(user.uid);
          totalDeleted++;
          console.log(`✅ Silindi: ${user.email || user.uid} (${totalDeleted}/${listUsersResult.users.length})`);
        } catch (error) {
          console.error(`❌ Silinemedi: ${user.email || user.uid} - ${error.message}`);
        }
      }
      
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);
    
    console.log(`\n✅ Toplam ${totalDeleted} kullanıcı silindi!`);
    
  } catch (error) {
    console.error('❌ Hata:', error);
  } finally {
    process.exit(0);
  }
}

deleteAllUsers();

