import express from 'express';
import * as userController from '../controllers/userController'; 

const userRouter = express.Router();

userRouter.post('/register', userController.registerUser);   
userRouter.post('/verify-token', userController.verifyidToken); 
userRouter.post('/initialize', userController.initializeUser);  
userRouter.post('/rename', userController.changeUsername);  
export default userRouter;
