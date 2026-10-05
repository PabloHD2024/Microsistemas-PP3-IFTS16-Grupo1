import { useEffect, useState } from "react";
import { clientesApi } from "../api/clientes.js";

export default function Direcciones() {
  const [perfil, setPerfil] = useState(null);
  const [form, setForm] = useState({ calle: "", numero: "", ciudad: "", provincia: "", codigoPostal: "" });
  const [error, setError] = useState("");

  async function cargar() {
    try { setPerfil(await clientesApi.miPerfil()); }
    catch { setPerfil({ direcciones: [] }); }
  }

  useEffect(() => { cargar(); }, []);

  async function agregar(e) {
    e.preventDefault();
    setError("");
    try {
      await clientesApi.agregarDireccion(form);
      setForm({ calle: "", numero: "", ciudad: "", provincia: "", codigoPostal: "" });
      await cargar();
    } catch (err) { setError(err.message); }
  }

  async function eliminar(id) {
    if (!confirm("¿Eliminar?")) return;
    await clientesApi.eliminarDireccion(id);
    await cargar();
  }

  if (!perfil) return <p style={{ padding: "2rem" }}>Cargando...</p>;

  return (
    <div style={{ padding: "1rem", maxWidth: "700px", margin: "0 auto" }}>
      <h1>Mis direcciones</h1>
      {perfil.direcciones?.map((d) => (
        <div key={d._id} style={{ border: "1px solid #ccc", padding: "1rem", margin: "0.5rem 0", borderRadius: "8px" }}>
          <strong>{d.calle} {d.numero}</strong>
          {d.esPredeterminada && <span style={{ marginLeft: "0.5rem", color: "green" }}>(predeterminada)</span>}
          <p>{d.ciudad}, {d.provincia}</p>
          <button onClick={() => eliminar(d._id)}>Eliminar</button>
        </div>
      ))}
      <h3>Agregar</h3>
      <form onSubmit={agregar}>
        <input placeholder="Calle" value={form.calle} onChange={(e) => setForm({ ...form, calle: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input placeholder="Número" value={form.numero} onChange={(e) => setForm({ ...form, numero: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input placeholder="Ciudad" value={form.ciudad} onChange={(e) => setForm({ ...form, ciudad: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input placeholder="Provincia" value={form.provincia} onChange={(e) => setForm({ ...form, provincia: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
        <input placeholder="Código Postal" value={form.codigoPostal} onChange={(e) => setForm({ ...form, codigoPostal: e.target.value })} required style={{ width: "100%", marginBottom: "0.5rem" }} />
        {error && <p style={{ color: "red" }}>{error}</p>}
        <button type="submit" style={{ width: "100%" }}>Agregar</button>
      </form>
    </div>
  );
}
