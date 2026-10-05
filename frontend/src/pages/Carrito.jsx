import { Link, useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";
import { useAuth } from "../context/AuthContext.jsx";

export default function Carrito() {
  const { items, total, actualizarCantidad, quitar } = useCart();
  const { autenticado } = useAuth();
  const navigate = useNavigate();

  if (items.length === 0) {
    return (
      <div style={{ padding: "2rem", textAlign: "center" }}>
        <h2>Tu carrito está vacío</h2>
        <Link to="/catalogo">Ir al catálogo</Link>
      </div>
    );
  }

  return (
    <div style={{ padding: "1rem", maxWidth: "800px", margin: "0 auto" }}>
      <h1>Carrito</h1>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr><th>Producto</th><th>Precio</th><th>Cantidad</th><th>Subtotal</th><th></th></tr>
        </thead>
        <tbody>
          {items.map((i) => (
            <tr key={i.productoId} style={{ borderTop: "1px solid #ddd" }}>
              <td>{i.nombre}</td>
              <td>${i.precio.toLocaleString("es-AR")}</td>
              <td>
                <button onClick={() => actualizarCantidad(i.productoId, i.cantidad - 1)}>-</button>
                <span style={{ margin: "0 0.5rem" }}>{i.cantidad}</span>
                <button onClick={() => actualizarCantidad(i.productoId, i.cantidad + 1)}>+</button>
              </td>
              <td>${(i.precio * i.cantidad).toLocaleString("es-AR")}</td>
              <td><button onClick={() => quitar(i.productoId)}>🗑️</button></td>
            </tr>
          ))}
        </tbody>
      </table>
      <h2 style={{ textAlign: "right" }}>Total: ${total.toLocaleString("es-AR")}</h2>
      <div style={{ textAlign: "right" }}>
        <button onClick={() => navigate(autenticado ? "/checkout" : "/login")}
          style={{ padding: "1rem 2rem" }}>
          {autenticado ? "Ir a pagar" : "Iniciar sesión para pagar"}
        </button>
      </div>
    </div>
  );
}
