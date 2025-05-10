import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';

dotenv.config();

interface ItineraryDay {
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
  
interface Itinerary {
    [day: string]: ItineraryDay;
}


const gemini = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const model = gemini.getGenerativeModel({ model: "gemini-pro" }); // fuck change this idk what model to sue

async function validateInput(input: string){
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
