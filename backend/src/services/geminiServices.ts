import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from 'dotenv';

dotenv.config();

const gemini = new GoogleGenerativeAI(process.env.GEMINI_API_KEY!);

const model = gemini.getGenerativeModel({ model: "gemini-pro" }); // fuck change this idk what model to use

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
