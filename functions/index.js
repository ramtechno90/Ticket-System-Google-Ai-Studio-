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
    await db.collection("notifications").add({
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
      data: {
        ticketId: ticketId,
        click_action: "FLUTTER_NOTIFICATION_CLICK"
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

// Trigger: Ticket Status Update
exports.onTicketUpdate = onDocumentUpdated("tickets/{ticketId}", async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  const ticketId = event.params.ticketId;

  // Check for status change
  if (before.status !== after.status) {
    const newStatus = after.status;
    const clientUserId = after.userId; // The creator (Client)

    // Notify the Client User
    await sendNotification(
      clientUserId,
      `Ticket #${ticketId} Update`,
      `Status changed to: ${newStatus}`,
      ticketId
    );
  }
});

// Trigger: New Comment
exports.onCommentCreate = onDocumentCreated("tickets/{ticketId}/comments/{commentId}", async (event) => {
  const comment = event.data.data();
  const ticketId = event.params.ticketId;

  // Get ticket to know who is who
  const ticketDoc = await db.collection("tickets").doc(ticketId).get();
  if (!ticketDoc.exists) return;
  const ticket = ticketDoc.data();

  // Determine Sender and Recipient
  const senderId = comment.userId;
  const senderRole = comment.userRole;

  // If Staff commented -> Notify Client
  if (senderRole !== 'client_user') {
    const clientUserId = ticket.userId;
    if (senderId !== clientUserId) { // Don't notify self (if staff created ticket for themselves?)
      await sendNotification(
        clientUserId,
        `New Reply on Ticket #${ticketId}`,
        `${comment.userName}: ${comment.text}`,
        ticketId
      );
    }
  }
});
