import * as geminiService from '../services/geminiServices';
import { Request, Response } from 'express';

const validateInput = async (req: Request, res: Response):Promise<any>=>{
    try {
    const {input} = req.body;
    const validity:boolean = await geminiService.validateInput(input);
    return res.status(201).json({ status: true, valid:validity });
  } catch (error) {
    return res.status(500).json({ status: false, error: error.message || error});
  }
}
 const handleItinerary = async (req: Request, res: Response): Promise<Response> => {
  try {
    const {
      input,
      destination,
      departureTime,
      returnTime,
      numPeople,
      preferredTransportation
    } = req.body;

    if (!input || !destination || !departureTime || !returnTime || !numPeople || !preferredTransportation) {
      return res.status(400).json({ status: false, error: "Missing required fields." });
    }

    // Step 1: Extract features
    const rawJson = await geminiService.extractItienaryFeatures(input);

    // Step 2: Parse & clean JSON
    const parsed = JSON.parse(rawJson);
    const [placeJson, miscellaneousJson] = await geminiService.cleanJSON(parsed);

    // Step 3: Generate query
    const queryJson = await geminiService.getQuery(
      destination,
      departureTime,
      returnTime,
      numPeople,
      preferredTransportation,
      JSON.stringify(placeJson)
    );

    return res.status(200).json({
      status: true,
      placeJson,
      miscellaneousJson,
      queryJson: JSON.parse(queryJson)
    });
  } catch (error: any) {
    console.error("Error in itinerary handler:", error);
    return res.status(500).json({ status: false, error: error.message || error });
  }
};
