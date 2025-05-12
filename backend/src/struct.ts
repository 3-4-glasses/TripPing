import admin from 'firebase-admin';

export interface Trip{
  id?: String,
  from: admin.firestore.Timestamp,
  to: admin.firestore.Timestamp,
  expensesUsed: number,
  expensesLimit: number,
  setExpenses: Record<string,number>,
  variableExpenses: Record<string,number>,
  items: String[]
}


export interface Activity {
  from: Date;
  to: Date;
  title: string;
  details: string;
  location?: admin.firestore.GeoPoint;
}

export interface Itinerary {
  id?: string;
  date: Date;  // Date of the itinerary
  activities: Activity[];  // List of activities within this itinerary
}



