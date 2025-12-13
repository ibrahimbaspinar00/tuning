const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

// Admin panelinden silinen kullanıcıları Firebase Auth'tan sil
exports.deleteUserFromAuth = functions.firestore
  .document('deleted_users/{docId}')
  .onCreate(async (snap, context) => {
    const data = snap.data();
    const email = data.email;
    const userId = data.userId;

    try {
      console.log(`🔍 Silinen kullanıcı: ${email} (${userId})`);

      // E-posta ile Firebase Auth kullanıcısını bul
      const userRecord = await admin.auth().getUserByEmail(email);
      
      if (userRecord) {
        // Firebase Auth'tan kullanıcıyı sil
        await admin.auth().deleteUser(userRecord.uid);
        console.log(`✅ Firebase Auth kullanıcısı silindi: ${email}`);
        
        // Silinen kullanıcı kaydını güncelle
        await snap.ref.update({
          authDeleted: true,
          authDeletedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      console.error(`❌ Firebase Auth silme hatası: ${error.message}`);
      
      // Hata durumunda kaydı güncelle
      await snap.ref.update({
        authDeleted: false,
        error: error.message,
      });
    }
  });

