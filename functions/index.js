const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.firestore();

setGlobalOptions({ maxInstances: 10, region: "asia-south1" });

// Helper to send notification
async function sendNotification(userId, title, body, ticketId) {
  console.log(`[sendNotification] preparing for User: ${userId}, Ticket: ${ticketId}`);
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
    console.log(`[sendNotification] Firestore notification created: ${notificationRef.id}`);

    // 2. Send FCM
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      console.log(`[sendNotification] User document not found for ${userId}`);
      return;
    }

    const userData = userDoc.data();
    const tokens = userData.fcmTokens || [];
    console.log(`[sendNotification] Found ${tokens.length} tokens for user ${userId}`);

    if (tokens.length === 0) return;

    const message = {
      notification: {
        title: title,
        body: body,
      },
      android: {
        priority: "high",
        notification: {
          tag: notificationRef.id,
          channelId: "high_importance_channel_v2",
          sound: "default",
          clickAction: "FLUTTER_NOTIFICATION_CLICK"
        }
      },
      data: {
        ticketId: String(ticketId), // Ensure string
        click_action: "FLUTTER_NOTIFICATION_CLICK",
        notificationId: String(notificationRef.id) // Ensure string
      },
      tokens: tokens,
    };

    console.log(`[sendNotification] Sending multicast message...`);
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(`[sendNotification] Response: Success=${response.successCount}, Failure=${response.failureCount}`);

    // Cleanup invalid tokens
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const error = resp.error;
          console.error(`[sendNotification] Error for token ${tokens[idx]}:`, error);
          if (error && (
            error.code === 'messaging/invalid-registration-token' ||
            error.code === 'messaging/registration-token-not-registered'
          )) {
            failedTokens.push(tokens[idx]);
          }
        }
      });

      if (failedTokens.length > 0) {
        console.log(`[sendNotification] Removing ${failedTokens.length} invalid tokens`);
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

  console.log(`[notifyOnComment] Triggered for Ticket ${ticketId}, Comment User: ${comment.userId}`);

  // Get ticket to know who is who
  const ticketDoc = await db.collection("tickets").doc(ticketId).get();
  if (!ticketDoc.exists) {
    console.log(`[notifyOnComment] Ticket ${ticketId} not found`);
    return;
  }
  const ticket = ticketDoc.data();

  const senderId = comment.userId;
  const senderRole = comment.userRole;
  const clientUserId = ticket.userId || ticket.clientId; // fallback if userId missing but clientId exists?

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
    console.log(`[notifyOnComment] Sender is client, notifying staff...`);
    // Notify Manufacturer (All support agents/admins)
    const staffSnapshot = await db.collection("users")
      .where("role", "in", ["support_agent", "supervisor", "admin"])
      .get();

    console.log(`[notifyOnComment] Found ${staffSnapshot.size} staff members`);

    const notifications = staffSnapshot.docs.map(doc =>
      sendNotification(doc.id, title, body, ticketId)
    );

    await Promise.all(notifications);
  } else {
    console.log(`[notifyOnComment] Sender is staff, notifying client ${clientUserId || 'UNKNOWN'}...`);
    // Notify the original client who created the ticket
    if (clientUserId) {
      await sendNotification(
        clientUserId,
        title,
        body,
        ticketId
      );
    } else {
      console.log(`[notifyOnComment] No clientUserId found on ticket, skipping client notification.`);
    }
  }
});
