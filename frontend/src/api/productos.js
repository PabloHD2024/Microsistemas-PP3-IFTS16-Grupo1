import { get } from "./client.js";

export const productosApi = {
  listar: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return get(`/api/productos${qs ? `?${qs}` : ""}`);
  },
  obtener: (id) => get(`/api/productos/${id}`),
};
