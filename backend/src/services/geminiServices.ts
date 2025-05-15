import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';
import {Client,TextSearchRequest,PlaceType1,LatLng} from '@googlemaps/google-maps-services-js';
import { Activity, Itinerary } from "../struct";
import { sanitizeJsonString } from "../utils/jsonSanitizer";
import admin from 'firebase-admin';

dotenv.config();
const client = new Client({});

const gemini = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const model = gemini.getGenerativeModel({ model: "gemini-2.0-flash-lite" }); // fuck change this idk what model to use

async function validateInput(input: string): Promise<boolean>{
  const systemInst = `  
    Your task is to return whether the input string contains the following fields, do not offer explanations and only return true or false:
    Dates
    Destination
    Activities
    Time of day
    Accommodation
    Transportation
    Total budget
    And return true if it is a coherent plan
  `;
  const result = await model.generateContent([systemInst, input]);
  const response = await result.response;
  const text = await response.text();
  console.log(text);
  return text.trim().toLowerCase() === 'true';
}

async function  extractItienaryFeatures(input: string): Promise<string> {
  const systemInst = `
    You are a helpful itinerary planning assistant. Your task is to extract structured information from a free-text travel description written by a user.
    The user's message may contain destination, travel dates, daily plans, activity preferences, time references, and miscellaneous instructions.
    Make each field an array that is not malformed so that we know what we want to do, and how it correlates to the other fields, and have
    miscellaneous if it doenst fit the other fields, the miscellaneous array shape doesnt have to fit the other field's shape
    Return the data in the following in a strict JSON format, no explanations:
      {
        "activityTime":[string]
        "textExplanation": [string]
        "location": [string],
        "priceRange": [string],
        "priceLevel": [number],
        "type": [string],
        "isGoodForChildren": [boolean],
        "isGoodForGroups": [boolean],
        "servesBeer": [boolean],
        "servesBreakfast": [boolean],
        "servesBrunch": [boolean],
        "servesCocktail": [boolean],
        "servesCoffee": [boolean],
        "servesDessert": [boolean],
        "servesDinner": [boolean],
        "servesLunch": [boolean],
        "servesVegetarianFood": [boolean],
        "servesWine": [boolean],
        "hasLiveMusic": [boolean],
        "allowsDogs": [boolean],
        "accessibilityOptions": [string],
      }
  `;
  const result = await model.generateContent([systemInst, input]);
  const response = await result.response;
  const text = await response.text();
  return text.trim();
}

function getParams(item: any){
      const query = item.query ?? "";
      if (!query) return; // Skip if required field is missing

      const type = item.type ?? undefined;
      const region = item.region ?? undefined;
      const radius = typeof item.radius === "number" ? item.radius : undefined;
      const minprice = typeof item.minprice === "number" ? item.minprice : undefined;
      const maxprice = typeof item.maxprice === "number" ? item.maxprice : undefined;
      const location = item.location;
      const lat = location?.latitude;
      const lng = location?.longitude;
      const hasValidLocation = typeof lat === "number" && typeof lng === "number";

      const request: TextSearchRequest["params"] = {
        query,
        key: process.env.GEMINI_API_KEY!,
        ...(type && { type: type as PlaceType1 }),
        ...(region && { region }),
        ...(radius !== undefined && hasValidLocation && { radius }),
        ...(minprice !== undefined && { minprice }),
        ...(maxprice !== undefined && { maxprice }),
        ...(hasValidLocation && {
          location: { lat, lng } as LatLng,
        }),
      };
      return request;
}

