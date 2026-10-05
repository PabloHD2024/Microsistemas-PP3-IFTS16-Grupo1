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
