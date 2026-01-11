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
2. Set the `GEMINI_API_KEY` in [.env.local](.env.local) to your Gemini API key
3. **Firebase Setup:**
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
4. Run the app:
   `npm run dev`
