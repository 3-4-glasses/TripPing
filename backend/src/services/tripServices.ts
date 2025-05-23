import dotenv from 'dotenv';
import admin from 'firebase-admin';
import {Trip,Itinerary,Activity} from '../struct';

dotenv.config();


/*
Itinerary
{
  "date": "2025-05-12",
  "activities": [
    {
      "from": "2025-05-12T08:00:00Z",
      "to": "2025-05-12T09:00:00Z",
      "title": "Breakfast at Cafe",
      "details": "Enjoy a traditional breakfast at the local cafe.",
      "location": { "latitude": 40.7128, "longitude": -74.0060 }
    },
    {
      "from": "2025-05-12T10:00:00Z",
      "to": "2025-05-12T12:00:00Z",
      "title": "Visit the Museum",
      "details": "Explore the history museum in the city center.",
      "location": { "latitude": 40.7129, "longitude": -74.0070 }
    }
  ]
}

*/


// // TODO implement this
// interface Itinerary {
//   id?: string; 
//   from: Date;
//   to: Date;
//   title: string;
//   details: string;
//   location: admin.firestore.GeoPoint;
// }


// From flutter pass jsonEncode

const serviceAccount = require(process.env.FIREBASE_SERVICE_ACC as string);

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}
const db = admin.firestore();

async function isUserExist(userId: string): Promise<boolean>{
    try{
        return (await db.collection("users").doc(userId).get()).exists;
    }catch(error){
        console.log(`error on is UserExist, ${userId}`);
        throw error;
    }
}

async function isTripExist(userId: string, tripId:string): Promise<boolean>{
    try{
        return (await db.collection("users").doc(userId).collection("trips").doc(tripId).get()).exists;
    }catch(error){
        console.log(`error on is UserExist, ${userId}`);
        throw error;
    }
}

async function isItineraryExist(userId: string, tripId:string,itineraryId:string): Promise<boolean>{
    try{
        return (await db.collection("users").doc(userId).collection("trips").doc(tripId).collection("itinerary").doc(itineraryId).get()).exists;
    }catch(error){
        console.log(`error on is UserExist, ${userId}`);
        throw error;
    }
}

async function createTrip(userId: string, tripData: any, itineraries: Itinerary[]): Promise<string> {
    try {
        const tripRef = db.collection("users").doc(userId).collection("trips").doc();
        console.log(`Created tripRef with ID: ${tripRef.id!}`); // Log to verify ID
        await tripRef.set(tripData); // Create the trip
        
        // Create a batch to add multiple itineraries to the trip
        const batch = db.batch();
        itineraries.forEach(itinerary => {
            const itineraryRef = tripRef.collection("itinerary").doc();
            const itineraryDate = new Date(itinerary.date);
            const activities = itinerary.activities.map((activity: any) => ({
                from: new Date(activity.from),
                to: new Date(activity.to),
                title: activity.title,
                locationDetail: activity.locationDetail,
                details: activity.details,
                ...(activity.location?.latitude != null && activity.location?.longitude != null
                    ? {
                        location: new admin.firestore.GeoPoint(
                            activity.location.latitude,
                            activity.location.longitude
                        )
                    }
                    : {})
            }));


            const itineraryObj = {
                date: itineraryDate,
                activities: activities
            };

            batch.set(itineraryRef, itineraryObj);
        });

        await batch.commit();
        return tripRef.id!; // Return the trip ID
    } catch (error:any) {
        console.error(`Error in createTrip: ${error.message}`);
        throw error;
    }
}


