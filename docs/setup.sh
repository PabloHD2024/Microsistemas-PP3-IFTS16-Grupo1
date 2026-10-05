#!/usr/bin/env bash
set -e

# ============================================================
# E-commerce Microservicios — Generador de estructura completa
# ============================================================

ROOT="ecommerce-microservices"
mkdir -p "$ROOT"
cd "$ROOT"

echo "📁 Creando estructura de carpetas..."

# --- api-gateway ---
mkdir -p api-gateway/src/config api-gateway/src/middlewares

# --- ms-usuarios ---
mkdir -p ms-usuarios/src/config ms-usuarios/src/models ms-usuarios/src/controllers ms-usuarios/src/middlewares ms-usuarios/src/routes ms-usuarios/tests

# --- ms-productos ---
mkdir -p ms-productos/src/config ms-productos/src/controllers ms-productos/src/middlewares ms-productos/src/routes ms-productos/src/services ms-productos/tests ms-productos/sql

# --- ms-clientes ---
mkdir -p ms-clientes/src/config ms-clientes/src/models ms-clientes/src/controllers ms-clientes/src/middlewares ms-clientes/src/routes ms-clientes/src/services ms-clientes/tests

# --- ms-pedidos ---
mkdir -p ms-pedidos/src/config ms-pedidos/src/controllers ms-pedidos/src/middlewares ms-pedidos/src/routes ms-pedidos/src/services ms-pedidos/tests ms-pedidos/sql

# --- frontend ---
mkdir -p frontend/src/api frontend/src/context frontend/src/components frontend/src/pages

# --- docs ---
mkdir -p docs/uml docs/postman docs/sql

echo "✅ Carpetas creadas"
echo "📝 Escribiendo archivos..."

# ============================================================
# API GATEWAY
# ============================================================

cat > api-gateway/package.json << 'EOF'
{
  "name": "api-gateway",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "express-rate-limit": "^7.4.0",
    "http-proxy-middleware": "^3.0.0",
    "jsonwebtoken": "^9.0.2"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

cat > api-gateway/.env.example << 'EOF'
PORT=3000
JWT_SECRET=dev_secret_largo_y_unico
GATEWAY_SECRET=dev_gateway_secret_compartido
FRONTEND_URL=http://localhost:5173
MS_USUARIOS_URL=http://localhost:3001
MS_PRODUCTOS_URL=http://localhost:3002
MS_CLIENTES_URL=http://localhost:3003
MS_PEDIDOS_URL=http://localhost:3004
NODE_ENV=development
EOF

cat > api-gateway/.gitignore << 'EOF'
node_modules/
.env
*.log
coverage/
.DS_Store
EOF

cat > api-gateway/src/config/services.js << 'EOF'
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
EOF

cat > api-gateway/src/middlewares/auth.js << 'EOF'
import jwt from "jsonwebtoken";
import { PUBLIC_ROUTES } from "../config/services.js";

function esRutaPublica(req) {
  return PUBLIC_ROUTES.some(
    (r) =>
      r.method === req.method &&
      (req.originalUrl === r.path || req.originalUrl.startsWith(r.path))
  );
}

export function authGateway(req, res, next) {
  if (esRutaPublica(req)) return next();

  const header = req.headers.authorization;
  if (!header) return res.status(401).json({ error: "Token requerido" });

  const token = header.split(" ")[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    req.headers["x-user-id"] = payload.id;
    req.headers["x-user-rol"] = payload.rol;
    next();
  } catch {
    res.status(403).json({ error: "Token inválido o expirado" });
  }
}
EOF

cat > api-gateway/src/index.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import { createProxyMiddleware } from "http-proxy-middleware";
import { SERVICES } from "./config/services.js";
import { authGateway } from "./middlewares/auth.js";

dotenv.config();
const app = express();

app.use(cors({
  origin: process.env.FRONTEND_URL?.split(",") || "*",
  credentials: true,
}));

app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 300,
  message: { error: "Demasiadas solicitudes" },
}));

app.use("/api/usuarios/auth/login", rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
}));

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "api-gateway" })
);

app.use(authGateway);

function proxyTo(target, pathPrefix) {
  return createProxyMiddleware({
    target,
    changeOrigin: true,
    pathRewrite: { [`^${pathPrefix}`]: "" },
    onProxyReq: (proxyReq, req) => {
      if (req.headers["x-user-id"]) {
        proxyReq.setHeader("x-user-id", req.headers["x-user-id"]);
        proxyReq.setHeader("x-user-rol", req.headers["x-user-rol"]);
      }
      proxyReq.setHeader("x-gateway-secret", process.env.GATEWAY_SECRET);
    },
    onError: (err, req, res) => {
      console.error(`[Gateway] ${target}`, err.message);
      res.status(502).json({ error: "Servicio no disponible" });
    },
  });
}

app.use("/api/usuarios",  proxyTo(SERVICES.usuarios,  "/api/usuarios"));
app.use("/api/productos", proxyTo(SERVICES.productos, "/api/productos"));
app.use("/api/clientes",  proxyTo(SERVICES.clientes,  "/api/clientes"));
app.use("/api/pedidos",   proxyTo(SERVICES.pedidos,   "/api/pedidos"));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`🚪 API Gateway en puerto ${PORT}`));
EOF

# ============================================================
# MS-USUARIOS
# ============================================================

cat > ms-usuarios/package.json << 'EOF'
{
  "name": "ms-usuarios",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "node --experimental-vm-modules node_modules/jest/bin/jest.js"
  },
  "dependencies": {
    "bcryptjs": "^2.4.3",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "jsonwebtoken": "^9.0.2",
    "mongoose": "^8.5.1"
  },
  "devDependencies": {
    "jest": "^29.7.0",
    "mongodb-memory-server": "^10.0.0",
    "nodemon": "^3.1.4",
    "supertest": "^7.0.0"
  }
}
EOF

cat > ms-usuarios/.env.example << 'EOF'
PORT=3001
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/ms-usuarios
JWT_SECRET=dev_secret_largo_y_unico
JWT_EXPIRES=2h
GATEWAY_SECRET=dev_gateway_secret_compartido
NODE_ENV=development
EOF

cat > ms-usuarios/.gitignore << 'EOF'
node_modules/
.env
*.log
coverage/
.DS_Store
EOF

cat > ms-usuarios/src/config/db.js << 'EOF'
import mongoose from "mongoose";

export async function connectDB(uri = process.env.MONGO_URI) {
  try {
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
    console.log(`✅ MongoDB conectado (${mongoose.connection.name})`);
  } catch (error) {
    console.error("❌ Error MongoDB:", error.message);
    if (process.env.NODE_ENV !== "test") process.exit(1);
    throw error;
  }
}

export async function disconnectDB() {
  await mongoose.disconnect();
}
EOF

cat > ms-usuarios/src/models/Usuario.js << 'EOF'
import mongoose from "mongoose";
import bcrypt from "bcryptjs";

const usuarioSchema = new mongoose.Schema(
  {
    nombre: { type: String, required: true, trim: true, minlength: 2, maxlength: 80 },
    email: {
      type: String, required: true, unique: true, lowercase: true, trim: true,
      match: /^[^\s@]+@[^\s@]+\.[^\s@]+$/,
    },
    password: { type: String, required: true, minlength: 6, select: false },
    rol: { type: String, enum: ["cliente", "admin"], default: "cliente" },
    activo: { type: Boolean, default: true },
    ultimoLogin: { type: Date, default: null },
  },
  { timestamps: true }
);

