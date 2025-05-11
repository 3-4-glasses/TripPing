import express from 'express';
import * as geminiController from "../controllers/geminiController";

const geminirouter = express.Router();

geminirouter.post("/validate", geminiController.validateInput)
geminirouter.post("/itinerary", geminiController.handleItinerary);

export default geminirouter;