export function gatewayOnly(req, res, next) {
  const secret = req.headers["x-gateway-secret"];
  if (!secret || secret !== process.env.GATEWAY_SECRET) {
    return res.status(403).json({ error: "Acceso solo vía API Gateway" });
  }
  next();
}
