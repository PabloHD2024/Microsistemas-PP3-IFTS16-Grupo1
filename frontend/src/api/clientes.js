import { get, post, put, del } from "./client.js";

export const clientesApi = {
  crearPerfil: (data) => post("/api/clientes", data),
  miPerfil: () => get("/api/clientes/perfil"),
  actualizarPerfil: (data) => put("/api/clientes/perfil", data),
  agregarDireccion: (data) => post("/api/clientes/direcciones", data),
  eliminarDireccion: (id) => del(`/api/clientes/direcciones/${id}`),
  marcarPredeterminada: (id) => put(`/api/clientes/direcciones/${id}/predeterminada`),
};
