import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import clientesRoutes from "./routes/clientesRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-clientes", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/clientes", clientesRoutes);

const PORT = process.env.PORT || 3003;
connectDB().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-clientes en puerto ${PORT}`));
});
