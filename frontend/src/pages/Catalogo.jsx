import { useEffect, useState } from "react";
import { productosApi } from "../api/productos.js";
import ProductoCard from "../components/ProductoCard.jsx";

export default function Catalogo() {
  const [productos, setProductos] = useState([]);
  const [cotizacion, setCotizacion] = useState(null);
  const [categoria, setCategoria] = useState("");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => { cargar(); }, [categoria]);

  async function cargar() {
    setCargando(true);
    setError("");
    try {
      const params = categoria ? { categoria } : {};
      const data = await productosApi.listar(params);
      setProductos(data.productos || []);
      setCotizacion(data.cotizacion || null);
    } catch (err) { setError(err.message); }
    finally { setCargando(false); }
  }

  return (
    <div style={{ padding: "1rem" }}>
      <h1>Catálogo</h1>
      {cotizacion && (
        <p style={{ background: "#eef", padding: "0.5rem", borderRadius: "4px" }}>
          💵 Dólar oficial: compra ${cotizacion.compra} / venta ${cotizacion.venta}
        </p>
      )}
      <select value={categoria} onChange={(e) => setCategoria(e.target.value)}
        style={{ marginBottom: "1rem" }}>
        <option value="">Todas las categorías</option>
        <option value="electronica">Electrónica</option>
        <option value="muebles">Muebles</option>
      </select>
      {cargando && <p>Cargando...</p>}
      {error && <p style={{ color: "red" }}>{error}</p>}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(250px, 1fr))", gap: "1rem" }}>
        {productos.map((p) => <ProductoCard key={p.id} producto={p} />)}
      </div>
    </div>
  );
}
