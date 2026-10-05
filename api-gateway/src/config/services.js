export const SERVICES = {
  usuarios: process.env.MS_USUARIOS_URL,
  productos: process.env.MS_PRODUCTOS_URL,
  clientes: process.env.MS_CLIENTES_URL,
  pedidos: process.env.MS_PEDIDOS_URL,
};

export const PUBLIC_ROUTES = [
  { method: "POST", path: "/api/usuarios/auth/register" },
  { method: "POST", path: "/api/usuarios/auth/login" },
  { method: "GET",  path: "/api/productos" },
];
