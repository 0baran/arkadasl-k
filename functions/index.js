const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnMessage = functions.firestore
  .document("users/{userId}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    const notificationData = snap.data();
    const userId = context.params.userId;

    if (!notificationData) {
      console.log("No notification data found.");
      return null;
    }

    // Get the receiver's FCM token from their user document
    const userDoc = await admin.firestore().collection("users").doc(userId).get();
    
    if (!userDoc.exists) {
      console.log(`User ${userId} does not exist.`);
      return null;
    }

    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;

    if (!fcmToken) {
      console.log(`User ${userId} does not have an FCM token.`);
      return null;
    }

    // Prepare the FCM payload
    const payload = {
      token: fcmToken,
      notification: {
        title: notificationData.title || "Yeni Bildirim",
        body: notificationData.body || "Görüntülemek için dokunun.",
      },
      data: {
        type: notificationData.type || "default",
        senderId: notificationData.senderId || "",
        click_action: "FLUTTER_NOTIFICATION_CLICK"
      }
    };

    // Send the notification
    try {
      const response = await admin.messaging().send(payload);
      console.log(`Notification sent to ${userId}:`, response);
    } catch (error) {
      console.error("Error sending notification:", error);
    }

    return null;
  }
);
