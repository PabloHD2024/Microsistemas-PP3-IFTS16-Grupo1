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
