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


export interface ItineraryQuery {
    location?: string[];
    priceRange?: string[];
    priceLevel?: number[];
    type?: string[];
    isGoodForChildren?: boolean[];
    isGoodForGroups?: boolean[];
    servesBeer?: boolean[];
    servesBreakfast?: boolean[];
    servesBrunch?: boolean[];
    servesCocktail?: boolean[];
    servesCoffee?: boolean[];
    servesDessert?: boolean[];
    servesDinner?: boolean[];
    servesLunch?: boolean[];
    servesVegetarianFood?: boolean[];
    servesWine?: boolean[];
    hasLiveMusic?: boolean[];
    allowsDogs?: boolean[];
    accessibilityOptions?: string[];
    miscellaneous?: {
      time: string;
      activity: string;
    }[];
  }
  
export interface ItineraryDays {
    [day: string]: ItineraryQuery;
}



