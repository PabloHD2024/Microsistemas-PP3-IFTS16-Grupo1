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
