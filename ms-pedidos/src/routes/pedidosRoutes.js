import { Router } from "express";
import {
  crearPedido, listarMisPedidos, cancelarPedido,
} from "../controllers/pedidosController.js";

const router = Router();
router.get("/mis-pedidos", listarMisPedidos);
router.post("/", crearPedido);
router.put("/:id/cancelar", cancelarPedido);

export default router;
