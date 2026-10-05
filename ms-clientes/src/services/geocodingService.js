export async function geocodificarDireccion(direccion) {
  const query = [direccion.calle, direccion.numero, direccion.ciudad, direccion.provincia, direccion.pais || "Argentina"]
    .filter(Boolean).join(", ");

  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "json");
  url.searchParams.set("limit", "1");
  url.searchParams.set("countrycodes", "ar");

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(url.toString(), {
      signal: controller.signal,
      headers: {
        "User-Agent": "ecommerce-tp/1.0 (contacto@ejemplo.com)",
        "Accept-Language": "es",
      },
    });
    clearTimeout(timeout);
    if (!resp.ok) throw new Error(`Nominatim ${resp.status}`);
    const data = await resp.json();
    if (data.length === 0) return null;
    return { lat: Number(data[0].lat), lng: Number(data[0].lon) };
  } catch (error) {
    console.warn("Geocodificación falló:", error.message);
    return null;
  }
}