usuarioSchema.pre("save", async function (next) {
  if (!this.isModified("password")) return next();
  this.password = await bcrypt.hash(this.password, 10);
  next();
});

usuarioSchema.methods.compararPassword = function (plain) {
  return bcrypt.compare(plain, this.password);
};

usuarioSchema.statics.buscarPorEmail = function (email) {
  return this.findOne({ email: email.toLowerCase(), activo: true });
};

usuarioSchema.set("toJSON", {
  transform: (_, ret) => {
    delete ret.password;
    delete ret.__v;
    return ret;
  },
});

export default mongoose.model("Usuario", usuarioSchema);
EOF

cat > ms-usuarios/src/controllers/authController.js << 'EOF'
import jwt from "jsonwebtoken";
import Usuario from "../models/Usuario.js";

function firmarToken(usuario) {
  return jwt.sign(
    { id: usuario._id.toString(), rol: usuario.rol, email: usuario.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES || "2h" }
  );
}

export async function register(req, res, next) {
  try {
    const { nombre, email, password, rol } = req.body;
    if (!nombre || !email || !password)
      return res.status(400).json({ error: "Faltan campos obligatorios" });
    if (password.length < 6)
      return res.status(400).json({ error: "Contraseña mínimo 6 caracteres" });

    const existe = await Usuario.findOne({ email: email.toLowerCase() });
    if (existe) return res.status(409).json({ error: "Email ya registrado" });

    const rolFinal = rol === "admin" ? "cliente" : (rol || "cliente");
    const usuario = await Usuario.create({ nombre, email, password, rol: rolFinal });

    res.status(201).json({
      id: usuario._id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol,
    });
  } catch (e) { next(e); }
}

export async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ error: "Faltan credenciales" });

    const usuario = await Usuario.buscarPorEmail(email).select("+password");
    if (!usuario) return res.status(401).json({ error: "Credenciales inválidas" });

    const ok = await usuario.compararPassword(password);
    if (!ok) return res.status(401).json({ error: "Credenciales inválidas" });

    usuario.ultimoLogin = new Date();
    await usuario.save({ validateBeforeSave: false });

    res.json({
      token: firmarToken(usuario),
      usuario: { id: usuario._id, nombre: usuario.nombre, email: usuario.email, rol: usuario.rol },
    });
  } catch (e) { next(e); }
}

export async function perfil(req, res) {
  const usuario = await Usuario.findById(req.headers["x-user-id"]);
  if (!usuario) return res.status(404).json({ error: "Usuario no encontrado" });
  res.json(usuario);
}

export async function listarUsuarios(req, res) {
  if (req.headers["x-user-rol"] !== "admin")
    return res.status(403).json({ error: "Solo administradores" });

  const { page = 1, limit = 20 } = req.query;
  const [total, data] = await Promise.all([
    Usuario.countDocuments({ activo: true }),
    Usuario.find({ activo: true })
      .skip((page - 1) * limit).limit(Number(limit)).sort({ createdAt: -1 }),
  ]);
  res.json({ total, page: Number(page), data });
}

export async function desactivarUsuario(req, res) {
  if (req.headers["x-user-rol"] !== "admin")
    return res.status(403).json({ error: "Solo administradores" });

  const usuario = await Usuario.findByIdAndUpdate(
    req.params.id, { activo: false }, { new: true }
  );
  if (!usuario) return res.status(404).json({ error: "Usuario no encontrado" });
  res.json({ mensaje: "Usuario desactivado", usuario });
}
EOF

cat > ms-usuarios/src/middlewares/gatewayOnly.js << 'EOF'
export function gatewayOnly(req, res, next) {
  const secret = req.headers["x-gateway-secret"];
  if (!secret || secret !== process.env.GATEWAY_SECRET) {
    return res.status(403).json({ error: "Acceso solo vía API Gateway" });
  }
  next();
}
EOF

cat > ms-usuarios/src/middlewares/errorHandler.js << 'EOF'
export function errorHandler(err, req, res, _next) {
  console.error("[ms-usuarios]", err);
  if (err.name === "ValidationError") {
    return res.status(400).json({
      error: "Error de validación",
      detalles: Object.values(err.errors).map((e) => e.message),
    });
  }
  if (err.code === 11000) {
    return res.status(409).json({
      error: "Recurso duplicado",
      campo: Object.keys(err.keyValue)[0],
    });
  }
  if (err.name === "CastError") {
    return res.status(400).json({ error: "ID inválido" });
  }
  res.status(500).json({ error: "Error interno del servidor" });
}

export function notFound(req, res) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}
EOF

cat > ms-usuarios/src/routes/authRoutes.js << 'EOF'
import { Router } from "express";
import {
  register, login, perfil, listarUsuarios, desactivarUsuario,
} from "../controllers/authController.js";

const router = Router();
router.post("/auth/register", register);
router.post("/auth/login", login);
router.get("/auth/perfil", perfil);
router.get("/usuarios", listarUsuarios);
router.delete("/usuarios/:id", desactivarUsuario);

export default router;
EOF

