import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";
import { clientesApi } from "../api/clientes.js";
import { pedidosApi } from "../api/pedidos.js";

export default function Checkout() {
  const { items, total, vaciar } = useCart();
  const navigate = useNavigate();
  const [perfil, setPerfil] = useState(null);
  const [direccionId, setDireccionId] = useState(null);
  const [error, setError] = useState("");
  const [enviando, setEnviando] = useState(false);

  useEffect(() => {
    clientesApi.miPerfil().then(setPerfil).catch(() => setPerfil({ direcciones: [] }));
  }, []);

  async function confirmar() {
    setError("");
    setEnviando(true);
    try {
      const direccion = perfil?.direcciones.find((d) => d._id === direccionId);
      const pedidoItems = items.map((i) => ({ productoId: i.productoId, cantidad: i.cantidad }));
      await pedidosApi.crear(pedidoItems, direccion || null);
      vaciar();
      navigate("/mis-pedidos");
    } catch (err) { setError(err.message); }
    finally { setEnviando(false); }
  }

  if (items.length === 0) return <p style={{ padding: "2rem" }}>Carrito vacío</p>;

  return (
    <div style={{ padding: "1rem", maxWidth: "700px", margin: "0 auto" }}>
      <h1>Confirmar pedido</h1>
      <h3>Resumen</h3>
      <ul>
        {items.map((i) => (
          <li key={i.productoId}>{i.cantidad} × {i.nombre} = ${(i.precio * i.cantidad).toLocaleString("es-AR")}</li>
        ))}
      </ul>
      <p style={{ fontWeight: "bold" }}>Total: ${total.toLocaleString("es-AR")}</p>

      <h3>Dirección</h3>
      {!perfil || perfil.direcciones.length === 0 ? (
        <p>Sin direcciones cargadas. <a href="/direcciones">Agregar</a></p>
      ) : (
        <select value={direccionId || ""} onChange={(e) => setDireccionId(e.target.value)} style={{ width: "100%" }}>
          <option value="">Elegí una dirección</option>
          {perfil.direcciones.map((d) => (
            <option key={d._id} value={d._id}>{d.calle} {d.numero}, {d.ciudad}</option>
          ))}
        </select>
      )}

      {error && <p style={{ color: "red" }}>{error}</p>}
      <button onClick={confirmar} disabled={enviando || !direccionId}
        style={{ marginTop: "1rem", padding: "1rem 2rem" }}>
        {enviando ? "Procesando..." : "Confirmar pedido"}
      </button>
    </div>
  );
}
