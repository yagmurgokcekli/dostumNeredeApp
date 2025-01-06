const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNewPostNotification = functions.firestore
    .document("posts/{postId}")
    .onCreate(async (snap, context) => {
      const postData = snap.data();
      const payload = {
        notification: {
          title: "Yeni Kayıp Evcil Hayvan İlanı!",
          body: `${postData.petName} kayboldu. Hemen inceleyin!`,
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      };

      const allTokensSnapshot = await admin
      .firestore()
      .collection("user_tokens")
      .get();
      const tokens = allTokensSnapshot.docs.map((doc) => doc.data().token);

      if (tokens.length > 0) {
        await admin.messaging().sendToDevice(tokens, payload);
      }
    });
