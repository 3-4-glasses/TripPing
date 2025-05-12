
import cors from 'cors';
import tripRouter from "./routes/tripRoutes";
import userRouter from "./routes/userRoutes";
import express, { Express } from 'express';
import geminiRouter from './routes/geminiRoutes';
import dotenv from 'dotenv';


dotenv.config();

const app: Express = express(); 
const port = process.env.PORT || 8080;

app.use(cors());
app.use(express.json()); 

app.use('/gemini',geminiRouter)
app.use('/trip',tripRouter);
app.use('/user',userRouter);


app.listen(Number(port),'0.0.0.0', () => {
  console.log("Server running on port 8080");
})


