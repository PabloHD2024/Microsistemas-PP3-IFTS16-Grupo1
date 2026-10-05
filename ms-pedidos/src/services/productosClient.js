const BASE_URL = process.env.MS_PRODUCTOS_URL;
const SECRET = process.env.GATEWAY_SECRET;

async function fetchConTimeout(url, options = {}, timeoutMs = 5000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

export async function reducirStock(productoId, cantidad) {
  const resp = await fetchConTimeout(`${BASE_URL}/productos/reducir-stock`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-gateway-secret": SECRET },
    body: JSON.stringify({ id: productoId, cantidad }),
  });
  if (!resp.ok) {
    const err = await resp.json().catch(() => ({ error: "Error desconocido" }));
    throw new Error(err.error || `Error con producto ${productoId}`);
  }
  return resp.json();
}

export async function restaurarStock(productoId, cantidad) {
  const resp = await fetchConTimeout(`${BASE_URL}/productos/restaurar-stock`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-gateway-secret": SECRET },
    body: JSON.stringify({ id: productoId, cantidad }),
  });
  return resp.ok;
}
