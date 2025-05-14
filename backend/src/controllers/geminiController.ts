import * as geminiService from '../services/geminiServices';
import { Request, Response } from 'express';
import {createTrip, isTripExist, isUserExist, isItineraryExist} from '../services/tripServices'
import { Activity, Itinerary} from '../struct';
import { editActivity } from '../services/tripServices';
import admin from 'firebase-admin';

const validateInput = async (req: Request, res: Response):Promise<any>=>{
  try {
    const {input} = req.body;
    const validity:boolean = await geminiService.validateInput(input);
    return res.status(201).json({ status: true, valid:validity });
  } catch (error: any) {
    return res.status(500).json({ status: false, error: error.message || error});
  } 
}

const addItineraryAI = async(req:Request, res: Response): Promise<any>=>{
  try{
    const {userId, tripId, itineraryId, previousActivty, input} = req.body;
    if(!input || input === ''){
      return res.status(400).json({ status: false, error: "input is empty" });
    }
    if(!userId || userId === ''){
      return res.status(400).json({ status: false, error: "userId is required" });
    }
    
    if(!isUserExist(userId)){
      return res.status(404).json({ status: false, error: "userId does not exist" });
    }
    if(!tripId || tripId === ''){
      return res.status(400).json({ status: false, error: "tripId is required" });
    }
    
    if(!isTripExist(userId,tripId)){
      return res.status(404).json({ status: false, error: "tripId does not exist" });
    }        
    if(!itineraryId || itineraryId === ''){
      return res.status(400).json({ status: false, error: "itineraryId is required" });
    }

    if(!isItineraryExist(userId,tripId,itineraryId)){
      return res.status(404).json({ status: false, error: "itineraryId does not exist" });
    }

    if(!Array.isArray(previousActivty)){
      return res.status(400).json({ status: false, error: "previous activity needs to be an array" });
    }
    for(const activity of previousActivty){
      if (!activity || !activity.from || !activity.to || !activity.title) {
        return res.status(400).json({ status: false, error: "Invalid activity structure" });
      }
    }
    const finalizeActivity: Activity[]= await geminiService.itenararyAI(previousActivty,input);
    const editActivityStatus:boolean = await editActivity(userId,finalizeActivity,tripId,itineraryId);
    if(editActivityStatus){
      return res.status(201).json({ status: true, updatedActivity:finalizeActivity });
    }else{
      return res.status(400).json({ status: true, message:"activity needs to be an array" });
    }

  } catch(error: any){
    console.log(`error on addItineraryAI ${error}`);
    throw error
  }
}

const handleItinerary = async (req: Request, res: Response): Promise<any> => {
  try {
    const {
      title,
      userId,
      input,
      destination,
      departureTime,
      returnTime,
      numChildren,
      numAdult,
      preferredTransportation,
    } = req.body;

    let transport: string[] = [];

    if (Array.isArray(preferredTransportation)) {
      transport = preferredTransportation;
    } else if (typeof preferredTransportation === 'string') {
      transport = [preferredTransportation];
    }

    if (!input || !destination || typeof departureTime !== 'number' || typeof returnTime !== 'number' || typeof numChildren !== 'number' 
      || typeof numAdult !== 'number') {
      return res.status(400).json({ status: false, error: "Missing or invalid required fields." });
    }

    const rawJson = await geminiService.extractItienaryFeatures(input);

    const [placeJson, miscellaneousJson] = await geminiService.cleanJSON(rawJson);

    const queryJson = await geminiService.getQuery(
      destination,
      departureTime,
      returnTime,
      numAdult,
      numChildren,
      transport,
      JSON.stringify(placeJson)
    );
    console.log(queryJson);

    const finalize = await geminiService.processAI(queryJson, JSON.stringify(miscellaneousJson), numAdult, numChildren, input);
    
    let finalizeJSON;
    try {
      finalizeJSON = typeof finalize === "string" ? JSON.parse(finalize) : finalize;
    } catch (err: any) {
      console.error("Parsing finalized result failed:", finalize);
      throw err;
    }

    const tripData = {
      title: title,
      from: new Date(departureTime),
      to: new Date(returnTime),
      expensesUsed: finalizeJSON.estimatedExpenses || 0,
      expensesLimit: finalizeJSON.expensesLimit || 0,
      setExpenses: finalizeJSON.setExpenses || [],
      variableExpenses: finalizeJSON.variableExpenses || []
    };

    const itineraryArray: Itinerary[] = [];
    const baseDate = new Date(departureTime); // Start with the base date (departureTime)
    let dayIndex = 0;

    for (const key in finalizeJSON) {
      if (key.startsWith("day") && finalizeJSON[key]?.activities) {
        const currentDate = new Date(baseDate);
        currentDate.setDate(currentDate.getDate() + dayIndex); // Adjust the current date based on the day index

        const activities = finalizeJSON[key].activities;

        const formattedActivities: Activity[] = activities.map((act: any) => {
          const fromTime = new Date(`${currentDate.toISOString().split("T")[0]}T${act.from}`);
          const toTime = new Date(`${currentDate.toISOString().split("T")[0]}T${act.to}`);

          return {
            from: fromTime,  // Set the activity's from time
            to: toTime,      // Set the activity's to time
            title: act.title,
            details: act.details,
            location: act.location
              ? new admin.firestore.GeoPoint(act.location.latitude, act.location.longitude)
              : undefined
          };
        });

        itineraryArray.push({
          date: currentDate,
          activities: formattedActivities,
        });

        dayIndex++;
      }
    }

    const createdTripId = await createTrip(userId, tripData, itineraryArray);

    return res.status(200).json({
      status: true,
      result: finalize,
      tripId: createdTripId
    });
  } catch (error: any) {
    console.error("Error in itinerary handler:", error);
    return res.status(500).json({ status: false, error: error.message || error });
  }
};


export {validateInput, handleItinerary, addItineraryAI}