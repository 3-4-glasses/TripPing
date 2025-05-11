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