cat > ms-usuarios/src/index.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import authRoutes from "./routes/authRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";
import { errorHandler, notFound } from "./middlewares/errorHandler.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json({ limit: "1mb" }));

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-usuarios", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/", authRoutes);

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3001;
connectDB().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-usuarios en puerto ${PORT}`));
});
EOF

# ============================================================
# MS-PRODUCTOS
# ============================================================

cat > ms-productos/package.json << 'EOF'
{
  "name": "ms-productos",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "pg": "^8.12.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

cat > ms-productos/.env.example << 'EOF'
PORT=3002
DATABASE_URL=postgresql://user:pass@host/db
GATEWAY_SECRET=dev_gateway_secret_compartido
NODE_ENV=development
EOF

cat > ms-productos/.gitignore << 'EOF'
node_modules/
.env
*.log
.DS_Store
EOF

cat > ms-productos/sql/schema.sql << 'EOF'
CREATE TABLE IF NOT EXISTS productos (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio NUMERIC(10,2) NOT NULL CHECK (precio >= 0),
  stock INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0),
  categoria VARCHAR(50),
  imagen_url TEXT,
  activo BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_productos_categoria ON productos(categoria);

INSERT INTO productos (nombre, precio, stock, categoria, descripcion) VALUES
  ('Notebook Lenovo', 850000, 10, 'electronica', 'Ryzen 5, 16GB RAM, 512GB SSD'),
  ('Mouse Logitech', 25000, 50, 'electronica', 'Inalámbrico, 1600 DPI'),
  ('Teclado Mecánico', 75000, 30, 'electronica', 'Redragon, switches rojos'),
  ('Silla Gamer', 320000, 5, 'muebles', 'Reclinable 180°, apoyabrazos 4D'),
  ('Monitor 27"', 480000, 8, 'electronica', 'IPS 144Hz, 2K');
EOF

cat > ms-productos/src/config/db.js << 'EOF'
import pg from "pg";
const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on("error", (err) => console.error("Error Postgres:", err));

export async function testConnection() {
  const { rows } = await pool.query("SELECT NOW() AS now");
  console.log(`✅ PostgreSQL conectado: ${rows[0].now}`);
}
EOF

cat > ms-productos/src/services/cotizacionService.js << 'EOF'
let cacheDolar = null;
const CACHE_TTL_MS = 10 * 60 * 1000;

export async function obtenerCotizacionDolar() {
  const ahora = Date.now();
  if (cacheDolar && ahora - cacheDolar.timestamp < CACHE_TTL_MS) {
    return { ...cacheDolar.valor, fromCache: true };
  }
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch("https://dolarapi.com/v1/dolares/oficial", {
      signal: controller.signal,
      headers: { "User-Agent": "ecommerce-tp/1.0" },
    });
    clearTimeout(timeout);
    if (!resp.ok) throw new Error(`API ${resp.status}`);
    const data = await resp.json();
    const valor = { compra: data.compra, venta: data.venta, fecha: data.fechaActualizacion };
    cacheDolar = { valor, timestamp: ahora };
    return { ...valor, fromCache: false };
  } catch (error) {
    if (cacheDolar) return { ...cacheDolar.valor, fromCache: true, stale: true };
    throw new Error("No se pudo obtener cotización");
  }
}
EOF

cat > ms-productos/src/controllers/productosController.js << 'EOF'
import { pool } from "../config/db.js";
import { obtenerCotizacionDolar } from "../services/cotizacionService.js";

export async function listarProductos(req, res) {
  const { categoria, q } = req.query;
  let sql = "SELECT * FROM productos WHERE activo = true";
  const params = [];

  if (categoria) {
    params.push(categoria);
    sql += ` AND categoria = $${params.length}`;
  }
  if (q) {
    params.push(`%${q}%`);
    sql += ` AND nombre ILIKE $${params.length}`;
  }

  try {
    const { rows } = await pool.query(sql, params);
    let cotizacion = null;
    try { cotizacion = await obtenerCotizacionDolar(); } catch {}

    const productos = rows.map((p) => ({
      ...p,
      precioUSD: cotizacion ? Number((p.precio / cotizacion.venta).toFixed(2)) : null,
    }));

    res.json({
      cotizacion: cotizacion ? { ...cotizacion, moneda: "ARS" } : null,
      productos,
    });
  } catch (e) {
    console.error(e);
    res.status(500).json({ error: "Error al listar productos" });
  }
}

export async function obtenerProducto(req, res) {
  try {
    const { rows } = await pool.query("SELECT * FROM productos WHERE id = $1", [req.params.id]);
    if (rows.length === 0) return res.status(404).json({ error: "Producto no encontrado" });
    res.json(rows[0]);
  } catch { res.status(500).json({ error: "Error al obtener producto" }); }
}

export async function crearProducto(req, res) {
  if (req.headers["x-user-rol"] !== "admin")
    return res.status(403).json({ error: "Solo administradores" });

  const { nombre, precio, stock, categoria, descripcion } = req.body;
  if (!nombre || precio == null || stock == null)
    return res.status(400).json({ error: "Faltan campos obligatorios" });

  try {
    const { rows } = await pool.query(
      `INSERT INTO productos (nombre, precio, stock, categoria, descripcion)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [nombre, precio, stock, categoria, descripcion]
    );
    res.status(201).json(rows[0]);
  } catch { res.status(500).json({ error: "Error al crear producto" }); }
}

export async function reducirStock(req, res) {
  const { id, cantidad } = req.body;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { rows } = await client.query(
      "SELECT stock FROM productos WHERE id = $1 FOR UPDATE", [id]
    );
    if (rows.length === 0) throw new Error("Producto no existe");
    if (rows[0].stock < cantidad) throw new Error("Stock insuficiente");

    const upd = await client.query(
      "UPDATE productos SET stock = stock - $1 WHERE id = $2 RETURNING *",
      [cantidad, id]
    );
    await client.query("COMMIT");
    res.json(upd.rows[0]);
  } catch (e) {
    await client.query("ROLLBACK");
    res.status(400).json({ error: e.message });
  } finally {
    client.release();
  }
}

export async function restaurarStock(req, res) {
  const { id, cantidad } = req.body;
  try {
    const { rows } = await pool.query(
      "UPDATE productos SET stock = stock + $1 WHERE id = $2 RETURNING *",
      [cantidad, id]
    );
    res.json(rows[0]);
  } catch { res.status(500).json({ error: "Error al restaurar stock" }); }
}
EOF

cat > ms-productos/src/middlewares/gatewayOnly.js << 'EOF'
export function gatewayOnly(req, res, next) {
  const secret = req.headers["x-gateway-secret"];
  if (!secret || secret !== process.env.GATEWAY_SECRET) {
    return res.status(403).json({ error: "Acceso solo vía API Gateway" });
  }
  next();
}
EOF

cat > ms-productos/src/routes/productosRoutes.js << 'EOF'
import { Router } from "express";
import {
  listarProductos, obtenerProducto, crearProducto, reducirStock, restaurarStock,
} from "../controllers/productosController.js";

const router = Router();
router.get("/", listarProductos);
router.get("/:id", obtenerProducto);
router.post("/", crearProducto);
router.post("/reducir-stock", reducirStock);
router.post("/restaurar-stock", restaurarStock);

export default router;
EOF

cat > ms-productos/src/index.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { testConnection } from "./config/db.js";
import productosRoutes from "./routes/productosRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-productos", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/productos", productosRoutes);

