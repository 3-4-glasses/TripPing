import express from 'express';
import {
  getItineraryIds,
  getAllItinerary,
  getAllTrip,
  editActivity,
  addItem,
  deleteItem,
  deleteEvent,
  addVariableExpenses,
  setBudget
} from '../controllers/tripController'; 

const tripRouter = express.Router();

tripRouter.get('/itinerary-ids', getItineraryIds);

tripRouter.get('/itineraries', getAllItinerary);

tripRouter.get('/all', getAllTrip);

tripRouter.post('/activity', editActivity);

tripRouter.post('/item', addItem);

tripRouter.delete('/item', deleteItem);

tripRouter.delete('/event', deleteEvent);

tripRouter.post('/variable-expenses', addVariableExpenses);

tripRouter.post('/budget', setBudget);

export default tripRouter;
