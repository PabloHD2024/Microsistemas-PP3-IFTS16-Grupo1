import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { testConnection } from "./config/db.js";
import pedidosRoutes from "./routes/pedidosRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";
import { errorHandler, notFound } from "./middlewares/errorHandler.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-pedidos", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/pedidos", pedidosRoutes);

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3004;
testConnection().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-pedidos en puerto ${PORT}`));
});
