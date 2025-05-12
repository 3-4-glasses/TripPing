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


const serviceAccount = require(process.env.GOOGLE_APPLICATION_CREDENTIALS as string);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

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

async function createTrip(userId: string, tripData: any, itineraries: Itinerary[]): Promise<string>  {
    console.log(`error on createTrip, args userId ${userId} tripData ${tripData} itenerary ${itineraries}`);
    try {
        const tripRef = db.collection("users").doc(userId).collection("trips").doc();
        await tripRef.set(tripData); // Create the trip
        
        // Create a batch to add multiple itineraries to the trip
        const batch = db.batch();
        itineraries.forEach(itinerary => {
        const itineraryRef = tripRef.collection("itinerary").doc(); // Create a new itinerary doc
        const itineraryDate=new Date(itinerary.date);
        const activites = itinerary.activities.map((activity: any) => ({
            from: new Date(activity.from),
            to: new Date(activity.to),
            title: activity.title,
            details: activity.details,
            location: new admin.firestore.GeoPoint(activity.location.latitude, activity.location.longitude),}
        ));
        
        const itineraryObj = {
            date:itineraryDate,
            activities:activites
        };

        batch.set(itineraryRef, itineraryObj); // Add each itinerary to the batch
        });

        // Commit the batch to Firestore
        await batch.commit();

        return tripRef.id; // Return the trip ID
    } catch (error) {
        console.log(`error on createTrip, args userId ${userId} tripData ${tripData} itenerary ${itineraries}`);
        console.log(`error ${error}`);
        throw error
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
        id: doc.id, // The itinerary ID (document ID)
        date: data.date.toDate(),
        activities:data.activities
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
        id:doc.id,
        from:data.from,
        to:data.to,
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

async function editActivity (
  userId: string,
  activity: Activity[],
  tripId: string,
  itineraryId: string
) : Promise<boolean>{
    console.log(`addActivity called, args userId ${userId} activityAddition ${activity} tripId ${tripId} itineraryId ${itineraryId}`);
    try{
        const itineraryRef = await db
        .collection("users")
        .doc(userId)
        .collection("trips")
        .doc(tripId)
        .collection("itinerary")
        .doc(itineraryId);
        const itinerarySnap=await itineraryRef.get();
        const data = itinerarySnap.data();
        if(Array.isArray(activity)){
            const updatedActivities = [activity];
            await itineraryRef.set({ activities: updatedActivities },{merge:true});
        }
        return true;
    }catch(error){
        console.log(`error on addActivity, args userId ${userId} activityAddition ${activity} tripId ${tripId} itineraryId ${itineraryId}`);
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

async function deleteEvent(userId:string,tripId:string,itineraryId:string,activity:Activity): Promise<void> {
    console.log(`deleteEvent called, args userId ${userId} tripId ${tripId} item ${itineraryId} activity ${activity}`);
    try{
        const itineraryRef = await db.collection("users").doc(userId).collection("trips").doc(tripId).collection("itinerary").doc(itineraryId);
        const itinerarySnap = await itineraryRef.get();
        const data = itinerarySnap.data();
        let eventsDay:Activity[] = data!.activities;
        const updatedActivities = eventsDay.filter((activityDay) => {
            const sameLocation =
                (!activityDay.location && !activity.location) || // both undefined/null
                (activityDay.location &&
                activity.location &&
                activityDay.location.latitude === activity.location.latitude &&
                activityDay.location.longitude === activity.location.longitude);

            return !(
                activityDay.details === activity.details &&
                activityDay.title === activity.title &&
                new Date(activityDay.from).getTime() === new Date(activity.from).getTime() &&
                new Date(activityDay.to).getTime() === new Date(activity.to).getTime() &&
                sameLocation
            );
        });

        await itineraryRef.update({ activities: updatedActivities });
    }catch(error){
        console.log(`error on deleteEvent, args userId ${userId} tripId ${tripId} item ${itineraryId} activity ${activity}`);
        console.log(`error ${error}`);
        throw error
    }
}


async function addVariableExpenses(userId: string, tripId: string, item: any): Promise<void> {
    console.log(`addVariableExpenses called, args userId ${userId} tripId ${tripId} item ${item}`);
    try {
        const tripRef = db.collection("users").doc(userId).collection("trips").doc(tripId);
        const tripSnap = await tripRef.get();

        if (!tripSnap.exists) {
        throw new Error("Trip not found");
        }

        const data = tripSnap.data();
        let variableExpenses: Record<string, number> = data?.variableExpenses || {};

        if (!variableExpenses[item.name]) {
        variableExpenses[item.name] = item.value;
        await incrementExpenses(userId,tripId,item.value);
        }

        await tripRef.set({ variableExpenses:variableExpenses }, { merge: true });
    } catch (error) {
        console.log(`error on addVariableExpenses, args userId ${userId} tripId ${tripId} item ${item}`);
        console.log(`error ${error}`);
        throw error
    }
}

async function setBudget(userId:string,tripId:string,amount:number): Promise<void>{
    console.log(`setBudget called, args userId ${userId} tripId ${tripId} amount ${amount}`);
    try{
        const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
        await tripRef.set({ expensesUsed:amount},{ merge: true });
    }catch(error){
        console.log(`error on addItems, args userId ${userId} tripId ${tripId} amount ${amount}`);
        console.log(`error ${error}`);
        throw error
    }
}

export {createTrip, getItineraryIds, 
    getAllItinerary, getAllTrip, editActivity, 
    addItems, deleteItem, incrementExpenses, 
    deleteEvent, addVariableExpenses, setBudget,
    isTripExist,isItineraryExist,isUserExist} 

// async function decrementExpenses(userId:string,tripId:string,amount:number){
//     try{
//     const tripRef = await db.collection("users").doc(userId).collection("trips").doc(tripId);
//     const tripSnap = await tripRef.get();
//     const data = tripSnap.data();
//     let expenses:number = data!.expensesUsed;
//     expenses-=amount;
//     await tripRef.set({ expensesUsed:expenses},{ merge: true });
//   }catch(error){

//   }
// }



// Not needed i think
// async function addSetExpenses(userId: string, tripId: string, item: any) {
//   try {
//     const tripRef = db.collection("users").doc(userId).collection("trips").doc(tripId);
//     const tripSnap = await tripRef.get();

//     if (!tripSnap.exists) {
//       throw new Error("Trip not found");
//     }

//     const data = tripSnap.data();
//     let setExpenses: Record<string, number> = data?.setExpenses || {};

//     if (!setExpenses[item.name]) {
//       setExpenses[item.name] = item.value;
//       incrementExpenses(userId,tripId,item.value);
//     }

//     await tripRef.set({ setExpenses }, { merge: true });
//   } catch (error) {
    
//   }
// }



