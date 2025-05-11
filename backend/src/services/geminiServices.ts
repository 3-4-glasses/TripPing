import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';

dotenv.config();

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

    Return the data in the following in a strict JSON format, no explanations:
    {
      "day1": {
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
async function cleanJSON(parsed: Record<string, any>){
  const placeJson: Record<string, any> = {};
  const miscellaneousJson: Record<string, any> = {};

  for (const [day, details] of Object.entries(parsed)) {
    const { miscellaneous, ...rest } = details as any;
    placeJson[day] = rest;
    if (miscellaneous) {
      miscellaneousJson[day] = miscellaneous;
    }
  }

  return [placeJson, miscellaneousJson];
}
async function getQuery(destination:string, departureTime:string, returnTime:string, numpeople: number, preferredTransportation:string[], cleanJSON: string): Promise<string>{
  const systemInst =
  `
  You are an assistant generating Google Places Text Search API query objects.

Given structured day-by-day data and trip preferences, return JSON with the following format:

{
  "day1": [
    {
      "textQuery": "vegetarian dinner restaurant near Shibuya",
      "locationBias": {
        "circle": {
          "center": {
            "latitude": 35.6595,
            "longitude": 139.7005
          },
          "radius": 1500
        }
      }
    }
  ],
  "day2": [ ... ]
}
Rules:
Use textQuery to describe the intent (e.g., "kid-friendly museum with vegetarian lunch near Kyoto").

Use the last known location or specified location for locationBias.center (lat/lng).

Use radius based on preferredTransportation:

walking → 1000-1500

transit → 2000-3000

driving → 4000-7000

Omit a query if location or intent is unclear
  `
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
  return text.trim();
}
async function processAI(placeJSON: string, miscellaneousJSON: string){ // TODO later
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
  ${JSON.stringify(placeJSON, null, 2)}

  Miscellaneous:
  ${JSON.stringify(miscellaneousJSON, null, 2)}
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

  // await writeToDb(planned); // Store planned itinerary
  //return planned;
}

export {validateInput, extractItienaryFeatures, cleanJSON, getQuery, processAI}