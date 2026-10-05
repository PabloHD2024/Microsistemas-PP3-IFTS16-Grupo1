import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import { createProxyMiddleware } from "http-proxy-middleware";
import { SERVICES } from "./config/services.js";
import { authGateway } from "./middlewares/auth.js";

dotenv.config();
const app = express();

app.use(cors({
  origin: process.env.FRONTEND_URL?.split(",") || "*",
  credentials: true,
}));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  message: { error: "Demasiadas solicitudes" },
}));

app.use("/api/usuarios/auth/login", rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
}));

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "api-gateway" })
);

app.use(authGateway);

function proxyTo(target, pathPrefix) {
  return createProxyMiddleware({
    target,
    changeOrigin: true,
    pathRewrite: { [`^${pathPrefix}`]: "" },
    onProxyReq: (proxyReq, req) => {
      if (req.headers["x-user-id"]) {
        proxyReq.setHeader("x-user-id", req.headers["x-user-id"]);
        proxyReq.setHeader("x-user-rol", req.headers["x-user-rol"]);
      }
      proxyReq.setHeader("x-gateway-secret", process.env.GATEWAY_SECRET);
    },
    onError: (err, req, res) => {
      console.error(`[Gateway] ${target}`, err.message);
      res.status(502).json({ error: "Servicio no disponible" });
    },
  });
}

app.use("/api/usuarios",  proxyTo(SERVICES.usuarios,  "/api/usuarios"));
app.use("/api/productos", proxyTo(SERVICES.productos, "/api/productos"));
app.use("/api/clientes",  proxyTo(SERVICES.clientes,  "/api/clientes"));
app.use("/api/pedidos",   proxyTo(SERVICES.pedidos,   "/api/pedidos"));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚪 API Gateway en puerto ${PORT}`));
