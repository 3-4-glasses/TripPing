import { GoogleGenAI } from "@google/genai";
import dotenv from 'dotenv';

dotenv.config();

const gemini = new GoogleGenAI({vertexai:false, apiKey: process.env.GEMINI_API_KEY });


