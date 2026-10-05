import { get, post, put } from "./client.js";

export const pedidosApi = {
  crear: (items, direccionEntrega) => post("/api/pedidos", { items, direccionEntrega }),
  misPedidos: () => get("/api/pedidos/mis-pedidos"),
  cancelar: (id) => put(`/api/pedidos/${id}/cancelar`),
};
