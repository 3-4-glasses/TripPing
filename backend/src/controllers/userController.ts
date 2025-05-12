import * as userService from '../services/userServices';
import { Request, Response } from 'express';

const registerUser = async (req: Request, res: Response):Promise<any>=>{
  try {
    const { user_name, email, password } = req.body;
    if(!user_name || user_name === ''){
      return res.status(400).json({ status: false, error:"username must exist" });
    }
    const userId = await userService.registerUser(user_name, email, password);
    await userService.initUser(userId,user_name);
    return res.status(201).json({ status: true, userId:userId });
  } catch (error: any) {
    return res.status(500).json({ status: false, error: error.message || error});
  }
}

const verifyidToken = async (req: Request, res: Response):Promise<any>=>{
  try{
    const tokenReq = req.body;
    const decodedToken = await userService.verifyToken(tokenReq);
    return res.status(201).json({status: true, decodedToken});
  } catch(error: any){
    return res.status(500).json({ status:false, error: error.message || error});
  }
}


const initializeUser = async (req: Request, res: Response):Promise<any> => {
  try{
    const {userId, userName} = req.body;
    
    await userService.initUser(userId,userName);
    return res.status(201).json({status:true, message:"success"})
  }catch(error: any){
    return res.status(500).json({ status:false, error: error.message || error});
  }
}

export {registerUser,verifyidToken,initializeUser}