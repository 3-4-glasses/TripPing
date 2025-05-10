import * as userService from '../services/userServices';
import { Request, Response } from 'express';

const registerUser = async (req: Request, res: Response):Promise<any>=>{
  try {
    const { user_name, email, password } = req.body;
    const userId = await userService.registerUser(user_name, email, password);
    userService.initUser(userId,user_name);
    return res.status(201).json({ status: true, userId:userId });
  } catch (error) {
    return res.status(500).json({ status: false, error: error.message || error});
  }
}

const verifyidToken = async (req: Request, res: Response):Promise<any>=>{
  try{
    const tokenReq = req.body;
    const decodedToken = await userService.verifyToken(tokenReq);
    return res.status(201).json({status: true, decodedToken});
  } catch(error){
    return res.status(500).json({ status:false, error: error.message || error});
  }
}


const initializeUser = async (req: Request, res: Response):Promise<any> => {
  try{
    const {userId, userName} = req.body;
    await userService.initUser(userId,userName);
    return res.status(201).json({status:true, message:"success"})
  }catch(error){
    return res.status(500).json({ status:false, error: error.message || error});
  }
}

export {registerUser,verifyidToken,initializeUser}