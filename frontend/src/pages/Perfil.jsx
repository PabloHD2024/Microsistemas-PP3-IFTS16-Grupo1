import { useEffect, useState } from "react";
import { clientesApi } from "../api/clientes.js";

export default function Perfil() {
  const [perfil, setPerfil] = useState(null);
  const [form, setForm] = useState({ nombre: "", apellido: "", dni: "", telefono: "" });
  const [error, setError] = useState("");

  useEffect(() => {
    clientesApi.miPerfil().then((p) => { setPerfil(p); setForm(p); })
      .catch(() => setPerfil(null));
  }, []);

  async function crear(e) {
    e.preventDefault();
    setError("");
    try {
      const p = await clientesApi.crearPerfil(form);
      setPerfil(p);
    } catch (err) { setError(err.message); }
  }

  async function actualizar(e) {
    e.preventDefault();
    setError("");
    try {
      const p = await clientesApi.actualizarPerfil(form);
      setPerfil(p);
      alert("Actualizado");
    } catch (err) { setError(err.message); }
  }

  if (!perfil) {
    return (
      <div style={{ maxWidth: "500px", margin: "2rem auto", padding: "1rem" }}>
        <h1>Crear perfil</h1>
        <form onSubmit={crear}>
          <input placeholder="Nombre" value={form.nombre} onChange={(e) => setForm({ ...form, nombre: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
          <input placeholder="Apellido" value={form.apellido} onChange={(e) => setForm({ ...form, apellido: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
          <input placeholder="DNI (7-8 dígitos)" value={form.dni} onChange={(e) => setForm({ ...form, dni: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
          <input placeholder="Teléfono" value={form.telefono} onChange={(e) => setForm({ ...form, telefono: e.target.value })} style={{ width: "100%", marginBottom: "0.5rem" }} />
          {error && <p style={{ color: "red" }}>{error}</p>}
          <button type="submit" style={{ width: "100%" }}>Crear perfil</button>
        </form>
      </div>
    );
  }

  return (
    <div style={{ maxWidth: "500px", margin: "2rem auto", padding: "1rem" }}>
      <h1>Mi perfil</h1>
      <form onSubmit={actualizar}>
        <input value={form.nombre || ""} onChange={(e) => setForm({ ...form, nombre: e.target.value })} style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input value={form.apellido || ""} onChange={(e) => setForm({ ...form, apellido: e.target.value })} style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input value={form.telefono || ""} onChange={(e) => setForm({ ...form, telefono: e.target.value })} style={{ width: "100%", marginBottom: "0.5rem" }} />
        <button type="submit" style={{ width: "100%" }}>Guardar</button>
      </form>
      <h3 style={{ marginTop: "2rem" }}>Direcciones</h3>
      {perfil.direcciones?.length === 0 && <p>Sin direcciones.</p>}
      {perfil.direcciones?.map((d) => (
        <div key={d._id} style={{ border: "1px solid #ccc", padding: "0.5rem", marginBottom: "0.5rem", borderRadius: "4px" }}>
          {d.calle} {d.numero}, {d.ciudad}
        </div>
      ))}
      <a href="/direcciones">Gestionar direcciones →</a>
    </div>
  );
}
