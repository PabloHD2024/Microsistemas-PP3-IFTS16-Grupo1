import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { testConnection } from "./config/db.js";
import productosRoutes from "./routes/productosRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-productos", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/productos", productosRoutes);

const PORT = process.env.PORT || 3002;
testConnection().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-productos en puerto ${PORT}`));
});
