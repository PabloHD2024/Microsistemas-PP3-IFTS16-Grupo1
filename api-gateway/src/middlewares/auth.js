import jwt from "jsonwebtoken";
import { PUBLIC_ROUTES } from "../config/services.js";

function esRutaPublica(req) {
  return PUBLIC_ROUTES.some(
    (r) =>
      r.method === req.method &&
      (req.originalUrl === r.path || req.originalUrl.startsWith(r.path))
  );
}

export function authGateway(req, res, next) {
  if (esRutaPublica(req)) return next();

  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ error: "Token requerido" });

  const token = header.split(" ")[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.headers["x-user-id"] = payload.id;
    req.headers["x-user-rol"] = payload.rol;
    next();
  } catch {
    res.status(403).json({ error: "Token inválido o expirado" });
  }
}
