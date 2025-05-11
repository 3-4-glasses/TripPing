import express from 'express';
import * as geminiController from "../controllers/geminiController";

const geminirouter = express.Router();

geminirouter.post("/itinerary", geminiController.handleItinerary);

export default geminirouter;