async function itenararyAI(tripItinerary:Itinerary[] ,input: string): Promise<Itinerary[]> {
  const systemInst = `
    You are an assistant that generates Google Places Text Search API query JSON.
    You will be given two inputs, the user's intent and the trip's entire itinerary
    The user's message may contain destination, travel dates, activity preferences, time references, and miscellaneous instructions.
    The entirety of the trip's itinerary with its activity for each day will be given
    
    Your task is to create a query for google places that aligns with the user's intent, AND the trip's existing itinerary
    IMPORTANT: MAKE SURE QUERY IS WITHIN THE SAME GENERAL AREA AS THE PREVIOUS ACTIVITIES; 
      For example: if the previous activities are generally located in Bali, dont give locations that are in other parts of indonesia
    Return the data in the following in a strict JSON format, no explanations:
    Activities:[{
      location?: {
        longitude: number 
        latitude: number
      };
      maxprice?: number;
      minprice?: number;
      query: string;
      radius?: number;
      region?: string;
      type?: string;
      }
    },{
      location?: {
        longitude: number 
        latitude: number
      };
      maxprice?: number;
      minprice?: number;
      query: string;
      radius?: number;
      region?: string;
      type?: string;
      }
    }]
    -  Set "location's longitude and latitude" using a known coordinate (if unavailable, omit).
    =  If there are tags such as the ones below, add it to the query string
        "location": [string],
        "priceRange": [string],
        "priceLevel": [number],
        "type": [string],
        "isGoodForChildren": [boolean],
        "isGoodForGroups": [boolean],
        "servesBeer": [boolean],
        "servesBreakfast": [boolean],
        "servesBrunch": [boolean],
        "servesCocktail": [boolean],
        "servesCoffee": [boolean],
        "servesDessert": [boolean],
        "servesDinner": [boolean],
        "servesLunch": [boolean],
        "servesVegetarianFood": [boolean],
        "servesWine": [boolean],
        "hasLiveMusic": [boolean],
        "allowsDogs": [boolean],
        "accessibilityOptions": [string],
  `;
  const result = await model.generateContent([systemInst, `User's input: ${input} Trip's itinerary: ${JSON.stringify(tripItinerary)}`]);
  const response = await result.response;
  const text = await response.text();
  let parsed;
  
  try{ 
    parsed = JSON.parse(sanitizeJsonString(text));
  } catch (error) {
    console.error("Failed to parse Gemini response:", error);
    console.error("Raw output:", text);
    throw error;
  }
  const addActivityRes: any[] = [];
  if (Array.isArray(parsed.Activities)) {
    for (const activity of parsed.Activities) {
      const request = getParams(activity);
      if(!request) continue;
      try {
        const res = await client.textSearch({ params: request });
        addActivityRes.push(res.data);
      } catch (error) {
        console.error(`Failed request for:`, error);
        throw error;
      }
    }
  } else {
    console.error("Invalid or missing Activities array");
  }
  const hasProposals = addActivityRes.length > 0;
  const cleanUpInst = `
    You are a smart travel assistant that creates detailed, well-paced, daily travel itineraries.

${hasProposals ? `
You are given a list of Google Places results and must pick the most relevant ones based on the user's preferences.
` : `
You are NOT given proposed places. You must generate relevant places from scratch based on the user's interest and location of previous activities.
`}

IMPORTANT:
- Include the previous activity in the response, DO NOT REMOVE OR EXCLUDE IT
- You may rearrange events to fit the user's intent
- Ensure the new locations match the same area as the previous activities.
- Format your response as strict JSON like this:
- If there are no location, pleaase exclude 
- Each activity MUST have "from" and "to" time fields in HH:mm format.
- If exact time is unknown, use approximate times (e.g. "09:00", "18:00").
- Do NOT omit or nullify the "from" or "to" fields.
[
  {
    “date”: “01-01-2025”,
    “activities”: [
      {
        "from": "09:00",
        "to": "10:30",
        "title": "Visit Tanah Lot Temple",
        "location": {
          "latitude": -8.6216,
          "longitude": 115.0866
        },
        "details": "Explore a scenic seaside Balinese Hindu temple and learn about local traditions.",
        "locationDetail": "Tanah Lot, Tabanan Regency, Bali"
      },
      {
        "from": "11:00",
        "to": "12:00",
        "title": "Local market tour",
        "details": "Support local artisans by exploring handmade crafts and regional food."
      },
      ...
    ]
  },
    {
    “date”: “01-01-2025”,
    “activities”: [
      {
        "from": "09:00",
        "to": "10:30",
        "title": "Visit Tanah Lot Temple",
        "location": {
          "latitude": -8.6216,
          "longitude": 115.0866
        },
        "details": "Explore a scenic seaside Balinese Hindu temple and learn about local traditions.",
        "locationDetail": "Tanah Lot, Tabanan Regency, Bali"
      },
      {
        "from": "11:00",
        "to": "12:00",
        "title": "Local market tour",
        "details": "Support local artisans by exploring handmade crafts and regional food."
      },
      ...
    ]
  }
]
  `
  const prompt=`
  User intent: ${input}
  Trip's itinerary: ${JSON.stringify(tripItinerary)}
${hasProposals ? `Proposed places: ${JSON.stringify(addActivityRes)}` : ''}
  `;
  console.log(prompt);
  const resultClean = await model.generateContent([cleanUpInst, prompt]);
  const responseClean = await resultClean.response;
  const textClean = await responseClean.text();
  const cleanedItinerary: Itinerary[] = [];

  try {
    parsed = JSON.parse(sanitizeJsonString(textClean));
    console.log();
    console.log(textClean);

    for (const day of parsed) {
      if (!Array.isArray(day.activities) || !day.date) continue;

      const activityList: Activity[] = [];

      for (const activity of day.activities) {
        // Normalize time strings, add seconds if missing
        let fromTime = activity.from;
        if (fromTime && fromTime.length === 5) fromTime += ":00";

        let toTime = activity.to;
        if (toTime && toTime.length === 5) toTime += ":00";

      // Combine day.date with time, add 'Z' for UTC
      const fromDate = fromTime ? new Date(`${day.date}T${fromTime}Z`) : null;
      const toDate = toTime ? new Date(`${day.date}T${toTime}Z`) : null;
        
        const activityDoc: Activity = {
          from: fromDate!,
          to: toDate!,
          title: activity.title,
          details: activity.details,
        };
        if (activity.location) {
          const lat = activity.location.latitude ?? activity.location._latitude;
          const lng = activity.location.longitude ?? activity.location._longitude;

          // Validate that lat and lng are numbers
          if (typeof lat === 'number' && !isNaN(lat) && typeof lng === 'number' && !isNaN(lng)) {
            activityDoc.location = new admin.firestore.GeoPoint(lat, lng);
          }
        }


        if (activity.locationDetail) {
          activityDoc.locationDetail = activity.locationDetail;
        }

        activityList.push(activityDoc);
      }

      cleanedItinerary.push({
        date: new Date(day.date),
        activities: activityList,
      });
    }
  } catch (error) {
    console.log("Error parsing cleaned itinerary:", error);
    throw error;
  }

  return cleanedItinerary;
}

