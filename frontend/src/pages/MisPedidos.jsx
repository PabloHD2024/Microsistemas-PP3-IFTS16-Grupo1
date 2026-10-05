import { useEffect, useState } from "react";
import { pedidosApi } from "../api/pedidos.js";

export default function MisPedidos() {
  const [pedidos, setPedidos] = useState([]);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    pedidosApi.misPedidos().then(setPedidos).finally(() => setCargando(false));
  }, []);

  async function cancelar(id) {
    if (!confirm("¿Cancelar este pedido?")) return;
    try {
      await pedidosApi.cancelar(id);
      setPedidos((prev) => prev.map((p) => (p.id === id ? { ...p, estado: "cancelado" } : p)));
    } catch (err) { alert(err.message); }
  }

  if (cargando) return <p style={{ padding: "2rem" }}>Cargando...</p>;

  return (
    <div style={{ padding: "1rem", maxWidth: "900px", margin: "0 auto" }}>
      <h1>Mis pedidos</h1>
      {pedidos.length === 0 && <p>No tenés pedidos todavía.</p>}
      {pedidos.map((p) => (
        <div key={p.id} style={{ border: "1px solid #ccc", margin: "1rem 0", padding: "1rem", borderRadius: "8px" }}>
          <strong>Pedido #{p.id}</strong> — {new Date(p.created_at).toLocaleDateString("es-AR")}
          <p>Estado: <strong>{p.estado}</strong></p>
          <p>Total: ${Number(p.total).toLocaleString("es-AR")}</p>
          <ul>{p.items?.map((i) => <li key={i.id}>{i.cantidad} × {i.nombre_producto}</li>)}</ul>
          {["pendiente", "confirmado"].includes(p.estado) && (
            <button onClick={() => cancelar(p.id)}>Cancelar</button>
          )}
        </div>
      ))}
    </div>
  );
}