const PORT = process.env.PORT || 3002;
testConnection().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-productos en puerto ${PORT}`));
});
EOF

# ============================================================
# MS-CLIENTES
# ============================================================

cat > ms-clientes/package.json << 'EOF'
{
  "name": "ms-clientes",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "mongoose": "^8.5.1"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

cat > ms-clientes/.env.example << 'EOF'
PORT=3003
MONGO_URI=mongodb+srv://user:pass@cluster.mongodb.net/ms-clientes
GATEWAY_SECRET=dev_gateway_secret_compartido
NODE_ENV=development
EOF

cat > ms-clientes/.gitignore << 'EOF'
node_modules/
.env
*.log
.DS_Store
EOF

cat > ms-clientes/src/config/db.js << 'EOF'
import mongoose from "mongoose";

export async function connectDB() {
  try {
    await mongoose.connect(process.env.MONGO_URI, { serverSelectionTimeoutMS: 5000 });
    console.log("✅ MongoDB conectado (ms-clientes)");
  } catch (error) {
    console.error("❌ Error MongoDB:", error.message);
    process.exit(1);
  }
}
EOF

cat > ms-clientes/src/models/Cliente.js << 'EOF'
import mongoose from "mongoose";

const direccionSchema = new mongoose.Schema(
  {
    etiqueta: { type: String, enum: ["casa", "trabajo", "otra"], default: "casa" },
    calle: { type: String, required: true, trim: true },
    numero: { type: String, required: true },
    piso: { type: String, default: null },
    depto: { type: String, default: null },
    ciudad: { type: String, required: true },
    provincia: { type: String, required: true },
    codigoPostal: { type: String, required: true },
    pais: { type: String, default: "Argentina" },
    esPredeterminada: { type: Boolean, default: false },
    coordenadas: {
      lat: { type: Number, default: null },
      lng: { type: Number, default: null },
    },
  },
  { _id: true, timestamps: true }
);

const preferenciasSchema = new mongoose.Schema(
  {
    idioma: { type: String, enum: ["es", "en", "pt"], default: "es" },
    notificacionesEmail: { type: Boolean, default: true },
    newsletter: { type: Boolean, default: false },
  },
  { _id: false }
);

const clienteSchema = new mongoose.Schema(
  {
    usuarioId: { type: String, required: true, unique: true, index: true },
    nombre: { type: String, required: true, trim: true },
    apellido: { type: String, required: true, trim: true },
    dni: { type: String, required: true, unique: true, match: /^\d{7,8}$/ },
    telefono: { type: String, trim: true },
    fechaNacimiento: { type: Date },
    direcciones: { type: [direccionSchema], default: [] },
    preferencias: { type: preferenciasSchema, default: () => ({}) },
    activo: { type: Boolean, default: true },
  },
  { timestamps: true }
);

clienteSchema.pre("save", function (next) {
  if (this.isModified("direcciones")) {
    const preds = this.direcciones.filter((d) => d.esPredeterminada);
    if (preds.length > 1) {
      const ultima = preds[preds.length - 1]._id;
      this.direcciones.forEach((d) => { d.esPredeterminada = d._id.equals(ultima); });
    }
  }
  next();
});

export default mongoose.model("Cliente", clienteSchema);
EOF

cat > ms-clientes/src/services/geocodingService.js << 'EOF'
export async function geocodificarDireccion(direccion) {
  const query = [direccion.calle, direccion.numero, direccion.ciudad, direccion.provincia, direccion.pais || "Argentina"]
    .filter(Boolean).join(", ");

  const url = new URL("https://nominatim.openstreetmap.org/search");
  url.searchParams.set("q", query);
  url.searchParams.set("format", "json");
  url.searchParams.set("limit", "1");
  url.searchParams.set("countrycodes", "ar");

  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(url.toString(), {
      signal: controller.signal,
      headers: {
        "User-Agent": "ecommerce-tp/1.0 (contacto@ejemplo.com)",
        "Accept-Language": "es",
      },
    });
    clearTimeout(timeout);
    if (!resp.ok) throw new Error(`Nominatim ${resp.status}`);
    const data = await resp.json();
    if (data.length === 0) return null;
    return { lat: Number(data[0].lat), lng: Number(data[0].lon) };
  } catch (error) {
    console.warn("Geocodificación falló:", error.message);
    return null;
  }
}
EOF

cat > ms-clientes/src/controllers/clientesController.js << 'EOF'
import Cliente from "../models/Cliente.js";
import { geocodificarDireccion } from "../services/geocodingService.js";

export async function crearCliente(req, res) {
  try {
    const usuarioId = req.headers["x-user-id"];
    if (!usuarioId) return res.status(400).json({ error: "Falta x-user-id" });

    const existe = await Cliente.findOne({ usuarioId });
    if (existe) return res.status(409).json({ error: "El cliente ya existe" });

    const { nombre, apellido, dni, telefono, fechaNacimiento } = req.body;
    if (!nombre || !apellido || !dni)
      return res.status(400).json({ error: "Faltan campos obligatorios" });

    const cliente = await Cliente.create({
      usuarioId, nombre, apellido, dni, telefono, fechaNacimiento,
    });
    res.status(201).json(cliente);
  } catch (error) {
    if (error.code === 11000)
      return res.status(409).json({ error: "DNI o usuario ya registrado" });
    res.status(500).json({ error: "Error al crear cliente" });
  }
}

export async function obtenerMiPerfil(req, res) {
  try {
    const cliente = await Cliente.findOne({ usuarioId: req.headers["x-user-id"], activo: true });
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });
    res.json(cliente);
  } catch { res.status(500).json({ error: "Error al obtener perfil" }); }
}

export async function actualizarPerfil(req, res) {
  try {
    const permitidos = ["nombre", "apellido", "telefono", "fechaNacimiento", "avatarUrl"];
    const updates = {};
    permitidos.forEach((k) => { if (req.body[k] !== undefined) updates[k] = req.body[k]; });

    const cliente = await Cliente.findOneAndUpdate(
      { usuarioId: req.headers["x-user-id"] },
      { $set: updates },
      { new: true, runValidators: true }
    );
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });
    res.json(cliente);
  } catch { res.status(500).json({ error: "Error al actualizar perfil" }); }
}

export async function agregarDireccion(req, res) {
  try {
    const cliente = await Cliente.findOne({ usuarioId: req.headers["x-user-id"] });
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });

    const nueva = { ...req.body };
    if (!nueva.coordenadas?.lat) {
      const coords = await geocodificarDireccion(nueva);
      if (coords) nueva.coordenadas = coords;
    }
    if (cliente.direcciones.length === 0) nueva.esPredeterminada = true;

    cliente.direcciones.push(nueva);
    await cliente.save();
    res.status(201).json(cliente.direcciones[cliente.direcciones.length - 1]);
  } catch (error) { res.status(400).json({ error: error.message }); }
}

export async function eliminarDireccion(req, res) {
  try {
    const cliente = await Cliente.findOne({ usuarioId: req.headers["x-user-id"] });
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });
    cliente.direcciones.pull(req.params.dirId);
    if (cliente.direcciones.length > 0 && !cliente.direcciones.some((d) => d.esPredeterminada)) {
      cliente.direcciones[0].esPredeterminada = true;
    }
    await cliente.save();
    res.json({ mensaje: "Dirección eliminada" });
  } catch { res.status(500).json({ error: "Error al eliminar dirección" }); }
}

export async function marcarPredeterminada(req, res) {
  try {
    const cliente = await Cliente.findOne({ usuarioId: req.headers["x-user-id"] });
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });
    cliente.direcciones.forEach((d) => {
      d.esPredeterminada = d._id.toString() === req.params.dirId;
    });
    await cliente.save();
    res.json({ mensaje: "Dirección predeterminada actualizada" });
  } catch { res.status(500).json({ error: "Error al marcar dirección" }); }
}

export async function actualizarPreferencias(req, res) {
  try {
    const cliente = await Cliente.findOneAndUpdate(
      { usuarioId: req.headers["x-user-id"] },
      { $set: { preferencias: { ...req.body } } },
      { new: true, runValidators: true }
    );
    if (!cliente) return res.status(404).json({ error: "Perfil no encontrado" });
    res.json(cliente.preferencias);
  } catch { res.status(500).json({ error: "Error al actualizar preferencias" }); }
}
EOF

cat > ms-clientes/src/middlewares/gatewayOnly.js << 'EOF'
export function gatewayOnly(req, res, next) {
  const secret = req.headers["x-gateway-secret"];
  if (!secret || secret !== process.env.GATEWAY_SECRET) {
    return res.status(403).json({ error: "Acceso solo vía API Gateway" });
  }
  next();
}
EOF

cat > ms-clientes/src/routes/clientesRoutes.js << 'EOF'
import { Router } from "express";
import {
  crearCliente, obtenerMiPerfil, actualizarPerfil,
  agregarDireccion, eliminarDireccion, marcarPredeterminada, actualizarPreferencias,
} from "../controllers/clientesController.js";

const router = Router();
router.post("/", crearCliente);
router.get("/perfil", obtenerMiPerfil);
router.put("/perfil", actualizarPerfil);
router.post("/direcciones", agregarDireccion);
router.delete("/direcciones/:dirId", eliminarDireccion);
router.put("/direcciones/:dirId/predeterminada", marcarPredeterminada);
router.put("/preferencias", actualizarPreferencias);

export default router;
EOF

cat > ms-clientes/src/index.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { connectDB } from "./config/db.js";
import clientesRoutes from "./routes/clientesRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-clientes", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/clientes", clientesRoutes);

const PORT = process.env.PORT || 3003;
connectDB().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-clientes en puerto ${PORT}`));
});
EOF

