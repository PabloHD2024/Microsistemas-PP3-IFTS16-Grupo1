import { useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";

export default function Register() {
  const [form, setForm] = useState({ nombre: "", email: "", password: "" });
  const [error, setError] = useState("");
  const { register, cargando } = useAuth();
  const navigate = useNavigate();

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    try {
      await register(form);
      navigate("/login");
    } catch (err) { setError(err.message); }
  }

  return (
    <div style={{ maxWidth: "400px", margin: "2rem auto" }}>
      <h1>Crear cuenta</h1>
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "1rem" }}>
          <label>Nombre</label>
          <input value={form.nombre} onChange={(e) => setForm({ ...form, nombre: e.target.value })}
            required style={{ width: "100%" }} />
        </div>
        <div style={{ marginBottom: "1rem" }}>
          <label>Email</label>
          <input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })}
            required style={{ width: "100%" }} />
        </div>
        <div style={{ marginBottom: "1rem" }}>
          <label>Contraseña (mín. 6)</label>
          <input type="password" value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })}
            required minLength={6} style={{ width: "100%" }} />
        </div>
        {error && <p style={{ color: "red" }}>{error}</p>}
        <button type="submit" disabled={cargando} style={{ width: "100%", padding: "0.75rem" }}>
          {cargando ? "Creando..." : "Registrarse"}
        </button>
      </form>
      <p style={{ marginTop: "1rem" }}>
        ¿Ya tenés cuenta? <Link to="/login">Iniciar sesión</Link>
      </p>
    </div>
  );
}
