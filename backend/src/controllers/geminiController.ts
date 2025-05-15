import * as geminiService from '../services/geminiServices';
import { Request, Response } from 'express';
import {createTrip, isTripExist, isUserExist, isItineraryExist} from '../services/tripServices'
import { Activity, Itinerary} from '../struct';
import { editItinerary } from '../services/tripServices';
import admin from 'firebase-admin';

const validateInput = async (req: Request, res: Response):Promise<any>=>{
  try {
    const {input} = req.body;
    console.log(`Validate INput: ${input}`);
    const validity:boolean = await geminiService.validateInput(input);
    console.log(validity);
    return res.status(201).json({ status: true, valid:validity });
  } catch (error: any) {
    console.log(`Error on validateInput: ${error.message || error}`);
    return res.status(500).json({ status: false, error: error.message || error});
  } 
}

const addItineraryAI = async(req:Request, res: Response): Promise<any>=>{
  try{
    const {userId, tripId, itineraries, input} = req.body;
    console.log(JSON.stringify(itineraries));
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
    if(!Array.isArray(itineraries)){
            return res.status(400).json({ status: false, error: "Itinerary needs to be an array" });
        }
        itineraries.forEach((day, index) => {
            if (!day.date || !day.activities || !Array.isArray(day.activities)) {
                return res.status(400).json({
                status: false,
                error: `Itinerary item at index ${index} is missing required fields or activities is not an array`,
                });
            }

            const date = new Date(day.date);
            if (isNaN(date.getTime())) {
                return res.status(400).json({
                status: false,
                error: `Invalid date format in itinerary at index ${index}`,
                });
            }

            for (let i = 0; i < day.activities.length; i++) {
                const activity = day.activities[i];
                if (!activity.from || !activity.to || !activity.title || !activity.details) {
                return res.status(400).json({
                    status: false,
                    error: `Missing required activity fields at itinerary[${index}].activities[${i}]`,
                });
                }

                const from = new Date(activity.from);
                const to = new Date(activity.to);
                if (isNaN(from.getTime()) || isNaN(to.getTime())) {
                return res.status(400).json({
                    status: false,
                    error: `Invalid date in activity at itinerary[${index}].activities[${i}]`,
                });
                }

                if (
                activity.location &&
                (typeof activity.location.latitude !== "number" ||
                    typeof activity.location.longitude !== "number")
                ) {
                return res.status(400).json({
                    status: false,
                    error: `Invalid location in activity at itinerary[${index}].activities[${i}]`,
                });
                }
            }
        });

    const finalizeItinerary: Itinerary[]= await geminiService.itenararyAI(itineraries,input);

    console.log(JSON.stringify(finalizeItinerary));

    return res.status(201).json({ status: true, itinerary:finalizeItinerary });
    

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
      variableExpenses: finalizeJSON.variableExpenses || [],
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
              : undefined,
            locationDetail: act.locationDetail ? act.locationDetail : ""
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