# ============================================================
# MS-PEDIDOS
# ============================================================

cat > ms-pedidos/package.json << 'EOF'
{
  "name": "ms-pedidos",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js"
  },
  "dependencies": {
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "express": "^4.19.2",
    "pg": "^8.12.0"
  },
  "devDependencies": {
    "nodemon": "^3.1.4"
  }
}
EOF

cat > ms-pedidos/.env.example << 'EOF'
PORT=3004
DATABASE_URL=postgresql://user:pass@host/db
MS_PRODUCTOS_URL=http://localhost:3002
GATEWAY_SECRET=dev_gateway_secret_compartido
NODE_ENV=development
EOF

cat > ms-pedidos/.gitignore << 'EOF'
node_modules/
.env
*.log
.DS_Store
EOF

cat > ms-pedidos/sql/schema.sql << 'EOF'
CREATE TABLE IF NOT EXISTS pedidos (
  id SERIAL PRIMARY KEY,
  usuario_id VARCHAR(50) NOT NULL,
  total NUMERIC(10,2) NOT NULL CHECK (total >= 0),
  estado VARCHAR(20) NOT NULL DEFAULT 'pendiente'
    CHECK (estado IN ('pendiente','confirmado','enviado','entregado','cancelado')),
  direccion_entrega JSONB,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pedido_items (
  id SERIAL PRIMARY KEY,
  pedido_id INTEGER NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  producto_id INTEGER NOT NULL,
  nombre_producto VARCHAR(150) NOT NULL,
  cantidad INTEGER NOT NULL CHECK (cantidad > 0),
  precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0)
);

CREATE INDEX IF NOT EXISTS idx_pedidos_usuario ON pedidos(usuario_id);
CREATE INDEX IF NOT EXISTS idx_pedido_items_pedido ON pedido_items(pedido_id);
EOF

cat > ms-pedidos/src/config/db.js << 'EOF'
import pg from "pg";
const { Pool } = pg;

export const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === "production" ? { rejectUnauthorized: false } : false,
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on("error", (err) => console.error("Error Postgres:", err));

export async function testConnection() {
  const { rows } = await pool.query("SELECT NOW() AS now");
  console.log(`✅ PostgreSQL conectado: ${rows[0].now}`);
}
EOF

cat > ms-pedidos/src/services/productosClient.js << 'EOF'
const BASE_URL = process.env.MS_PRODUCTOS_URL;
const SECRET = process.env.GATEWAY_SECRET;

async function fetchConTimeout(url, options = {}, timeoutMs = 5000) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...options, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

export async function reducirStock(productoId, cantidad) {
  const resp = await fetchConTimeout(`${BASE_URL}/productos/reducir-stock`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-gateway-secret": SECRET },
    body: JSON.stringify({ id: productoId, cantidad }),
  });
  if (!resp.ok) {
    const err = await resp.json().catch(() => ({ error: "Error desconocido" }));
    throw new Error(err.error || `Error con producto ${productoId}`);
  }
  return resp.json();
}

export async function restaurarStock(productoId, cantidad) {
  const resp = await fetchConTimeout(`${BASE_URL}/productos/restaurar-stock`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "x-gateway-secret": SECRET },
    body: JSON.stringify({ id: productoId, cantidad }),
  });
  return resp.ok;
}
EOF

cat > ms-pedidos/src/controllers/pedidosController.js << 'EOF'
import { pool } from "../config/db.js";
import { reducirStock, restaurarStock } from "../services/productosClient.js";

export async function crearPedido(req, res, next) {
  const usuarioId = req.headers["x-user-id"];
  const { items, direccionEntrega } = req.body;

  if (!usuarioId) return res.status(401).json({ error: "Usuario no autenticado" });
  if (!Array.isArray(items) || items.length === 0)
    return res.status(400).json({ error: "El pedido debe tener al menos un item" });

  for (const item of items) {
    if (!item.productoId || !item.cantidad || item.cantidad < 1)
      return res.status(400).json({ error: "Items inválidos" });
  }

  const client = await pool.connect();
  const stockReducido = [];

  try {
    await client.query("BEGIN");
    let total = 0;
    const detalles = [];

    for (const item of items) {
      try {
        const producto = await reducirStock(item.productoId, item.cantidad);
        stockReducido.push({ productoId: item.productoId, cantidad: item.cantidad });
        total += Number(producto.precio) * item.cantidad;
        detalles.push({
          productoId: item.productoId,
          nombreProducto: producto.nombre,
          cantidad: item.cantidad,
          precioUnitario: Number(producto.precio),
        });
      } catch (err) {
        await Promise.allSettled(
          stockReducido.map((s) => restaurarStock(s.productoId, s.cantidad))
        );
        throw new Error(`Error con producto ${item.productoId}: ${err.message}`);
      }
    }

    const { rows: [pedido] } = await client.query(
      `INSERT INTO pedidos (usuario_id, total, estado, direccion_entrega)
       VALUES ($1, $2, 'confirmado', $3) RETURNING *`,
      [usuarioId, total, direccionEntrega || null]
    );

    for (const d of detalles) {
      await client.query(
        `INSERT INTO pedido_items (pedido_id, producto_id, nombre_producto, cantidad, precio_unitario)
         VALUES ($1, $2, $3, $4, $5)`,
        [pedido.id, d.productoId, d.nombreProducto, d.cantidad, d.precioUnitario]
      );
    }

    await client.query("COMMIT");
    res.status(201).json({ ...pedido, items: detalles });
  } catch (error) {
    await client.query("ROLLBACK");
    next(error);
  } finally {
    client.release();
  }
}

export async function listarMisPedidos(req, res, next) {
  try {
    const { rows } = await pool.query(
      `SELECT p.*,
              COALESCE(json_agg(pi.*) FILTER (WHERE pi.id IS NOT NULL), '[]') AS items
       FROM pedidos p
       LEFT JOIN pedido_items pi ON pi.pedido_id = p.id
       WHERE p.usuario_id = $1
       GROUP BY p.id
       ORDER BY p.created_at DESC`,
      [req.headers["x-user-id"]]
    );
    res.json(rows);
  } catch (e) { next(e); }
}

export async function cancelarPedido(req, res) {
  const { id } = req.params;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const { rows: [pedido] } = await client.query(
      "SELECT * FROM pedidos WHERE id = $1 FOR UPDATE", [id]
    );
    if (!pedido) throw new Error("Pedido no encontrado");

    const rol = req.headers["x-user-rol"];
    const usuarioId = req.headers["x-user-id"];
    if (rol !== "admin" && pedido.usuario_id !== usuarioId) throw new Error("No autorizado");
    if (pedido.estado === "cancelado") throw new Error("Ya está cancelado");

    const { rows: items } = await client.query(
      "SELECT producto_id, cantidad FROM pedido_items WHERE pedido_id = $1", [id]
    );
    await Promise.allSettled(
      items.map((i) => restaurarStock(i.producto_id, i.cantidad))
    );

    await client.query("UPDATE pedidos SET estado = 'cancelado' WHERE id = $1", [id]);
    await client.query("COMMIT");
    res.json({ mensaje: "Pedido cancelado", pedidoId: id });
  } catch (error) {
    await client.query("ROLLBACK");
    res.status(400).json({ error: error.message });
  } finally {
    client.release();
  }
}
EOF

