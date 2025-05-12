
import cors from 'cors';
import tripRouter from "./routes/tripRoutes";
import userRouter from "./routes/userRoutes";
import express, { Express } from 'express';
import geminiRouter from './routes/geminiRoutes';

const app: Express = express(); 
const port:number = 3000;

app.use(cors());
app.use(express.json()); 

app.listen(port, () => {
  console.log("Server running on port 3000");
})

app.use('/gemini',geminiRouter)
app.use('/trip',tripRouter);
app.use('/user',userRouter);

