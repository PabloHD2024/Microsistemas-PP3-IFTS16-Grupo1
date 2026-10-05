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