cat > ms-pedidos/src/middlewares/gatewayOnly.js << 'EOF'
export function gatewayOnly(req, res, next) {
  const secret = req.headers["x-gateway-secret"];
  if (!secret || secret !== process.env.GATEWAY_SECRET) {
    return res.status(403).json({ error: "Acceso solo vía API Gateway" });
  }
  next();
}
EOF

cat > ms-pedidos/src/middlewares/errorHandler.js << 'EOF'
export function errorHandler(err, req, res, _next) {
  console.error("[ms-pedidos]", err);
  res.status(err.status || 500).json({ error: err.message || "Error interno" });
}

export function notFound(req, res) {
  res.status(404).json({ error: `Ruta no encontrada: ${req.method} ${req.originalUrl}` });
}
EOF

cat > ms-pedidos/src/routes/pedidosRoutes.js << 'EOF'
import { Router } from "express";
import {
  crearPedido, listarMisPedidos, cancelarPedido,
} from "../controllers/pedidosController.js";

const router = Router();
router.get("/mis-pedidos", listarMisPedidos);
router.post("/", crearPedido);
router.put("/:id/cancelar", cancelarPedido);

export default router;
EOF

cat > ms-pedidos/src/index.js << 'EOF'
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import { testConnection } from "./config/db.js";
import pedidosRoutes from "./routes/pedidosRoutes.js";
import { gatewayOnly } from "./middlewares/gatewayOnly.js";
import { errorHandler, notFound } from "./middlewares/errorHandler.js";

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) =>
  res.json({ status: "ok", service: "ms-pedidos", uptime: process.uptime() })
);

app.use(gatewayOnly);
app.use("/pedidos", pedidosRoutes);

app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 3004;
testConnection().then(() => {
  app.listen(PORT, () => console.log(`🚀 ms-pedidos en puerto ${PORT}`));
});
EOF

# ============================================================
# FRONTEND
# ============================================================

cat > frontend/package.json << 'EOF'
{
  "name": "frontend-ecommerce",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-router-dom": "^6.26.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.3.1",
    "vite": "^5.4.0"
  }
}
EOF

cat > frontend/vite.config.js << 'EOF'
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  server: { port: 5173 },
});
EOF

cat > frontend/index.html << 'EOF'
<!DOCTYPE html>
<html lang="es">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>E-commerce TP</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat > frontend/.env.example << 'EOF'
VITE_API_GATEWAY=http://localhost:3000
EOF

cat > frontend/.gitignore << 'EOF'
node_modules/
.env
dist/
.DS_Store
EOF

cat > frontend/src/main.jsx << 'EOF'
import React from "react";
import ReactDOM from "react-dom/client";
import App from "./App.jsx";
import "./styles.css";

ReactDOM.createRoot(document.getElementById("root")).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);
EOF

cat > frontend/src/styles.css << 'EOF'
* { box-sizing: border-box; }
body { margin: 0; font-family: system-ui, -apple-system, sans-serif; }
a { color: inherit; }
button { cursor: pointer; padding: 0.5rem 1rem; }
input, select { padding: 0.5rem; }
EOF

cat > frontend/src/api/client.js << 'EOF'
const API = import.meta.env.VITE_API_GATEWAY;

export async function request(path, options = {}) {
  const token = localStorage.getItem("token");
  const headers = { "Content-Type": "application/json", ...(options.headers || {}) };
  if (token) headers.Authorization = `Bearer ${token}`;

  let response;
  try {
    response = await fetch(`${API}${path}`, { ...options, headers });
  } catch {
    throw new Error("No se pudo conectar con el servidor");
  }

  if ((response.status === 401 || response.status === 403) && token) {
    localStorage.removeItem("token");
    localStorage.removeItem("usuario");
    window.dispatchEvent(new Event("sesion-expirada"));
    throw new Error("Sesión expirada");
  }

  if (response.status === 204) return null;
  const data = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error(data.error || `Error ${response.status}`);
  return data;
}

export const get = (path) => request(path);
export const post = (path, body) => request(path, { method: "POST", body: JSON.stringify(body) });
export const put = (path, body) => request(path, { method: "PUT", body: JSON.stringify(body) });
export const del = (path) => request(path, { method: "DELETE" });
EOF

cat > frontend/src/api/auth.js << 'EOF'
import { get, post } from "./client.js";

export const authApi = {
  login: (email, password) => post("/api/usuarios/auth/login", { email, password }),
  register: (data) => post("/api/usuarios/auth/register", data),
  perfil: () => get("/api/usuarios/auth/perfil"),
};
EOF

cat > frontend/src/api/productos.js << 'EOF'
import { get } from "./client.js";

export const productosApi = {
  listar: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return get(`/api/productos${qs ? `?${qs}` : ""}`);
  },
  obtener: (id) => get(`/api/productos/${id}`),
};
EOF

cat > frontend/src/api/clientes.js << 'EOF'
import { get, post, put, del } from "./client.js";

export const clientesApi = {
  crearPerfil: (data) => post("/api/clientes", data),
  miPerfil: () => get("/api/clientes/perfil"),
  actualizarPerfil: (data) => put("/api/clientes/perfil", data),
  agregarDireccion: (data) => post("/api/clientes/direcciones", data),
  eliminarDireccion: (id) => del(`/api/clientes/direcciones/${id}`),
  marcarPredeterminada: (id) => put(`/api/clientes/direcciones/${id}/predeterminada`),
};
EOF

cat > frontend/src/api/pedidos.js << 'EOF'
import { get, post, put } from "./client.js";

export const pedidosApi = {
  crear: (items, direccionEntrega) => post("/api/pedidos", { items, direccionEntrega }),
  misPedidos: () => get("/api/pedidos/mis-pedidos"),
  cancelar: (id) => put(`/api/pedidos/${id}/cancelar`),
};
EOF

cat > frontend/src/context/AuthContext.jsx << 'EOF'
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
EOF

cat > frontend/src/context/CartContext.jsx << 'EOF'
import { createContext, useContext, useEffect, useState } from "react";

const CartContext = createContext(null);

