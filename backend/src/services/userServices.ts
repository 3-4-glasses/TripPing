import dotenv from 'dotenv';
import admin from 'firebase-admin';


// Convert to express functions
dotenv.config();


  

const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS as string);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function registerUser(user_name: string, email: string, password: string): Promise<void> {
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: user_name,
    });

    console.log('User created successfully:', userRecord.uid);
  } catch (error) {
    console.error('Error creating user:', error);

  }
}


async function verifyToken(tokenReq) { 
    const token = tokenReq.headers.authorization?.split(' ')[1]; 
  
    if (!token) {
    console.log("No token provided")
      return;
    }
  
    // Use Promise-based verification instead of async/await
    admin.auth().verifyIdToken(token)
      .then((decodedToken) => {
        console.log('Decoded token:', decodedToken);
  
        const userId = decodedToken.uid;
        const email = decodedToken.email;

        
      })
      .catch((error) => {
        console.error('Error verifying token:', error);
      });
  }
  
// Initialize user in Firestore
async function initUser(userId: string, userName: string) {
  try {
    await db.collection('users').doc(userId).set({
      name: userName,
    });
    console.log('User initialized successfully');
  } catch (error) {
    console.error('Error initializing user:', error);
  }
}


