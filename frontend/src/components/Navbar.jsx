import { Link, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";
import { useCart } from "../context/CartContext.jsx";

export default function Navbar() {
  const { usuario, autenticado, logout } = useAuth();
  const { cantidadTotal } = useCart();
  const navigate = useNavigate();

  function handleLogout() { logout(); navigate("/"); }

  return (
    <nav style={{ display: "flex", gap: "1rem", padding: "1rem", background: "#222", color: "#fff", alignItems: "center" }}>
      <Link to="/" style={{ color: "#fff", fontWeight: "bold" }}>🛒 E-commerce</Link>
      <Link to="/catalogo" style={{ color: "#fff" }}>Catálogo</Link>
      {autenticado && (
        <>
          <Link to="/mis-pedidos" style={{ color: "#fff" }}>Mis pedidos</Link>
          <Link to="/perfil" style={{ color: "#fff" }}>Perfil</Link>
        </>
      )}
      <Link to="/carrito" style={{ color: "#fff", marginLeft: "auto" }}>
        🛒 Carrito ({cantidadTotal})
      </Link>
      {autenticado ? (
        <div style={{ display: "flex", gap: "0.5rem", alignItems: "center" }}>
          <span>👤 {usuario.nombre}</span>
          <button onClick={handleLogout}>Salir</button>
        </div>
      ) : (
        <>
          <Link to="/login" style={{ color: "#fff" }}>Login</Link>
          <Link to="/register" style={{ color: "#fff" }}>Registrarse</Link>
        </>
      )}
    </nav>
  );
}
