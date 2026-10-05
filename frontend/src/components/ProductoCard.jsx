import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";

export default function ProductoCard({ producto }) {
  const { agregar } = useCart();

  return (
    <div style={{ border: "1px solid #ccc", padding: "1rem", borderRadius: "8px" }}>
      <h3>{producto.nombre}</h3>
      <p style={{ fontSize: "1.2rem", fontWeight: "bold" }}>
        ${Number(producto.precio).toLocaleString("es-AR")}
      </p>
      {producto.precioUSD && (
        <p style={{ color: "#666", fontSize: "0.9rem" }}>USD {producto.precioUSD}</p>
      )}
      <p style={{ color: producto.stock > 0 ? "green" : "red" }}>
        {producto.stock > 0 ? `Stock: ${producto.stock}` : "Sin stock"}
      </p>
      <button
        onClick={() => agregar(producto)}
        disabled={producto.stock === 0}
        style={{ width: "100%", padding: "0.5rem" }}
      >
        Agregar al carrito
      </button>
    </div>
  );
}
