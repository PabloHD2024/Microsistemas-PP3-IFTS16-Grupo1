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