async function cleanJSON(input:string){
  const placeJson: Record<string, any> = {};
  const miscellaneousJson: Record<string, any> = {};
  let parsed:Record<string,any>;
  try{
    parsed = JSON.parse(sanitizeJsonString(input));
  }catch(error){
    console.log(error);
    throw error;
  }
  for (const [day, details] of Object.entries(parsed)) {
    const { miscellaneous, ...rest } = details as any;
    placeJson[day] = rest;
    if (miscellaneous) {
      miscellaneousJson[day] = miscellaneous;
    }
  }

  return [placeJson, miscellaneousJson];
}


type PlaceQuery = {
  query: string;
  type?: string;
  region?: string;
  radius?: number;
  minprice?: number;
  maxprice?: number;
  opennow?: boolean;
  pagetoken?: string;
  location?: {
    latitude: number;
    longitude: number;
  };
};



async function getQuery(destination:string, departureTime:number, returnTime:number,numAdult:number, numChildren:number, preferredTransportation:string[], cleanJSON: string): Promise<string>{
  const systemInst = `
You are an assistant that generates Google Places Text Search API query JSON.

The user provides structured itinerary data for each day of their trip. Each field is an array of the same length. Each index represents one planned activity. For example, the first item in 'location', 'type', 'servesLunch', etc., all describe the same place intent.


Your job is to generate one or more API query objects for each day.

departureTime and returnTime is in unixMs format

IMPORTANT:If the cleanJSON's day length is lesser than the total time(departureTime, and returnTime), give place suggestion within the same destination as if to plan an itenerary in the destination
IMPORTANT: The place suggestion must be in the form of the query, and if you dont know exact location, exclude location and radius.
IMPORTANT: Make sure to prioritize local cultures, but do not search all regarding local culture

Return strict JSON with this structure, where fields with ? are optional:
{
  "day1": [
    {
      location?: {
        longitude: number 
        latitude: number
      };
      maxprice?: number;
      minprice?: number;
      query: string;
      radius?: number;
      region?: string;
      type?: string;
      }
    },
    {
      location?: {
        longitude: number 
        latitude: number
      };
      maxprice?: number;
      minprice?: number;
      query: string;
      radius?: number;
      region?: string;
      type?: string;
      }
    },
    {
      location?: {
        longitude: number 
        latitude: number
      };
      maxprice?: number;
      minprice?: number;
      query: string;
      radius?: number;
      region?: string;
      type?: string;
      }
    },...
  ],
  "day2": [ ... ]
}

Instructions:

1. For each "i" in the tag arrays[servesLunch,hasLiveMusic,...]:
   - Build a "query" string describing the place using:
    - "type[i]" (e.g., "museum", "cafe", "restaurant")
    - Append all true tags as natural keywords. For example:
    - "servesLunch" → "lunch"
    - "hasLiveMusic" → "live music"
    - "isGoodForGroups" → "good for groups"
    - Always append "in ${destination}" at the end of the query string to restrict location
  - If the cleanJSON's day length is lesser than the total time(departureTime, and returnTime), give query suggestion within the same destination as if to plan an itenerary in the destination
    - IMPORTANT: The place suggestion must be in the form of the query, and if you dont know exact location, exclude location and radius.
    - IMPORTANT: Make sure to prioritize local cultures or the points noted below, but do not search all regarding that, IT must be a balance
      - Supporting eco-friendly and sustainable tourism
      - Encouraging meaningful, low-impact travel experiences
2. Set "location's longitude and latitude" using a known coordinate (if unavailable, omit).
3. Set "radius" based on the transport mode, AND only if there is an existing location set:

| Mode      | Radius (meters) |
|-----------|-----------------|
| walking   | 1000-1500       |
| transit   | 2000-3000       |
| driving   | 4000-7000       |
4. Skip any activity (index i) if required fields like "type[i]" or most boolean tags are missing, empty, or too vague.
5. Do not explain anything — only return the structured JSON object.
6. - Use "priceLevel[i]" (from 0 to 4) to set:
  - "minprice": max(0, priceLevel[i] - 1)
  - "maxprice": min(4, priceLevel[i] + 1)

  For example:
    - if priceLevel[i] = 2 → minprice = 1, maxprice = 3
    - if priceLevel[i] = 0 → minprice = 0, maxprice = 1
    - if priceLevel[i] = 4 → minprice = 3, maxprice = 4

- Only include "minprice" and "maxprice" if priceLevel[i] is a number between 0-4.
7. Set the type as the string in type[i]
8. For region, The region code, specified as a ccTLD (country code top-level domain) two-character value. Most ccTLD codes are identical to ISO 3166-1 codes, with some exceptions. This parameter will only influence, not fully restrict, search results. If more relevant results exist outside of the specified region, they may be included. When this parameter is used, the country name is omitted from the resulting formatted_address for results in the specified region.
`;
  const prompt= `
  Destination: ${destination}
  Departure Time: ${departureTime}
  Return Time: ${returnTime}
  Number of Adult: ${numAdult},
  Number of Children: ${numChildren}
  Preferred Transportation: ${preferredTransportation}

  Itinerary Data:
  ${JSON.stringify(cleanJSON, null, 2)}
  `;
  const result = await model.generateContent([systemInst, prompt]);
  const response = await result.response;
  const text = await response.text();
  console.log(`getQeury: ${text}`);
  let parsed: Record<string, PlaceQuery[]>;

  try {
    parsed = JSON.parse(sanitizeJsonString(text));
  } catch (error) {
    console.error("Failed to parse Gemini response:", error);
    console.error("Raw output:", text);
    throw error;
  }
  const dayResults: Record<string, any[]> = {};
  for (const [day, queries] of Object.entries(parsed)) {
    dayResults[day] = [];
    for (const item of queries) {
      // Generate the query for the current item in the current day
      const request = getParams(item);
      if (!request) continue;  // Skip if the request is invalid
    
      try {
        // Send the query for the current day's activity
        const res = await client.textSearch({ params: request });
        dayResults[day].push(res.data);  // Store the result for this day's activity
      } catch (error) {
        console.error(`Failed request for ${day}:`, error);
        throw error;
      }
    }
  }
  console.log(`Day results: ${dayResults}`);
  return JSON.stringify(dayResults);
}


