let cacheDolar = null;
const CACHE_TTL_MS = 10 * 60 * 1000;

export async function obtenerCotizacionDolar() {
  const ahora = Date.now();
  if (cacheDolar && ahora - cacheDolar.timestamp < CACHE_TTL_MS) {
    return { ...cacheDolar.valor, fromCache: true };
  }
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch("https://dolarapi.com/v1/dolares/oficial", {
      signal: controller.signal,
      headers: { "User-Agent": "ecommerce-tp/1.0" },
    });
    clearTimeout(timeout);
    if (!resp.ok) throw new Error(`API ${resp.status}`);
    const data = await resp.json();
    const valor = { compra: data.compra, venta: data.venta, fecha: data.fechaActualizacion };
    cacheDolar = { valor, timestamp: ahora };
    return { ...valor, fromCache: false };
  } catch (error) {
    if (cacheDolar) return { ...cacheDolar.valor, fromCache: true, stale: true };
    throw new Error("No se pudo obtener cotización");
  }
}
