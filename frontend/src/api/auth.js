import { get, post } from "./client.js";

export const authApi = {
  login: (email, password) => post("/api/usuarios/auth/login", { email, password }),
  register: (data) => post("/api/usuarios/auth/register", data),
  perfil: () => get("/api/usuarios/auth/perfil"),
};