async function processAI(placeJSON: string, miscellaneousJSON: string, numAdult: number, numChildren: number, input: number){ 
  const systemInst=`
  You are a smart travel assistant that creates detailed, well-paced, daily travel itineraries.
  Your job is to organize both user-specified activities (miscellaneous) and places returned from the Google Places API into a structured, optimized itinerary.

  Focus on enhancing the travel experience by:

  Promoting local culture and heritage sites

  Supporting eco-friendly and sustainable tourism

  Encouraging meaningful, low-impact travel experiences

  Your Input:
  You will receive two JSON objects, the number of children and the number of adults:

  places: a list of possible recommended places grouped by day (based on Google Places API results)

  miscellaneous: extra user-described activities not tied to place data (e.g. "rest at hotel", "visit cousin")

  Each place entry includes:

  name, type, location, optional duration, and openTime/closeTime

  Your Task:
  IMPORTANT: Calculate the estimated expenses, depending on the number of children and adult, some tickets may vary on the age, which is why this is necessary
  For the estimated expenses, add each item to the setExpenses, with the item name and the price
  If the user states explicitly their budget, set it to expensesLimit, else set the same value as the estimated expenses
  IF THERE ARE ANY EXPENSES THAT CAN BE IN RANGE, SUCH AS BUYING GROCERIES, EATING AT A RESTAURANT, add the item name to teh variable expenses with teh estimated price,
  IMPORTANT: MAKESURE TO INCLUDE THE USER'S INTENT/INTERESTS
  If there is a location, make sure to inclue the location detail
  MAKE SURE THE CURRENCY IS CONSISTENT IN IDR
  For each day:

  Select the best 2-4 places from the list (prioritize local, cultural, or eco-friendly options)

  Merge in miscellaneous activities

  Assign realistic time slots (e.g., 09:00-10:30)

  Ensure good pacing, breaks, and efficient transport

  Add a short detail or description to each activity
  Return a strict json format like, DO NOT FORGET ABOUT THE ESTIMATED EXPENSES AND SET EXPENSES
  {
    "expensesLimit":100000,
    "estimatedExpenses": 10000,
    "setExpenses":[{
      "item": "Tanah Lot Ticket",
      "price": 10
    },...],
    "variableExpenses":[{
      "item": "Groceries",
      "price": 25
    }, ....]
    "day1": 
        “date”: “01-01-2025”,
        “activities”: [
      {
        "from": "09:00",
        "to": "10:30",
        "title": "Visit Tanah Lot Temple",
        "location": {
          "latitude": -8.6216,
          "longitude": 115.0866
        },
        "details": "Explore a scenic seaside Balinese Hindu temple and learn about local traditions.",
        "locationDetail": "Tanah Lot, Tabanan Regency, Bali"
      },
      {
        "from": "11:00",
        "to": "12:00",
        "title": "Local market tour",
        "details": "Support local artisans by exploring handmade crafts and regional food."
      },
      ...
    ],
    "day2": [...]
  }
  If no duration is given, estimate based on type.

  Use 24-hour time format.

  Avoid overloading the schedule. Include local and low-impact attractions when possible.`

  const prompt=`
  Places:
  ${placeJSON}

  Miscellaneous:
  ${miscellaneousJSON}

  Number of adult:
  ${numAdult}

  Number of children:
  ${numChildren}

  User's intent/interest:
  ${input}
  `;
  console.log(`Prompt: ${prompt}`);

  const result = await model.generateContent([systemInst, prompt]);
  const response = await result.response;
  const text = await response.text();
  
  let planned;
  try{
    planned = JSON.parse(sanitizeJsonString(text));
  } catch(err){
    console.error("Failed to parse itinerary JSON:\n", text);
    throw new Error("Gemini returned invalid JSON");
  }

  return planned;
}

export {itenararyAI,validateInput, extractItienaryFeatures, cleanJSON, getQuery, processAI}