export function CartProvider({ children }) {
  const [items, setItems] = useState(() => {
    const raw = localStorage.getItem("cart");
    return raw ? JSON.parse(raw) : [];
  });

  useEffect(() => {
    localStorage.setItem("cart", JSON.stringify(items));
  }, [items]);

  function agregar(producto, cantidad = 1) {
    setItems((prev) => {
      const existe = prev.find((i) => i.productoId === producto.id);
      if (existe) {
        return prev.map((i) =>
          i.productoId === producto.id ? { ...i, cantidad: i.cantidad + cantidad } : i
        );
      }
      return [...prev, {
        productoId: producto.id, nombre: producto.nombre,
        precio: Number(producto.precio), cantidad,
      }];
    });
  }

  function quitar(id) {
    setItems((prev) => prev.filter((i) => i.productoId !== id));
  }

  function actualizarCantidad(id, cantidad) {
    if (cantidad <= 0) return quitar(id);
    setItems((prev) => prev.map((i) => (i.productoId === id ? { ...i, cantidad } : i)));
  }

  function vaciar() { setItems([]); }

  const total = items.reduce((s, i) => s + i.precio * i.cantidad, 0);
  const cantidadTotal = items.reduce((s, i) => s + i.cantidad, 0);

  return (
    <CartContext.Provider value={{ items, total, cantidadTotal, agregar, quitar, actualizarCantidad, vaciar }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error("useCart fuera de CartProvider");
  return ctx;
}
EOF

cat > frontend/src/components/Navbar.jsx << 'EOF'
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
EOF

cat > frontend/src/components/ProtectedRoute.jsx << 'EOF'
import { Navigate, useLocation } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";

export default function ProtectedRoute({ children, soloAdmin = false }) {
  const { autenticado, esAdmin } = useAuth();
  const location = useLocation();

  if (!autenticado) {
    return <Navigate to="/login" state={{ from: location.pathname }} replace />;
  }
  if (soloAdmin && !esAdmin) return <Navigate to="/" replace />;
  return children;
}
EOF

cat > frontend/src/components/ProductoCard.jsx << 'EOF'
import { Link } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";

export default function ProductoCard({ producto }) {
  const { agregar } = useCart();

  return (
    <div style={{ border: "1px solid #ccc", padding: "1rem", borderRadius: "8px" }}>
      <h3>{producto.nombre}</h3>
      <p style={{ fontSize: "1.2rem", fontWeight: "bold" }}>
        ${Number(producto.precio).toLocaleString("es-AR")}
      </p>
      {producto.precioUSD && (
        <p style={{ color: "#666", fontSize: "0.9rem" }}>USD {producto.precioUSD}</p>
      )}
      <p style={{ color: producto.stock > 0 ? "green" : "red" }}>
        {producto.stock > 0 ? `Stock: ${producto.stock}` : "Sin stock"}
      </p>
      <button
        onClick={() => agregar(producto)}
        disabled={producto.stock === 0}
        style={{ width: "100%", padding: "0.5rem" }}
      >
        Agregar al carrito
      </button>
    </div>
  );
}
EOF

cat > frontend/src/pages/Home.jsx << 'EOF'
import { Link } from "react-router-dom";
export default function Home() {
  return (
    <div style={{ padding: "3rem", textAlign: "center" }}>
      <h1>Bienvenido al E-commerce</h1>
      <p>Microservicios + API Gateway + React</p>
      <Link to="/catalogo" style={{ fontSize: "1.2rem" }}>Ver catálogo →</Link>
    </div>
  );
}
EOF

cat > frontend/src/pages/Login.jsx << 'EOF'
import { useState } from "react";
import { useNavigate, useLocation, Link } from "react-router-dom";
import { useAuth } from "../context/AuthContext.jsx";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const { login, cargando } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const from = location.state?.from || "/";

  async function handleSubmit(e) {
    e.preventDefault();
    setError("");
    try {
      await login(email, password);
      navigate(from, { replace: true });
    } catch (err) { setError(err.message); }
  }

  return (
    <div style={{ maxWidth: "400px", margin: "2rem auto" }}>
      <h1>Iniciar sesión</h1>
      <form onSubmit={handleSubmit}>
        <div style={{ marginBottom: "1rem" }}>
          <label>Email</label>
          <input type="email" value={email} onChange={(e) => setEmail(e.target.value)}
            required style={{ width: "100%" }} />
        </div>
        <div style={{ marginBottom: "1rem" }}>
          <label>Contraseña</label>
          <input type="password" value={password} onChange={(e) => setPassword(e.target.value)}
            required style={{ width: "100%" }} />
        </div>
        {error && <p style={{ color: "red" }}>{error}</p>}
        <button type="submit" disabled={cargando} style={{ width: "100%", padding: "0.75rem" }}>
          {cargando ? "Entrando..." : "Entrar"}
        </button>
      </form>
      <p style={{ marginTop: "1rem" }}>
        ¿No tenés cuenta? <Link to="/register">Registrate</Link>
      </p>
    </div>
  );
}
EOF

cat > frontend/src/pages/Register.jsx << 'EOF'
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
EOF

cat > frontend/src/pages/Catalogo.jsx << 'EOF'
import { useEffect, useState } from "react";
import { productosApi } from "../api/productos.js";
import ProductoCard from "../components/ProductoCard.jsx";

export default function Catalogo() {
  const [productos, setProductos] = useState([]);
  const [cotizacion, setCotizacion] = useState(null);
  const [categoria, setCategoria] = useState("");
  const [cargando, setCargando] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => { cargar(); }, [categoria]);

  async function cargar() {
    setCargando(true);
    setError("");
    try {
      const params = categoria ? { categoria } : {};
      const data = await productosApi.listar(params);
      setProductos(data.productos || []);
      setCotizacion(data.cotizacion || null);
    } catch (err) { setError(err.message); }
    finally { setCargando(false); }
  }

  return (
    <div style={{ padding: "1rem" }}>
      <h1>Catálogo</h1>
      {cotizacion && (
        <p style={{ background: "#eef", padding: "0.5rem", borderRadius: "4px" }}>
          💵 Dólar oficial: compra ${cotizacion.compra} / venta ${cotizacion.venta}
        </p>
      )}
      <select value={categoria} onChange={(e) => setCategoria(e.target.value)}
        style={{ marginBottom: "1rem" }}>
        <option value="">Todas las categorías</option>
        <option value="electronica">Electrónica</option>
        <option value="muebles">Muebles</option>
      </select>
      {cargando && <p>Cargando...</p>}
      {error && <p style={{ color: "red" }}>{error}</p>}
      <div style={{ display: "grid", gridTemplateColumns: "repeat(auto-fill, minmax(250px, 1fr))", gap: "1rem" }}>
        {productos.map((p) => <ProductoCard key={p.id} producto={p} />)}
      </div>
    </div>
  );
}
EOF

