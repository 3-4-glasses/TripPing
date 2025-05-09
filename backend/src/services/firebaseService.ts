// https://firebase.google.com/docs/reference/admin/node/firebase-admin.firestore
import dotenv from 'dotenv';
import admin from 'firebase-admin';

dotenv.config();

const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS as string);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// docref= db.collection(collectionname).doc(doc) to go to path
//    collection.doc.collection.doc to go to sub collection
// docref.set to write
// docref.update to update
// docref.get to update
