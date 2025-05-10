import { Request, Response } from 'express';
import * as tripService from '../services/tripServices';

const createTrip = async (req: Request, res: Response): Promise<any> => {
    try {
        const { userId, tripData, itineraries } = req.body;
        const tripId = await tripService.createTrip(userId, tripData, itineraries);
        return res.status(201).json({ status: true, tripId });
    } catch (error) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const getItineraryIds = async(req:Request, res: Response): Promise<any>=>{
    try{
        const {userId,tripId} = req.body;
        const itineraries =await tripService.getItineraryIds(userId,tripId);
        return res.status(200).json({ status: true, ids: itineraries });
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}
  
const getAllItinerary = async (req:Request, res:Response): Promise<any>=>{
    try{
        const {userId, tripId} = req.body;
        const iteneraries = await tripService.getAllItinerary(userId,tripId);
        return res.status(200).json({status:true, iteneraries:iteneraries})
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const getAllTrip = async (req:Request, res:Response): Promise<any>=>{
    try{
        const {userId} = req.body;
        const trips = await tripService.getAllTrip(userId);
        return res.status(200).json({status:true,trips:trips});
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const addActivity = async (req:Request, res:Response): Promise<any>=>{
    try{
        const {userId, activityAddition, tripId, itineraryId} = req.body;
        await tripService.addActivity(userId,activityAddition,tripId,itineraryId);
        return res.status(201).json({status:true,message:"success"});
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


const addItem = async (req:Request, res:Response): Promise<any> =>{
    try{
        const {userId, tripId, item} = req.body;
        await tripService.addItems(userId,tripId,item);
        return res.status(200).json({status:true,message:"success"});
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


const deleteItem = async (req:Request, res:Response): Promise<any>=>{
    try{
        const {userId, tripId, item} = req.body;
        await tripService.deleteItem(userId,tripId,item);
        return res.status(204).json({status:true,message:"success"});
    }catch(error){
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const incrementExpenses = async (req: Request, res: Response): Promise<any> => {
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

        await tripService.incrementExpenses(userId, tripId, amount);
        
        return res.status(200).json({ status: true, message: 'success' });
    } catch (error) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}

const deleteEvent = async (req:Request, res:Response): Promise<any>=>{
    try{
        const { userId, tripId, itineraryId, activity} = req.body;
        await tripService.deleteEvent(userId,tripId,itineraryId,activity);
        return res.status(204).json({status:true,message:"success"});
    }catch(error){
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
    } catch (error) {
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
    } catch (error) {
        return res.status(500).json({ status: false, error: error.message || error });
    }
}


export {createTrip, getItineraryIds, 
    getAllItinerary, getAllTrip, addActivity, 
    addItem, deleteItem, incrementExpenses, 
    deleteEvent, addVariableExpenses, setBudget} 