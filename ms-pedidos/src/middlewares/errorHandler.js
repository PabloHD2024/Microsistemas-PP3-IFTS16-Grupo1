export function errorHandler(err, req, res, _next) {
  console.error("[ms-pedidos]", err);
  res.status(err.status || 500).json({ error: err.message || "Error interno" });
}

export function notFound(req, res) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}
