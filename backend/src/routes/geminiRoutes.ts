import express from 'express';
import * as geminiController from "../controllers/geminiController";

const geminiRouter = express.Router();

geminiRouter.post("/editItenerary",geminiController.addItineraryAI); // TODO  implement later 
geminiRouter.post("/validate", geminiController.validateInput);
geminiRouter.post("/itinerary", geminiController.handleItinerary);

export default geminiRouter;