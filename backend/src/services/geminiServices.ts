import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';
import {Client,TextSearchRequest,PlaceType1,LatLng} from '@googlemaps/google-maps-services-js';


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
  return text.trim().toLowerCase() === 'true';
}

async function extractItienaryFeatures(input: string): Promise<string> {
  const systemInst = `
    You are a helpful itinerary planning assistant. Your task is to extract structured information from a free-text travel description written by a user.
    The user's message may contain destination, travel dates, daily plans, activity preferences, time references, and miscellaneous instructions.
    Make each field an array that is not malformed so that we know what we want to do, and how it correlates to the other fields, and have
    miscellaneous if it doenst fit the other fields, the miscellaneous array shape doesnt have to fit the other field's shape
    Return the data in the following in a strict JSON format, no explanations:
    {
      "day1": {
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
        "miscellaneous": [
          {
            "time": "HH:MM or label like 'morning' or 'afternoon'",
            "activity": "string"
          },{
            "time": "HH:MM or label like 'morning' or 'afternoon'",
            "activity": "string"
          }
        ]
      },
      "day2": { ... }
    }
  `;
  const result = await model.generateContent([systemInst, input]);
  const response = await result.response;
  const text = await response.text();
  return text.trim();
}
async function cleanJSON(input:string){
  const placeJson: Record<string, any> = {};
  const miscellaneousJson: Record<string, any> = {};
  let parsed:Record<string,any>;
  try{
    parsed = JSON.parse(input);
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



async function getQuery(destination:string, departureTime:string, returnTime:string, numpeople: number, preferredTransportation:string[], cleanJSON: string): Promise<string>{
  const systemInst = `
You are an assistant that generates Google Places Text Search API query JSON.

The user provides structured itinerary data for each day of their trip. Each field is an array of the same length. Each index represents one planned activity. For example, the first item in 'location', 'type', 'servesLunch', etc., all describe the same place intent.

Your job is to generate one or more API query objects for each day.

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
  Number of People: ${numpeople}
  Preferred Transportation: ${preferredTransportation}

  Itinerary Data:
  ${JSON.stringify(cleanJSON, null, 2)}
  `;
  const result = await model.generateContent([systemInst, prompt]);
  const response = await result.response;
  const text = await response.text();
  
  let parsed: Record<string, PlaceQuery[]>;

  try {
    parsed = JSON.parse(text);
  } catch (error) {
    console.error("Failed to parse Gemini response:", error);
    console.error("Raw output:", text);
    throw error;
  }
  const dayResults: Record<string, any[]> = {};
  for (const [day, queries] of Object.entries(parsed)) {
    dayResults[day] = [];
    for (const item of queries) {
      // Use optional chaining and nullish coalescing for safe access
      const query = item.query ?? "";
      if (!query) continue; // Skip if required field is missing

      const type = item.type ?? undefined;
      const region = item.region ?? undefined;
      const radius = typeof item.radius === "number" ? item.radius : undefined;
      const minprice = typeof item.minprice === "number" ? item.minprice : undefined;
      const maxprice = typeof item.maxprice === "number" ? item.maxprice : undefined;
      const opennow = typeof item.opennow === "boolean" ? item.opennow : undefined;
      const pagetoken = item.pagetoken ?? undefined;

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
      
    
      try {
        const res = await client.textSearch({ params: request });
        dayResults[day].push(res.data);
      } catch (error) {
        console.error(`Failed request for ${day}:`, error);
        throw error;
      }
    }
  }
  return JSON.stringify(dayResults);
}


async function processAI(placeJSON: string, miscellaneousJSON: string){ 
  const systemInst=`
  You are a smart travel assistant that creates detailed, well-paced, daily travel itineraries.
  Your job is to organize both user-specified activities (miscellaneous) and places returned from the Google Places API into a structured, optimized itinerary.

  Focus on enhancing the travel experience by:

  Promoting local culture and heritage sites

  Supporting eco-friendly and sustainable tourism

  Encouraging meaningful, low-impact travel experiences

  Your Input:
  You will receive two JSON objects:

  places: a list of possible recommended places grouped by day (based on Google Places API results)

  miscellaneous: extra user-described activities not tied to place data (e.g. "rest at hotel", "visit cousin")

  Each place entry includes:

  name, type, location, optional duration, and openTime/closeTime

  Your Task:
  For each day:

  Select the best 2-4 places from the list (prioritize local, cultural, or eco-friendly options)

  Merge in miscellaneous activities

  Assign realistic time slots (e.g., 09:00-10:30)

  Ensure good pacing, breaks, and efficient transport

  Add a short detail or description to each activity
  Return a strict json format like
  {
    "estimatedExpenses": 10000,
    "setExpenses":[{
      "item": "Tanah Lot Ticker",
      "price": 10
    },...]
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
        "details": "Explore a scenic seaside Balinese Hindu temple and learn about local traditions."
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
  `;

  const result = await model.generateContent([systemInst, prompt]);
  const response = await result.response;
  const text = await response.text();
  
  let planned;
  try{
    planned = JSON.parse(text)
  } catch(err){
    console.error("Failed to parse itinerary JSON:\n", text);
    throw new Error("Gemini returned invalid JSON");
  }

  return planned;
}

export {validateInput, extractItienaryFeatures, cleanJSON, getQuery, processAI}