
import cors from 'cors';
import tripRouter from "./routes/tripRoutes";
import userRouter from "./routes/userRoutes";
import express, { Express } from 'express';

const app: Express = express(); 
const port:number = 3000;

app.use(cors());

app.listen(port, () => {
  console.log("Server running on port 3000");
})


app.use('/trip',tripRouter);
app.use('/user',userRouter);

