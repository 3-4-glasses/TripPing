import { Request, Response } from 'express';
import * as tripService from '../services/tripServices';

// TODO for some functions see if the userId exists, cuz if not it will make it automatically, bad

const createTrip = async (req: Request, res: Response): Promise<any> => {
    try {
        const { userId, tripData, itineraries } = req.body;
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }

        if (!tripData || Object.keys(tripData).length === 0) {
            return res.status(400).json({ status: false, error: "tripData is required" });
        }
        if (!itineraries || !Array.isArray(itineraries) || itineraries.length === 0) {
            return res.status(400).json({ status: false, error: "itineraries must be a non-empty array" });
        }
        const tripId:string = await tripService.createTrip(userId, tripData, itineraries);
        return res.status(201).json({ status: true, id:tripId });
    } catch (error: any) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const deleteTrip = async(req:Request, res:Response): Promise<any>=>{
    try{
        const { userId, tripId }= req.body;    

        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }
        
        await tripService.deleteTrip(userId,tripId);
        return res.status(204).json({ status: true });
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const getItineraryIds = async(req:Request, res: Response): Promise<any>=>{
    try{
        const userId:string = req.query.userId as string;
        const tripId:string = req.query.tripId as string;
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }
        
        const itineraries =await tripService.getItineraryIds(userId,tripId);
        return res.status(200).json({ status: true, ids: itineraries });
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}
  
const getAllItinerary = async (req:Request, res:Response): Promise<any>=>{
    try{
        const userId:string = req.query.userId as string; 
        const tripId:string = req.query.tripId as string;
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }

        const iteneraries = await tripService.getAllItinerary(userId,tripId);
        return res.status(200).json({status:true, iteneraries:iteneraries})
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const getAllTrip = async (req: Request, res: Response): Promise<any> => {
  try {
    const userId: string = req.query.userId as string;

    if (!userId || userId.trim() === '') {
      return res.status(400).json({ status: false, error: "userId is required" });
    }

    const userExists = await tripService.isUserExist(userId);
    if (!userExists) {
      return res.status(404).json({ status: false, error: "userId does not exist" });
    }

    const trips = await tripService.getAllTrip(userId);

    // Optional: verify response
    // console.log("trips:", JSON.stringify(trips, null, 2));

    return res.status(200).json({ status: true, trips: trips });

  } catch (error: any) {
    console.error("getAllTrip error:", error);
    return res.status(500).json({ status: false, error: error.message || error.toString() });
  }
}


const editActivity = async (req:Request, res:Response): Promise<any>=>{
    
    try{
        const {userId, itinerary, tripId} = req.body;
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }        
        if(!Array.isArray(itinerary)){
            return res.status(400).json({ status: false, error: "Itinerary needs to be an array" });
        }
        itinerary.forEach((day, index) => {
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

        await tripService.editItinerary(userId, itinerary,tripId);
        return res.status(201).json({status:true,message:"success"});
    }catch(error: any){
        console.log(`ERROR: ${error.message}`);
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const addItem = async (req:Request, res:Response): Promise<any> =>{
    try{
        const {userId, tripId, item} = req.body;
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }        
        if(!item || item ===''){
            return res.status(400).json({ status: false, error: "item is required" });
        }
        await tripService.addItems(userId,tripId,item);
        return res.status(200).json({status:true,message:"success"});
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


const deleteItem = async (req:Request, res:Response): Promise<any>=>{
    try{
        const { userId, tripId, item }= req.body;

        if (!userId || !tripId || !item) {
            return res.status(400).json({ status: false, error: 'Missing required fields: userId, tripId, or item' });
        }

        if(!tripService.isUserExist(userId) || !tripService.isTripExist(userId, tripId)){
            return res.status(404).json({ status: false, error: 'TripID or userID doesnt exist' });
        }

        await tripService.deleteItem(userId,tripId,item);
        return res.status(204).json({status:true,message:"success"});
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const deleteEvent = async (req:Request, res:Response): Promise<any>=>{
    try{
        const { userId, tripId, itineraryId, activity} = req.body;
        
        
        if(!userId || userId === ''){
            return res.status(400).json({ status: false, error: "userId is required" });
        }
        
        if(!tripService.isUserExist(userId)){
            return res.status(404).json({ status: false, error: "userId does not exist" });
        }
        if(!tripId || tripId === ''){
            return res.status(400).json({ status: false, error: "tripId is required" });
        }
        
        if(!tripService.isTripExist(userId,tripId)){
            return res.status(404).json({ status: false, error: "tripId does not exist" });
        }        
        if(!itineraryId || itineraryId === ''){
            return res.status(400).json({ status: false, error: "itineraryId is required" });
        }

        if(!tripService.isItineraryExist(userId,tripId,itineraryId)){
            return res.status(404).json({ status: false, error: "itineraryId does not exist" });
        }

        if(!activity || !activity.from || !activity.to || !activity.title || !activity.details){
            return res.status(400).json({ status: false, error: "activity is malformed" });   
        }
        activity.from = new Date(activity.from);
        activity.to = new Date(activity.to);


        await tripService.deleteEvent(userId,tripId,itineraryId,activity);
        return res.status(204).json({status:true,message:"success"});
    }catch(error: any){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const addVariableExpenses = async (req: Request, res: Response): Promise<any> => {
    try {
        const { userId, tripId, item } = req.body;

        if (!item || !item.name || typeof item.name !== 'string' || item.name.trim() === '') {
            return res.status(400).json({ status: false, error: 'Item name is required and must be a non-empty string' });
        }

        if (item.value == null || isNaN(item.value) || item.value <= 0) {
            return res.status(400).json({ status: false, error: 'Item value is required and must be a positive number' });
        }

        await tripService.addVariableExpenses(userId, tripId, item);

        return res.status(200).json({ status: true, message: 'success' });
    } catch (error: any) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


const setBudget = async (req: Request, res: Response): Promise<any> => {
    try {
        const { userId, tripId, amount } = req.body;

        if (!userId || !tripId || amount === undefined) {
            return res.status(400).json({ status: false, error: 'Missing required fields: userId, tripId, or amount' });
        }

        if (isNaN(amount)) {
            return res.status(400).json({ status: false, error: 'Amount must be a valid number' });
        }

        if (amount <= 0) {
            return res.status(400).json({ status: false, error: 'Amount must be a positive number' });
        }

        await tripService.setBudget(userId, tripId, amount);
        
        return res.status(200).json({ status: true, message: 'success' });
    } catch (error: any) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


export {createTrip, getItineraryIds, 
    getAllItinerary, getAllTrip, editActivity, 
    addItem, deleteItem, deleteTrip,
    deleteEvent, addVariableExpenses, setBudget} 