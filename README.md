<div align="center">
<img width="1200" height="475" alt="GHBanner" src="https://github.com/user-attachments/assets/0aa67016-6eaf-458a-adb2-6e31a0763ed6" />
</div>

# Run and deploy your AI Studio app

This contains everything you need to run your app locally.

View your app in AI Studio: https://ai.studio/apps/drive/1SQErHJYbBlgS3_CNL7qMTW9Vled75Qtl

## Run Locally

**Prerequisites:**  Node.js


1. Install dependencies:
   `npm install`
2. **Firebase Setup:**
   - Create a project in the [Firebase Console](https://console.firebase.google.com/).
   - Enable **Authentication** and set up the **Email/Password** sign-in method.
   - Create a **Cloud Firestore** database.
   - Copy the web app configuration from Project Settings.
   - Create a `.env` file (or add to `.env.local`) with the following keys (see `.env.example`):
     ```
     VITE_FIREBASE_API_KEY=...
     VITE_FIREBASE_AUTH_DOMAIN=...
     VITE_FIREBASE_PROJECT_ID=...
     VITE_FIREBASE_STORAGE_BUCKET=...
     VITE_FIREBASE_MESSAGING_SENDER_ID=...
     VITE_FIREBASE_APP_ID=...
     ```
   - **Initial Data:** You will need to manually create users in Firebase Authentication and corresponding user documents in the `users` Firestore collection to match the application roles (see `types.ts` for the `User` interface).

### Demo Accounts Setup

To make the "Demo Accounts" buttons on the login page work, verify you have created the following users in your Firebase project.

1.  **Create Users in Authentication:**
    *   **Email:** `client@apple.com`, **Password:** `password123`
    *   **Email:** `agent@factory.com`, **Password:** `password123`

2.  **Create User Profiles in Firestore:**
    *   Collection: `users`
    *   **Document ID:** `[UID of client@apple.com]`
        *   `email`: "client@apple.com"
        *   `name`: "John Doe"
        *   `role`: "client_user"
        *   `clientId`: "client_apple"
        *   `clientName`: "Apple Inc."
    *   **Document ID:** `[UID of agent@factory.com]`
        *   `email`: "agent@factory.com"
        *   `name`: "Jane Support"
        *   `role`: "support_agent"
        *   `clientId`: "manufacturer"

3. Run the app:
   `npm run dev`

### Security Rules

To secure your data, you must apply the security rules.

1.  Go to the **Firestore Database** section in the Firebase Console.
2.  Click on the **Rules** tab.
3.  Copy the contents of `firestore.rules` (the top part starting with `service cloud.firestore`) and paste it into the editor.
4.  Click **Publish**.

### Firestore Indexes

You may encounter an error like `The query requires an index`. This is normal for Firestore when performing compound queries (e.g., filtering by user and sorting by time).

1.  **Automatic Creation:** Open the browser developer console when the error occurs. Firebase provides a direct link in the error message. Click it to create the required index automatically in the Firebase Console.
2.  **Manual Creation:** You can check `firestore.indexes.json` for the list of required indexes.
    *   `notifications`: `userId` (ASC) + `timestamp` (DESC)
    *   `tickets`: `clientId` (ASC) + `updatedAt` (DESC)
    *   `comments`: `ticketId` (ASC) + `timestamp` (ASC)

### Troubleshooting

*   **"Missing or insufficient permissions"**: This often happens if the **Firestore User Profile** is missing for the logged-in user.
    *   Ensure you have manually created the user document in the `users` collection as described in the "Demo Accounts Setup" section.
    *   The Document ID MUST match the Authentication UID.
    *   If you are testing locally and cleared your database, you must recreate these user documents.

*Note: The `firestore.rules` file defines access policies. `storage.rules` defines file upload policies.*
