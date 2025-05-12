import dotenv from 'dotenv';
import admin from 'firebase-admin';


// Convert to express functions
dotenv.config();

const serviceAccount = require(process.env.FIREBASE_SERVICE_ACC as string);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

const db = admin.firestore();

async function registerUser(user_name: string, email: string, password: string): Promise<string> {

  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName: user_name,
    });
    return userRecord.uid;
  } catch (error) {
    console.log(`error ${error}`);
    console.log(`error on registerUser args ${user_name}, email ${email}, password ${password}`)
    throw error;
  }
}


async function verifyToken(tokenReq: any): Promise<{ uid: string; email: string, name: string } | null> {
  try {
    const authHeader = tokenReq.headers.authorization;
    const token = authHeader?.split(' ')[1];

    if (!token) {
      console.log("No token provided");
      return null;
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    console.log('Decoded token:', decodedToken);

    return {
      uid: decodedToken.uid,
      email: decodedToken.email || '',
      name: decodedToken.name || ''
    }; 
  } catch (error) {
    console.error('Error verifying token:', error);
    throw error; 
  }
}
// Initialize user in Firestore
async function initUser(userId: string, userName: string): Promise<void> {
    try {
        await db.collection('users').doc(userId).set({
        name: userName,
        });
        console.log('User initialized successfully');
    } catch (error) {
        console.log(`error on initUser ${userId} ${userName}`);
        console.log(`Error: ${error}`);
        throw error;
    }
}

export {initUser,registerUser,verifyToken};