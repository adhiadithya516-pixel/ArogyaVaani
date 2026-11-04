const admin = require("firebase-admin");

let firebaseApp;

function initializeFirebaseAdmin() {
  if (firebaseApp) {
    return firebaseApp;
  }

  if (!process.env.FIREBASE_PROJECT_ID) {
    throw new Error("FIREBASE_PROJECT_ID is missing from the environment");
  }

  if (!process.env.FIREBASE_CLIENT_EMAIL) {
    throw new Error("FIREBASE_CLIENT_EMAIL is missing from the environment");
  }

  if (!process.env.FIREBASE_PRIVATE_KEY) {
    throw new Error("FIREBASE_PRIVATE_KEY is missing from the environment");
  }

  firebaseApp = admin.initializeApp({
    credential: admin.credential.cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
    }),
  });

  return firebaseApp;
}

module.exports = { initializeFirebaseAdmin };