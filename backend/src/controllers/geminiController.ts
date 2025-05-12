import * as geminiService from '../services/geminiServices';
import { Request, Response } from 'express';
import {createTrip} from '../services/tripServices'
import { Activity, Itinerary} from '../struct';
import admin from 'firebase-admin';

const validateInput = async (req: Request, res: Response):Promise<any>=>{
  try {
    const {input} = req.body;
    const validity:boolean = await geminiService.validateInput(input);
    return res.status(201).json({ status: true, valid:validity });
  } catch (error) {
    return res.status(500).json({ status: false, error: error.message || error});
  }
}
 const handleItinerary = async (req: Request, res: Response): Promise<any> => {
  try {
    const {
      userId,
      input,
      destination,
      departureTime,
      returnTime,
      numPeople,
      preferredTransportation,
    } = req.body;

    if (!input || !destination || !departureTime || !returnTime || !numPeople || !preferredTransportation) {
      return res.status(400).json({ status: false, error: "Missing required fields." });
    }

    const rawJson = await geminiService.extractItienaryFeatures(input);

    const [placeJson, miscellaneousJson] = await geminiService.cleanJSON(rawJson);

    const queryJson = await geminiService.getQuery(
      destination,
      departureTime,
      returnTime,
      numPeople,
      preferredTransportation,
      JSON.stringify(placeJson)
    );
    
    
    const finalize = await geminiService.processAI(queryJson, JSON.stringify(miscellaneousJson));

    let finalizeJSON;
    try {
      finalizeJSON = typeof finalize === "string" ? JSON.parse(finalize) : finalize;
    } catch (err) {
      console.error("Parsing finalized result failed:", finalize);
      throw new err;
    }

    const tripData = {
      from: new Date(departureTime),
      to: new Date(returnTime),
      expensesUsed: finalizeJSON.estimatedExpenses || 0,
      expensesLimit: finalizeJSON.estimatedExpenses || 0,
      setExpenses: finalizeJSON.setExpenses || [],
    };

    const itineraryArray: Itinerary[] = [];

    const baseDate = new Date(departureTime);
    let dayIndex = 0;

    for (const key in finalizeJSON) {
      if (key.startsWith("day") && finalizeJSON[key]?.activities) {
        const currentDate = new Date(baseDate);
        currentDate.setDate(currentDate.getDate() + dayIndex);

        const activities = finalizeJSON[key].activities;

        const formattedActivities: Activity[] = activities.map((act: any) => ({
          from: new Date(`${currentDate.toISOString().split("T")[0]}T${act.from}`),
          to: new Date(`${currentDate.toISOString().split("T")[0]}T${act.to}`),
          title: act.title,
          details: act.details,
          location: act.location
            ? new admin.firestore.GeoPoint(act.location.latitude, act.location.longitude)
            : undefined
        }));

        itineraryArray.push({
          date: currentDate,
          activities: formattedActivities,
        });

        dayIndex++;
      }
    }

    const createdTripId = createTrip(userId,tripData,itineraryArray);

    return res.status(200).json({
      status: true,
      result:finalize,
      tripId: createdTripId
    });
  } catch (error: any) {
    console.error("Error in itinerary handler:", error);
    return res.status(500).json({ status: false, error: error.message || error });
  }
};

export {validateInput, handleItinerary}