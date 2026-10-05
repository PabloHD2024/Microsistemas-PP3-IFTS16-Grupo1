import { createContext, useContext, useEffect, useState } from "react";
import { authApi } from "../api/auth.js";

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [usuario, setUsuario] = useState(() => {
    const raw = localStorage.getItem("usuario");
    return raw ? JSON.parse(raw) : null;
  });
  const [cargando, setCargando] = useState(false);

  useEffect(() => {
    const handler = () => setUsuario(null);
    window.addEventListener("sesion-expirada", handler);
    return () => window.removeEventListener("sesion-expirada", handler);
  }, []);

  async function login(email, password) {
    setCargando(true);
    try {
      const { token, usuario } = await authApi.login(email, password);
      localStorage.setItem("token", token);
      localStorage.setItem("usuario", JSON.stringify(usuario));
      setUsuario(usuario);
      return usuario;
    } finally { setCargando(false); }
  }

  async function register(data) {
    setCargando(true);
    try { return await authApi.register(data); }
    finally { setCargando(false); }
  }

  function logout() {
    localStorage.removeItem("token");
    localStorage.removeItem("usuario");
    setUsuario(null);
  }

  const value = {
    usuario, cargando, autenticado: !!usuario,
    esAdmin: usuario?.rol === "admin",
    login, register, logout,
  };
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth fuera de AuthProvider");
  return ctx;
}
