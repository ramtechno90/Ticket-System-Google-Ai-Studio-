const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, region: "asia-south1" });

// Helper to send notification
async function sendNotification(userId, title, body, ticketId) {
  try {
    // 1. Create Notification Document in Firestore
    const notificationRef = await db.collection("notifications").add({
      userId: userId,
      title: title,
      body: body,
      ticketId: ticketId,
      timestamp: Date.now(),
      isRead: false
    });

    // 2. Send FCM
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) return;

    const userData = userDoc.data();
    const tokens = userData.fcmTokens || [];

    if (tokens.length === 0) return;

    const message = {
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: "high",
        notification: {
          tag: notificationRef.id, // Unique identity for each notification
          channelId: "high_importance_channel_v2",
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK"
        }
      },
      data: {
        ticketId: ticketId,
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        notificationId: notificationRef.id
      },
      tokens: tokens,
    };

    const response = await admin.messaging().sendMulticast(message);

    // Optional: Cleanup invalid tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
        }
      });
      if (failedTokens.length > 0) {
        await db.collection("users").doc(userId).update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens)
        });
      }
    }
  } catch (error) {
    console.error("Error sending notification:", error);
  }
}

// Trigger: New Comment (Handles user comments AND status changes via system messages)
exports.notifyOnComment = onDocumentCreated("tickets/{ticketId}/comments/{commentId}", async (event) => {
  const comment = event.data.data();
  const ticketId = event.params.ticketId;

  // Get ticket to know who is who
  const ticketDoc = await db.collection("tickets").doc(ticketId).get();
  if (!ticketDoc.exists) return;
  const ticket = ticketDoc.data();

  const senderId = comment.userId;
  const senderRole = comment.userRole;
  const clientUserId = ticket.userId;

  // Define notification details
  let title = `Ticket #${ticketId} Update`;
  let body = `${comment.userName}: ${comment.text}`;

  if (comment.isSystemMessage) {
    body = comment.text; // "Status changed to..."
  } else {
    title = `New Reply on Ticket #${ticketId}`;
  }

  // Logic:
  // 1. If Client sent it -> Notify Staff (Manufacturer)
  // 2. If Staff sent it -> Notify Client (unless Client is the sender, which shouldn't happen for staff role, but safety first)

  if (senderRole === 'client_user') {
    // Notify Manufacturer (All support agents/admins)
    const staffSnapshot = await db.collection("users")
      .where("role", "in", ["support_agent", "supervisor", "admin"])
      .get();

    const notifications = staffSnapshot.docs.map(doc =>
      sendNotification(doc.id, title, body, ticketId)
    );

    await Promise.all(notifications);
  } else {
    // Staff sent it. Notify Client.
    if (senderId !== clientUserId) {
      await sendNotification(
        clientUserId,
        title,
        body,
        ticketId
      );
    }
  }
});
