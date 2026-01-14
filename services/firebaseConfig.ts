import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyCCPa6IxwtEFZeRn9KYPQESFyOD2XdcYVk",
  authDomain: "ticketing-system-3ad55.firebaseapp.com",
  projectId: "ticketing-system-3ad55",
  storageBucket: "ticketing-system-3ad55.firebasestorage.app",
  messagingSenderId: "44703752154",
  appId: "1:44703752154:web:cc79d8456eab705c24eae3",
  measurementId: "G-KYEPCC8FFZ"
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);