cat > frontend/src/pages/Carrito.jsx << 'EOF'
import { Link, useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";
import { useAuth } from "../context/AuthContext.jsx";

export default function Carrito() {
  const { items, total, actualizarCantidad, quitar } = useCart();
  const { autenticado } = useAuth();
  const navigate = useNavigate();

  if (items.length === 0) {
    return (
      <div style={{ padding: "2rem", textAlign: "center" }}>
        <h2>Tu carrito está vacío</h2>
        <Link to="/catalogo">Ir al catálogo</Link>
      </div>
    );
  }

  return (
    <div style={{ padding: "1rem", maxWidth: "800px", margin: "0 auto" }}>
      <h1>Carrito</h1>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr><th>Producto</th><th>Precio</th><th>Cantidad</th><th>Subtotal</th><th></th></tr>
        </thead>
        <tbody>
          {items.map((i) => (
            <tr key={i.productoId} style={{ borderTop: "1px solid #ddd" }}>
              <td>{i.nombre}</td>
              <td>${i.precio.toLocaleString("es-AR")}</td>
              <td>
                <button onClick={() => actualizarCantidad(i.productoId, i.cantidad - 1)}>-</button>
                <span style={{ margin: "0 0.5rem" }}>{i.cantidad}</span>
                <button onClick={() => actualizarCantidad(i.productoId, i.cantidad + 1)}>+</button>
              </td>
              <td>${(i.precio * i.cantidad).toLocaleString("es-AR")}</td>
              <td><button onClick={() => quitar(i.productoId)}>🗑️</button></td>
            </tr>
          ))}
        </tbody>
      </table>
      <h2 style={{ textAlign: "right" }}>Total: ${total.toLocaleString("es-AR")}</h2>
      <div style={{ textAlign: "right" }}>
        <button onClick={() => navigate(autenticado ? "/checkout" : "/login")}
          style={{ padding: "1rem 2rem" }}>
          {autenticado ? "Ir a pagar" : "Iniciar sesión para pagar"}
        </button>
      </div>
    </div>
  );
}
EOF

cat > frontend/src/pages/Checkout.jsx << 'EOF'
import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { useCart } from "../context/CartContext.jsx";
import { clientesApi } from "../api/clientes.js";
import { pedidosApi } from "../api/pedidos.js";

export default function Checkout() {
  const { items, total, vaciar } = useCart();
  const navigate = useNavigate();
  const [perfil, setPerfil] = useState(null);
  const [direccionId, setDireccionId] = useState(null);
  const [error, setError] = useState("");
  const [enviando, setEnviando] = useState(false);

  useEffect(() => {
    clientesApi.miPerfil().then(setPerfil).catch(() => setPerfil({ direcciones: [] }));
  }, []);

  async function confirmar() {
    setError("");
    setEnviando(true);
    try {
      const direccion = perfil?.direcciones.find((d) => d._id === direccionId);
      const pedidoItems = items.map((i) => ({ productoId: i.productoId, cantidad: i.cantidad }));
      await pedidosApi.crear(pedidoItems, direccion || null);
      vaciar();
      navigate("/mis-pedidos");
    } catch (err) { setError(err.message); }
    finally { setEnviando(false); }
  }

  if (items.length === 0) return <p style={{ padding: "2rem" }}>Carrito vacío</p>;

  return (
    <div style={{ padding: "1rem", maxWidth: "700px", margin: "0 auto" }}>
      <h1>Confirmar pedido</h1>
      <h3>Resumen</h3>
      <ul>
        {items.map((i) => (
          <li key={i.productoId}>{i.cantidad} × {i.nombre} = ${(i.precio * i.cantidad).toLocaleString("es-AR")}</li>
        ))}
      </ul>
      <p style={{ fontWeight: "bold" }}>Total: ${total.toLocaleString("es-AR")}</p>

      <h3>Dirección</h3>
      {!perfil || perfil.direcciones.length === 0 ? (
        <p>Sin direcciones cargadas. <a href="/direcciones">Agregar</a></p>
      ) : (
        <select value={direccionId || ""} onChange={(e) => setDireccionId(e.target.value)} style={{ width: "100%" }}>
          <option value="">Elegí una dirección</option>
          {perfil.direcciones.map((d) => (
            <option key={d._id} value={d._id}>{d.calle} {d.numero}, {d.ciudad}</option>
          ))}
        </select>
      )}

      {error && <p style={{ color: "red" }}>{error}</p>}
      <button onClick={confirmar} disabled={enviando || !direccionId}
        style={{ marginTop: "1rem", padding: "1rem 2rem" }}>
        {enviando ? "Procesando..." : "Confirmar pedido"}
      </button>
    </div>
  );
}
EOF

cat > frontend/src/pages/MisPedidos.jsx << 'EOF'
import { useEffect, useState } from "react";
import { pedidosApi } from "../api/pedidos.js";

export default function MisPedidos() {
  const [pedidos, setPedidos] = useState([]);
  const [cargando, setCargando] = useState(true);

  useEffect(() => {
    pedidosApi.misPedidos().then(setPedidos).finally(() => setCargando(false));
  }, []);

  async function cancelar(id) {
    if (!confirm("¿Cancelar este pedido?")) return;
    try {
      await pedidosApi.cancelar(id);
      setPedidos((prev) => prev.map((p) => (p.id === id ? { ...p, estado: "cancelado" } : p)));
    } catch (err) { alert(err.message); }
  }

  if (cargando) return <p style={{ padding: "2rem" }}>Cargando...</p>;

  return (
    <div style={{ padding: "1rem", maxWidth: "900px", margin: "0 auto" }}>
      <h1>Mis pedidos</h1>
      {pedidos.length === 0 && <p>No tenés pedidos todavía.</p>}
      {pedidos.map((p) => (
        <div key={p.id} style={{ border: "1px solid #ccc", margin: "1rem 0", padding: "1rem", borderRadius: "8px" }}>
          <strong>Pedido #{p.id}</strong> — {new Date(p.created_at).toLocaleDateString("es-AR")}
          <p>Estado: <strong>{p.estado}</strong></p>
          <p>Total: ${Number(p.total).toLocaleString("es-AR")}</p>
          <ul>{p.items?.map((i) => <li key={i.id}>{i.cantidad} × {i.nombre_producto}</li>)}</ul>
          {["pendiente", "confirmado"].includes(p.estado) && (
            <button onClick={() => cancelar(p.id)}>Cancelar</button>
          )}
        </div>
      ))}
    </div>
  );
}
EOF

cat > frontend/src/pages/Perfil.jsx << 'EOF'
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
EOF

cat > frontend/src/pages/Direcciones.jsx << 'EOF'
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
EOF

cat > frontend/src/pages/NotFound.jsx << 'EOF'
export default function NotFound() {
  return (
    <div style={{ padding: "3rem", textAlign: "center" }}>
      <h1>404</h1>
      <p>Página no encontrada</p>
    </div>
  );
}
EOF

cat > frontend/src/App.jsx << 'EOF'
import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext.jsx";
import { CartProvider } from "./context/CartContext.jsx";
import Navbar from "./components/Navbar.jsx";
import ProtectedRoute from "./components/ProtectedRoute.jsx";
import Home from "./pages/Home.jsx";
import Login from "./pages/Login.jsx";
import Register from "./pages/Register.jsx";
import Catalogo from "./pages/Catalogo.jsx";
import Carrito from "./pages/Carrito.jsx";
import Checkout from "./pages/Checkout.jsx";
import MisPedidos from "./pages/MisPedidos.jsx";
import Perfil from "./pages/Perfil.jsx";
import Direcciones from "./pages/Direcciones.jsx";
import NotFound from "./pages/NotFound.jsx";

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <CartProvider>
          <Navbar />
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/login" element={<Login />} />
            <Route path="/register" element={<Register />} />
            <Route path="/catalogo" element={<Catalogo />} />
            <Route path="/carrito" element={<Carrito />} />
            <Route path="/checkout" element={<ProtectedRoute><Checkout /></ProtectedRoute>} />
            <Route path="/mis-pedidos" element={<ProtectedRoute><MisPedidos /></ProtectedRoute>} />
            <Route path="/perfil" element={<ProtectedRoute><Perfil /></ProtectedRoute>} />
            <Route path="/direcciones" element={<ProtectedRoute><Direcciones /></ProtectedRoute>} />
            <Route path="*" element={<NotFound />} />
          </Routes>
        </CartProvider>
      </AuthProvider>
    </BrowserRouter>
  );
}
EOF

# ============================================================
# README raíz
# ============================================================

cat > README.md << 'EOF'
# E-commerce Microservicios

Sistema de e-commerce con arquitectura de microservicios + API Gateway.

## Servicios

| Servicio | Puerto | Base de datos |
|---|---|---|
| api-gateway | 3000 | — |
| ms-usuarios | 3001 | MongoDB Atlas |
| ms-productos | 3002 | PostgreSQL |
| ms-clientes | 3003 | MongoDB Atlas |
| ms-pedidos | 3004 | PostgreSQL |
| frontend | 5173 | — |

## Instalación

En cada carpeta de servicio:

```bash
npm install
cp .env.example .env
# Editar .env con credenciales reales
npm run dev
