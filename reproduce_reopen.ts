
import { initializeApp } from 'firebase/app';
import { getAuth, signInWithEmailAndPassword } from 'firebase/auth';
import { getFirestore, doc, getDoc, updateDoc } from 'firebase/firestore';

// Hardcoded config from .env to run in Node
const firebaseConfig = {
    apiKey: "AIzaSyCCPa6IxwtEFZeRn9KYPQESFyOD2XdcYVk",
    authDomain: "ticketing-system-3ad55.firebaseapp.com",
    projectId: "ticketing-system-3ad55",
    storageBucket: "ticketing-system-3ad55.firebasestorage.app",
    messagingSenderId: "44703752154",
    appId: "1:44703752154:web:cc79d8456eab705c24eae3",
    measurementId: "G-KYEPCC8FFZ"
};

console.log("Initializing Firebase...");
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

async function testReopen() {
    try {
        console.log("Authenticating as Client (Apple)...");
        const userCredential = await signInWithEmailAndPassword(auth, 'client@apple.com', 'password123');
        const user = userCredential.user;
        console.log(`Logged in as: ${user.uid}`);

        const ticketId = 'T-4801';
        console.log(`Fetching ticket ${ticketId}...`);
        const ticketRef = doc(db, 'tickets', ticketId);
        const ticketSnap = await getDoc(ticketRef);

        if (!ticketSnap.exists()) {
            console.error("Ticket not found!");
            return;
        }

        const ticket = ticketSnap.data();
        console.log(`Ticket found via script logic. Owner ID: ${ticket.userId}`);
        console.log(`Current User ID: ${user.uid}`);
        console.log(`Match? ${ticket.userId === user.uid}`);

        console.log("Attempting Update to 'Acknowledge'...");

        // Simulate exactly what the app does
        const updates = {
            status: 'Acknowledge',
            updatedAt: Date.now()
        };

        await updateDoc(ticketRef, updates);
        console.log("SUCCESS! Ticket updated.");

    } catch (error: any) {
        console.error("FAILURE! Error Code:", error.code);
        console.error("Error Message:", error.message);
    } finally {
        process.exit(0);
    }
}

testReopen();
