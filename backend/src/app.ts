import { GoogleGenAI } from "@google/genai";
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


const gemini = new GoogleGenAI({vertexai:false, apiKey: process.env.GEMINI_API_KEY });