// Get all itinerary IDs for a given trip
async function getItineraryIds(userId: string, tripId: string): Promise<string[]> {
    console.log(`getItineraryIds called, args userId ${userId} tripId ${tripId}`);
    try {
        const tripRef = await db
        .collection("users")
        .doc(userId)
        .collection("trips")
        .doc(tripId)
        .collection("itinerary")
        .get(); 

        const itineraries: string[] = [];

        tripRef.forEach((doc) => {
        itineraries.push(doc.id); // Collect the document IDs as itinerary IDs
        });

        return itineraries;
    } catch (error) {
        console.log(`error on getItineraryIds, args userId ${userId} tripId ${tripId}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function deleteTrip(userId: string, tripId: string): Promise<void> {
  console.log(`deleteTrip called, args userId ${userId}, tripId ${tripId}`);
  try {
    const tripRef = db.collection("users").doc(userId).collection("trips").doc(tripId);
    const itineraryCollection = tripRef.collection("itinerary");

    // 1. Delete all itineraries under the trip
    const itinerariesSnap = await itineraryCollection.get();
    const batch = db.batch();

    itinerariesSnap.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();

    // 2. Delete the trip document itself
    await tripRef.delete();

    console.log(`Successfully deleted trip ${tripId} for user ${userId}`);
  } catch (error) {
    console.error(`Error deleting trip, userId: ${userId}, tripId: ${tripId}`, error);
    throw error;
  }
}


// Get all itineraries for a specific trip
async function getAllItinerary(userId: string, tripId: string):Promise<Itinerary[]> {
    console.log(`getAllItinerary called, args userId ${userId} tripId ${tripId}`);
    try {
    const tripSnap = await db
        .collection("users")
        .doc(userId)
        .collection("trips")
        .doc(tripId)
        .collection("itinerary")
        .get(); // Fetch all itineraries for the trip

    let res: Itinerary[] = [];
    tripSnap.forEach((doc) => {
        const data = doc.data();
        res.push({
        id: doc.id!, // The itinerary ID (document ID)
        date: data.date.toDate(),
        activities:data.activities,
        });
    });

    return res; // Return all itineraries as an array
    } catch (error) {
        console.log(`error on getAllItinerary, args userId ${userId} tripId ${tripId}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function getAllTrip(userId: string): Promise<Trip[]> {
  try {
    console.log(`getAllTrip called, args userId ${userId}`);
    const tripSnap = await db.collection("users").doc(userId).collection("trips").get();
    let AllTrip : Trip[] = [];
    tripSnap.forEach((doc)=>{
      const data = doc.data();
      AllTrip.push({
        id:doc.id!,
        from:data.from,
        to:data.to,
        title:data.title,
        expensesUsed:data.expensesUsed,
        expensesLimit:data.expensesLimit,
        setExpenses:data.setExpenses || {},
        variableExpenses:data.variableExpenses || {},
        items:data.items || []
      })
    })
    return AllTrip; 
  } catch (error) {
    console.log(`error on getAllTrip, args userId ${userId}`);
    console.log(`error ${error}`);
    throw error
  }
}

async function editItinerary (
  userId: string,
  itineraries: Itinerary[],
  tripId: string,
) : Promise<boolean>{
    console.log(` addActivity called, args userId ${userId} activityAddition ${JSON.stringify(itineraries)} tripId ${tripId}`);
    try{
        const itineraryCollectionRef = db
        .collection("users")
        .doc(userId)
        .collection("trips")
        .doc(tripId)
        .collection("itinerary");

        // 1. Fetch existing itinerary docs
        const existingDocs = await itineraryCollectionRef.get();

        // 2. Delete existing itinerary documents
        const deletePromises = existingDocs.docs.map((doc) => doc.ref.delete());
        await Promise.all(deletePromises);
        
        const tripRef = db.collection("users").doc(userId).collection("trips").doc(tripId);


        const batch = db.batch();
        itineraries.forEach(itinerary => {
            const itineraryRef = tripRef.collection("itinerary").doc();
            const itineraryDate = new Date(itinerary.date);
            const activities = itinerary.activities.map((activity: any) => ({
                from: new Date(activity.from),
                to: new Date(activity.to),
                title: activity.title,
                locationDetail: activity.locationDetail,
                details: activity.details,
                ...(activity.location?.latitude != null && activity.location?.longitude != null
                    ? {
                        location: new admin.firestore.GeoPoint(
                            activity.location.latitude,
                            activity.location.longitude
                        )
                    }
                    : {})
            }));


            const itineraryObj = {
                date: itineraryDate,
                activities: activities
            };

            batch.set(itineraryRef, itineraryObj);
        });

        await batch.commit();

        return true;
    }catch(error){
        console.log(`error on addActivity, args userId ${userId} activityAddition ${JSON.stringify(itineraries)} tripId ${tripId}`);
        console.log(`error ${error}`);
        throw error
    }
}




async function addItems(userId: string, tripId:string, item:string): Promise<void>{
    console.log(`addItems called, args userId ${userId} tripId ${tripId} item ${item}`);
    try{
        const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
        const tripSnap = await tripRef.get();
        const data = tripSnap.data();
        const itemDb:string[] = data!.items || [];
        if(itemDb.indexOf(item) === -1){
        itemDb.push(item);
        }
        await tripRef.set({ items:itemDb},{ merge: true });
    }catch(error){
        console.log(`error on addItems, args userId ${userId} tripId ${tripId} item ${item}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function deleteItem(userId:string, tripId:string,item:string): Promise<void>{
    console.log(`deleteItem called, args userId ${userId} tripId ${tripId} item ${item}`);
    try{
        const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
        const tripSnap = await tripRef.get();
        const data = tripSnap.data();
        const itemDb:string[] = data!.items || [];
        if(itemDb.indexOf(item) > -1){
            const updatedItems = itemDb.filter(itemArr => itemArr !== item);
            await tripRef.set({ items: updatedItems }, { merge: true });    
        }
    }catch(error){
        console.log(`error on deleteItem, args userId ${userId} tripId ${tripId} item ${item}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function incrementExpenses(userId:string,tripId:string,amount:number): Promise<void>{
    console.log(`incrementExpenses called, args userId ${userId} tripId ${tripId} amount ${amount}`);
    try{
        const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
        const tripSnap = await tripRef.get();
        const data = tripSnap.data();
        let expenses:number = data!.expensesUsed;
        expenses+=amount;
        await tripRef.set({ expensesUsed:expenses},{ merge: true });
    }catch(error){
        console.log(`error on incrementExpenses, args userId ${userId} tripId ${tripId} amount ${amount}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function deleteEvent(userId: string, tripId: string, itineraryId: string, activity: Activity): Promise<void> {
    console.log(`deleteEvent called, args userId ${userId} tripId ${tripId} item ${itineraryId} activity ${JSON.stringify(activity)}`);
    try {
        const itineraryRef = await db.collection("users").doc(userId).collection("trips").doc(tripId).collection("itinerary").doc(itineraryId);
        const itinerarySnap = await itineraryRef.get();
        const data = itinerarySnap.data();
        let eventsDay: Activity[] = data!.activities;
        
        
        const updatedActivities = eventsDay.filter((activityDay) => {

            // Convert Firestore Timestamps to milliseconds
            const storedFromMs = activityDay.from instanceof admin.firestore.Timestamp ? activityDay.from.toMillis() : activityDay.from.getTime();
            const storedToMs = activityDay.to instanceof admin.firestore.Timestamp ? activityDay.to.toMillis() : activityDay.to.getTime();

            // Convert input timestamps to milliseconds
            const inputFromMs = activity.from instanceof Date ? activity.from.getTime() : activity.from;
            const inputToMs = activity.to instanceof Date ? activity.to.getTime() : activity.to;

            return !(
                storedFromMs === inputFromMs &&
                storedToMs === inputToMs
            );
        });


        if (updatedActivities.length !== eventsDay.length) {
            await itineraryRef.update({ activities: updatedActivities });
        } 
    } catch (error) {
        console.log(`Error in deleteEvent, args userId ${userId} tripId ${tripId} item ${itineraryId} activity ${JSON.stringify(activity)}`);
        console.log(`Error: ${error}`);
        throw error;
    }
}


const addVariableExpenses = async (userId: string, tripId: string, item: any): Promise<void> => {
  try {
    const tripRef = db.collection("users").doc(userId).collection("trips").doc(tripId);
    const tripSnap = await tripRef.get();

    if (!tripSnap.exists) {
      throw new Error("Trip not found");
    }

    const data = tripSnap.data();
    let variableExpenses: Array<Record<string, number>> = data?.variableExpenses || {};
    
    // Check if the item already exists, if so, add the value to it
    if (!variableExpenses[item.name]) {
      console.log("Adding new item:", item.name);   
      variableExpenses.push({item:item.name,value:item.value})
    }
    

    // Now update the document with the merged variableExpenses
    await tripRef.set({ variableExpenses }, { merge: true });
    console.log("Firestore updated with new variableExpenses:", variableExpenses);

  } catch (error) {
    console.error("Error in addVariableExpenses:", error);
    throw error;
  }
};


async function setBudget(userId:string,tripId:string,amount:number): Promise<void>{
    console.log(`setBudget called, args userId ${userId} tripId ${tripId} amount ${amount}`);
    try{
        const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
        await tripRef.set({ expensesLimit:amount},{ merge: true });
    }catch(error){
        console.log(`error on addItems, args userId ${userId} tripId ${tripId} amount ${amount}`);
        console.log(`error ${error}`);
        throw error
    }
}

export {createTrip, getItineraryIds, 
    getAllItinerary, getAllTrip, editItinerary, 
    addItems, deleteItem, incrementExpenses, 
    deleteEvent, addVariableExpenses, setBudget,
    isTripExist,isItineraryExist,isUserExist,deleteTrip} 



